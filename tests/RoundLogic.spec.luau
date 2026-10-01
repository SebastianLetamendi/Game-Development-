--!strict
-- Unit tests for the round rules in src/shared/RoundLogic.luau.
-- Time is just a number here: the round starts at T = 1000.

local TestKit = require("./TestKit")
local RoundLogic = require("../src/shared/RoundLogic")

local suite = TestKit.suite("RoundLogic")
local test, equal, truthy = TestKit.test, TestKit.equal, TestKit.truthy

local RULES: RoundLogic.Rules = {
	ROUND_SECONDS = 90,
	GRACE_SECONDS = 0.25,
	BASE_POINTS = 100,
	POINTS_PER_SECOND_LEFT = 10,
}

local T = 1000
local NO_MIN_TRAVEL = 0

-- A round that has started toward "Library" at time T.
local function startedRound(): RoundLogic.Round
	local round = RoundLogic.newRound()
	local ok = RoundLogic.start(round, RULES, T, "Library")
	assert(ok, "start failed")
	return round
end

-- A round where the package was picked up at T + 5.
local function carryingRound(): RoundLogic.Round
	local round = startedRound()
	local ok = RoundLogic.pickUp(round, RULES, T + 5)
	assert(ok, "pickUp failed")
	return round
end

test(suite, "a new round is idle with no best score", function()
	local round = RoundLogic.newRound()
	equal(round.phase, "Idle", "phase")
	equal(round.best, 0, "best")
	equal(round.roundId, 0, "roundId")
	equal(RoundLogic.isRunning(round), false, "isRunning")
	equal(RoundLogic.timeLeft(round, T), 0, "timeLeft")
end)

test(suite, "start sets the destination and a 90 second deadline", function()
	local round = startedRound()
	equal(round.phase, "ToPickup", "phase")
	equal(round.targetId, "Library", "targetId")
	equal(round.deadline, T + 90, "deadline")
	equal(round.roundId, 1, "roundId")
	equal(RoundLogic.timeLeft(round, T + 30), 60, "timeLeft")
end)

test(suite, "pressing start again during a round does not reset the timer", function()
	local round = startedRound()
	local ok, reason = RoundLogic.start(round, RULES, T + 40, "Gym")
	equal(ok, false, "ok")
	equal(reason, "AlreadyRunning", "reason")
	equal(round.deadline, T + 90, "deadline")
	equal(round.targetId, "Library", "targetId")
	equal(round.roundId, 1, "roundId")
end)

test(suite, "picking up requires a running round", function()
	local round = RoundLogic.newRound()
	local ok, reason = RoundLogic.pickUp(round, RULES, T)
	equal(ok, false, "ok")
	equal(reason, "NotRunning", "reason")
	equal(round.phase, "Idle", "phase")
end)

test(suite, "picking up moves the round to the drop-off step", function()
	local round = carryingRound()
	equal(round.phase, "ToDropoff", "phase")
	equal(round.pickedUpAt, T + 5, "pickedUpAt")
end)

test(suite, "picking up twice is refused", function()
	local round = carryingRound()
	local ok, reason = RoundLogic.pickUp(round, RULES, T + 6)
	equal(ok, false, "ok")
	equal(reason, "AlreadyCarrying", "reason")
	equal(round.pickedUpAt, T + 5, "pickedUpAt")
end)

test(suite, "delivering before picking up is refused", function()
	local round = startedRound()
	local ok, reason = RoundLogic.deliver(round, RULES, T + 10, "Library", NO_MIN_TRAVEL)
	equal(ok, false, "ok")
	equal(reason, "NotCarrying", "reason")
	equal(round.phase, "ToPickup", "phase")
end)

test(suite, "delivering with no round is refused", function()
	local round = RoundLogic.newRound()
	local ok, reason = RoundLogic.deliver(round, RULES, T, "Library", NO_MIN_TRAVEL)
	equal(ok, false, "ok")
	equal(reason, "NotRunning", "reason")
end)

test(suite, "delivering to the wrong address keeps the round going", function()
	local round = carryingRound()
	local ok, reason = RoundLogic.deliver(round, RULES, T + 20, "Gym", NO_MIN_TRAVEL)
	equal(ok, false, "ok")
	equal(reason, "WrongTarget", "reason")
	equal(round.phase, "ToDropoff", "phase")
	equal(round.lastScore, nil, "lastScore")
end)

test(suite, "a trip faster than the travel limit is refused", function()
	local round = carryingRound() -- picked up at T + 5
	local ok, reason = RoundLogic.deliver(round, RULES, T + 7, "Library", 6)
	equal(ok, false, "ok")
	equal(reason, "TooFast", "reason")
	equal(round.phase, "ToDropoff", "phase")

	-- The same delivery is accepted once enough time has passed.
	local okLater = RoundLogic.deliver(round, RULES, T + 11, "Library", 6)
	equal(okLater, true, "accepted later")
end)

test(suite, "a delivery scores base points plus 10 per whole second left", function()
	local round = carryingRound()
	-- Delivered at T + 47.3: 42.7 seconds left -> 100 + 42 * 10 = 520.
	local ok = RoundLogic.deliver(round, RULES, T + 47.3, "Library", NO_MIN_TRAVEL)
	equal(ok, true, "ok")
	equal(round.phase, "Delivered", "phase")
	equal(round.lastScore, 520, "lastScore")
	equal(round.best, 520, "best")
	equal(round.newBest, true, "newBest")
	truthy(math.abs((round.lastSeconds :: number) - 47.3) < 1e-9, "lastSeconds")
	equal(RoundLogic.isRunning(round), false, "isRunning")
end)

test(suite, "a worse score keeps the best and is not a new best", function()
	local round = carryingRound()
	RoundLogic.deliver(round, RULES, T + 20, "Library", NO_MIN_TRAVEL) -- 70 s left -> 800

	local T2 = T + 100
	RoundLogic.start(round, RULES, T2, "Gym")
	RoundLogic.pickUp(round, RULES, T2 + 5)
	RoundLogic.deliver(round, RULES, T2 + 60, "Gym", NO_MIN_TRAVEL) -- 30 s left -> 400

	equal(round.lastScore, 400, "lastScore")
	equal(round.best, 800, "best")
	equal(round.newBest, false, "newBest")
end)

test(suite, "a delivery exactly at the deadline scores base points", function()
	local round = carryingRound()
	local ok = RoundLogic.deliver(round, RULES, T + 90, "Library", NO_MIN_TRAVEL)
	equal(ok, true, "ok")
	equal(round.lastScore, 100, "lastScore")
end)

test(suite, "the last moment of the grace period still counts", function()
	local round = carryingRound()
	equal(RoundLogic.expire(round, RULES, T + 90.25), false, "not expired yet")
	local ok = RoundLogic.deliver(round, RULES, T + 90.25, "Library", NO_MIN_TRAVEL)
	equal(ok, true, "ok")
end)

test(suite, "a delivery inside the grace period still counts, for base points", function()
	local round = carryingRound()
	local ok = RoundLogic.deliver(round, RULES, T + 90.2, "Library", NO_MIN_TRAVEL)
	equal(ok, true, "ok")
	equal(round.lastScore, 100, "lastScore")
end)

test(suite, "a delivery after the grace period ends the round as time up", function()
	local round = carryingRound()
	local ok, reason = RoundLogic.deliver(round, RULES, T + 90.3, "Library", NO_MIN_TRAVEL)
	equal(ok, false, "ok")
	equal(reason, "TimeUp", "reason")
	equal(round.phase, "TimeUp", "phase")
	equal(round.lastScore, nil, "lastScore")
	equal(round.best, 0, "best")
end)

test(suite, "the wrong address after the grace period is time up, not wrong address", function()
	local round = carryingRound()
	local ok, reason = RoundLogic.deliver(round, RULES, T + 91, "Gym", NO_MIN_TRAVEL)
	equal(ok, false, "ok")
	equal(reason, "TimeUp", "reason")
	equal(round.phase, "TimeUp", "phase")
end)

test(suite, "matching the best score is not a new best", function()
	local round = carryingRound()
	RoundLogic.deliver(round, RULES, T + 20, "Library", NO_MIN_TRAVEL) -- 800

	local T2 = T + 100
	RoundLogic.start(round, RULES, T2, "Gym")
	RoundLogic.pickUp(round, RULES, T2 + 5)
	RoundLogic.deliver(round, RULES, T2 + 20, "Gym", NO_MIN_TRAVEL) -- 800 again

	equal(round.lastScore, 800, "lastScore")
	equal(round.best, 800, "best")
	equal(round.newBest, false, "newBest")
end)

test(suite, "no time is left once a round is finished", function()
	local round = carryingRound()
	RoundLogic.deliver(round, RULES, T + 30, "Library", NO_MIN_TRAVEL)
	equal(RoundLogic.timeLeft(round, T + 31), 0, "timeLeft")
end)

test(suite, "a pickup after the grace period ends the round as time up", function()
	local round = startedRound()
	local ok, reason = RoundLogic.pickUp(round, RULES, T + 91)
	equal(ok, false, "ok")
	equal(reason, "TimeUp", "reason")
	equal(round.phase, "TimeUp", "phase")
end)

test(suite, "expire does nothing before the deadline and grace period", function()
	local round = startedRound()
	equal(RoundLogic.expire(round, RULES, T + 89), false, "before deadline")
	equal(RoundLogic.expire(round, RULES, T + 90.1), false, "inside grace")
	equal(round.phase, "ToPickup", "phase")
end)

test(suite, "expire ends a running round after the grace period", function()
	local round = carryingRound()
	equal(RoundLogic.expire(round, RULES, T + 90.3), true, "expired")
	equal(round.phase, "TimeUp", "phase")
	equal(RoundLogic.timeLeft(round, T + 95), 0, "timeLeft")
	-- A second call reports that nothing changed.
	equal(RoundLogic.expire(round, RULES, T + 96), false, "second expire")
end)

test(suite, "expire never touches a finished round", function()
	local round = carryingRound()
	RoundLogic.deliver(round, RULES, T + 30, "Library", NO_MIN_TRAVEL)
	equal(RoundLogic.expire(round, RULES, T + 200), false, "expired")
	equal(round.phase, "Delivered", "phase")
	equal(round.lastScore, 700, "lastScore")
end)

test(suite, "a new round can start after time up and gets a new id", function()
	local round = startedRound()
	RoundLogic.expire(round, RULES, T + 91)
	local ok = RoundLogic.start(round, RULES, T + 100, "Gym")
	equal(ok, true, "ok")
	equal(round.phase, "ToPickup", "phase")
	equal(round.roundId, 2, "roundId")
	equal(round.deadline, T + 190, "deadline")
	equal(round.pickedUpAt, nil, "pickedUpAt")
end)

test(suite, "starting again clears the previous result but keeps the best", function()
	local round = carryingRound()
	RoundLogic.deliver(round, RULES, T + 30, "Library", NO_MIN_TRAVEL)
	RoundLogic.start(round, RULES, T + 100, "Gym")
	equal(round.lastScore, nil, "lastScore")
	equal(round.lastSeconds, nil, "lastSeconds")
	equal(round.newBest, false, "newBest")
	equal(round.best, 700, "best")
end)

test(suite, "scoreFor rounds seconds down and never goes below base points", function()
	equal(RoundLogic.scoreFor(RULES, 90), 1000, "full time")
	equal(RoundLogic.scoreFor(RULES, 0.99), 100, "under one second")
	equal(RoundLogic.scoreFor(RULES, -5), 100, "negative")
end)

test(suite, "chooseTarget asks for one random pick among the other destinations", function()
	local ids = { "Gym", "Library", "Cafeteria" }
	local expected = { "Gym", "Cafeteria" } -- the list without "Library", in order
	for index = 1, 2 do
		local calls = 0
		local chosen = RoundLogic.chooseTarget(ids, "Library", function(count)
			calls += 1
			equal(count, 2, "choices offered")
			return index
		end)
		equal(calls, 1, "random picks")
		equal(chosen, expected[index], `pick {index}`)
	end
end)

test(suite, "chooseTarget offers every destination on the first round", function()
	local ids = { "Gym", "Library", "Cafeteria" }
	local offered = 0
	local chosen = RoundLogic.chooseTarget(ids, nil, function(count)
		offered = count
		return 3
	end)
	equal(offered, 3, "choices offered")
	equal(chosen, "Cafeteria", "chosen")
end)

test(suite, "chooseTarget repeats when only one destination exists", function()
	local chosen = RoundLogic.chooseTarget({ "Gym" }, "Gym", function()
		return 1
	end)
	equal(chosen, "Gym", "chosen")
end)

test(suite, "chooseTarget returns nil when there are no destinations", function()
	local chosen = RoundLogic.chooseTarget({}, nil, function()
		return 1
	end)
	equal(chosen, nil, "chosen")
end)

test(suite, "chooseTarget does not change the list it was given", function()
	local ids = { "Gym" }
	RoundLogic.chooseTarget(ids, "Gym", function()
		return 1
	end)
	equal(#ids, 1, "length")
	equal(ids[1], "Gym", "first")
end)

return suite
