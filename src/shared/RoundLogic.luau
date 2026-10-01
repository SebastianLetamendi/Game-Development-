--!strict
-- The rules of one delivery round, written as plain data and functions.
--
-- Nothing in this file touches Roblox services, parts or players. Time is
-- passed in as a number and randomness as a function, which is what lets
-- tests/RoundLogic.spec.luau check every rule outside Studio.
--
-- The server's RoundService is the only game code that calls these
-- functions, so clients can never change a round directly.
--
-- Phases of a round:
--
--   Idle ──start──▶ ToPickup ──pickUp──▶ ToDropoff ──deliver──▶ Delivered
--                      │                     │
--                      └──────expire─────────┴──────────────────▶ TimeUp
--
-- From Delivered or TimeUp, start begins a fresh round.

export type Phase = "Idle" | "ToPickup" | "ToDropoff" | "Delivered" | "TimeUp"

-- Why an action was refused. RoundService turns these into player messages.
export type Reason =
	"AlreadyRunning"
	| "NotRunning"
	| "AlreadyCarrying"
	| "NotCarrying"
	| "WrongTarget"
	| "TooFast"
	| "TimeUp"

-- The subset of Config these rules need. Tests pass their own table.
export type Rules = {
	ROUND_SECONDS: number,
	GRACE_SECONDS: number,
	BASE_POINTS: number,
	POINTS_PER_SECOND_LEFT: number,
}

export type Round = {
	phase: Phase,
	-- Goes up by one every start. A timer started for round 3 can tell
	-- that round 4 has begun and must not end it.
	roundId: number,
	targetId: string?, -- the destination for the current or last round
	startedAt: number?,
	deadline: number?, -- the time when the round's timer reaches zero
	pickedUpAt: number?,
	lastScore: number?, -- score of the last delivery; nil after a failed round
	lastSeconds: number?, -- how long the last successful delivery took
	best: number, -- best score so far in this server session
	newBest: boolean, -- true when the last delivery beat the previous best
}

local RoundLogic = {}

function RoundLogic.newRound(): Round
	return {
		phase = "Idle",
		roundId = 0,
		best = 0,
		newBest = false,
	}
end

function RoundLogic.isRunning(round: Round): boolean
	return round.phase == "ToPickup" or round.phase == "ToDropoff"
end

-- Seconds left on the timer, never below zero. Zero when no round is running.
function RoundLogic.timeLeft(round: Round, now: number): number
	local deadline = round.deadline
	if not RoundLogic.isRunning(round) or deadline == nil then
		return 0
	end
	return math.max(0, deadline - now)
end

-- Score for a delivery made with `secondsLeft` on the timer.
-- Example with the default Config: 42.7 s left -> 100 + 42 * 10 = 520.
function RoundLogic.scoreFor(rules: Rules, secondsLeft: number): number
	local wholeSeconds = math.floor(math.max(0, secondsLeft))
	return rules.BASE_POINTS + wholeSeconds * rules.POINTS_PER_SECOND_LEFT
end

-- Picks the next destination, avoiding the previous one when there is a
-- choice so that replays send the player somewhere new.
-- `randomIndex(n)` must return a whole number from 1 to n; the server passes
-- a function that uses Roblox's Random object, tests pass a fixed one.
function RoundLogic.chooseTarget(
	targetIds: { string },
	previousId: string?,
	randomIndex: (count: number) -> number
): string?
	local choices: { string } = {}
	for _, id in targetIds do
		if id ~= previousId then
			table.insert(choices, id)
		end
	end
	if #choices == 0 then
		-- Zero or one destination exists, so repeating is unavoidable.
		choices = table.clone(targetIds)
	end
	if #choices == 0 then
		return nil
	end
	return choices[randomIndex(#choices)]
end

local function isPastGrace(round: Round, rules: Rules, now: number): boolean
	local deadline = round.deadline
	return deadline ~= nil and now > deadline + rules.GRACE_SECONDS
end

local function endWithTimeUp(round: Round)
	round.phase = "TimeUp"
	round.lastScore = nil
	round.lastSeconds = nil
	round.newBest = false
end

-- Starts a new round toward `targetId`. Refused while a round is running, so
-- pressing Start twice cannot reset the timer.
function RoundLogic.start(
	round: Round,
	rules: Rules,
	now: number,
	targetId: string
): (boolean, Reason?)
	if RoundLogic.isRunning(round) then
		return false, "AlreadyRunning"
	end
	round.phase = "ToPickup"
	round.roundId += 1
	round.targetId = targetId
	round.startedAt = now
	round.deadline = now + rules.ROUND_SECONDS
	round.pickedUpAt = nil
	round.lastScore = nil
	round.lastSeconds = nil
	round.newBest = false
	return true, nil
end

-- The player collected the package at the depot.
function RoundLogic.pickUp(round: Round, rules: Rules, now: number): (boolean, Reason?)
	if round.phase == "ToDropoff" then
		return false, "AlreadyCarrying"
	end
	if round.phase ~= "ToPickup" then
		return false, "NotRunning"
	end
	if isPastGrace(round, rules, now) then
		endWithTimeUp(round)
		return false, "TimeUp"
	end
	round.phase = "ToDropoff"
	round.pickedUpAt = now
	return true, nil
end

-- The player handed the package over at destination `targetId`.
-- `minTravelSeconds` is the quickest believable trip from the depot to that
-- destination; the server works it out from distance and MAX_TRAVEL_SPEED.
-- A faster trip means the character was teleported, so it is refused.
function RoundLogic.deliver(
	round: Round,
	rules: Rules,
	now: number,
	targetId: string,
	minTravelSeconds: number
): (boolean, Reason?)
	if round.phase == "ToPickup" then
		return false, "NotCarrying"
	end
	if round.phase ~= "ToDropoff" then
		return false, "NotRunning"
	end
	if isPastGrace(round, rules, now) then
		endWithTimeUp(round)
		return false, "TimeUp"
	end
	if targetId ~= round.targetId then
		return false, "WrongTarget"
	end
	local pickedUpAt = round.pickedUpAt :: number
	if now - pickedUpAt < minTravelSeconds then
		return false, "TooFast"
	end

	local score = RoundLogic.scoreFor(rules, RoundLogic.timeLeft(round, now))
	round.phase = "Delivered"
	round.lastScore = score
	round.lastSeconds = now - (round.startedAt :: number)
	round.newBest = score > round.best
	if round.newBest then
		round.best = score
	end
	return true, nil
end

-- Ends the round if its time (plus the grace period) has run out.
-- Returns true only when this call changed the phase to TimeUp.
function RoundLogic.expire(round: Round, rules: Rules, now: number): boolean
	if not RoundLogic.isRunning(round) or not isPastGrace(round, rules, now) then
		return false
	end
	endWithTimeUp(round)
	return true
end

return RoundLogic
