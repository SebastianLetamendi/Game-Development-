--!strict
-- Runs a separate delivery round for every player on the server.
--
-- The server is the only place where rounds change. Clients can ask to start
-- a round (StartRound) and use ProximityPrompts; everything they send is
-- checked here before RoundLogic is called:
--   * Start requests are ignored while a round is running or if repeated
--     within START_COOLDOWN_SECONDS.
--   * Pickups and deliveries must come from a living character standing
--     near the right part.
--   * A delivery faster than the distance allows (MAX_TRAVEL_SPEED) is
--     refused, which stops teleporting to the mailbox.
--   * Scores and times are calculated here. No remote accepts them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.CampusDeliveryDash.Config)
local Net = require(ReplicatedStorage.CampusDeliveryDash.Net)
local RoundLogic = require(ReplicatedStorage.CampusDeliveryDash.RoundLogic)
local MapContract = require(script.Parent.MapContract)
local PackageVisual = require(script.Parent.PackageVisual)

type Session = {
	player: Player,
	round: RoundLogic.Round,
	seq: number, -- snapshot counter so clients can drop out-of-order updates
	lastStartRequest: number, -- os.clock() time of the last accepted Start press
	bestValue: IntValue, -- leaderstats "Best" shown in the player list
}

-- What players are told when the server refuses an action. Reasons left out
-- of this table get no message from refuse: AlreadyRunning only happens when
-- a button is pressed twice, TimeUp is explained by the results panel, and
-- WrongTarget builds its own message in onDestinationTriggered.
local MESSAGES: { [string]: string } = {
	NotRunning = "Press Start to begin a delivery.",
	AlreadyCarrying = "You are already carrying a package.",
	NotCarrying = "Pick up the package at the Depot first.",
	TooFast = "Delivery refused: that trip was impossibly fast.",
	NoCharacter = "Wait until your character has respawned.",
}

local RoundService = {}

local sessions: { [Player]: Session } = {}
local random = Random.new()

-- Three spots side by side on the StartPad, used in turn, so two players who
-- start at the same moment are not placed inside each other. They are level
-- with each other, so no spot is closer to the Depot.
local START_SPOTS = { 0, -3, 3 }
local nextStartSpot = 0

local mapParts: MapContract.MapParts
local remotes: Net.Remotes

local function now(): number
	-- The same clock clients read, so their countdowns match the server's.
	return Workspace:GetServerTimeNow()
end

-- The living character's root part, or nil if the player has no usable
-- character right now (not spawned yet, dead, or respawning).
local function getLivingRoot(player: Player): BasePart?
	local character = player.Character
	if character == nil then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or humanoid.Health <= 0 or root == nil or not root:IsA("BasePart") then
		return nil
	end
	return root
end

local function isNear(root: BasePart, part: BasePart): boolean
	-- Prompts measure distance to the part, and a large part's centre can be
	-- a few studs from its edge, so half its size is allowed for as well.
	local allowed = Config.PROMPT_DISTANCE
		+ Config.PROMPT_DISTANCE_TOLERANCE
		+ part.Size.Magnitude / 2
	return (root.Position - part.Position).Magnitude <= allowed
end

local function snapshot(session: Session, message: string?): Net.Snapshot
	local round = session.round
	local targetId = round.targetId
	local targetName = if targetId then mapParts.displayNames[targetId] else nil

	local objective: string? = nil
	local objectivePosition: Vector3? = nil
	if round.phase == "ToPickup" then
		objective = "Pick up the package at the Depot"
		objectivePosition = mapParts.depot.Position
	elseif round.phase == "ToDropoff" and targetId then
		objective = `Deliver the package to {targetName}`
		objectivePosition = mapParts.destinations[targetId].Position
	end

	session.seq += 1
	return {
		seq = session.seq,
		phase = round.phase,
		roundId = round.roundId,
		roundSeconds = Config.ROUND_SECONDS,
		deadline = if RoundLogic.isRunning(round) then round.deadline else nil,
		objective = objective,
		objectivePosition = objectivePosition,
		targetId = targetId,
		targetName = targetName,
		lastScore = round.lastScore,
		lastSeconds = round.lastSeconds,
		best = round.best,
		newBest = round.newBest,
		message = message,
	}
end

-- Sends the player's current round state to their client.
local function push(session: Session, message: string?)
	session.bestValue.Value = session.round.best
	remotes.RoundState:FireClient(session.player, snapshot(session, message))
end

-- A prompt the player finished this soon after their time ran out is
-- refused without a message: the results panel already explains it.
local LATE_PROMPT_SECONDS = 2

local function refuse(session: Session, reason: string)
	local round = session.round
	local deadline = round.deadline
	if
		reason == "NotRunning"
		and round.phase == "TimeUp"
		and deadline ~= nil
		and now() < deadline + Config.GRACE_SECONDS + LATE_PROMPT_SECONDS
	then
		return
	end
	local message = MESSAGES[reason]
	if message then
		push(session, message)
	end
end

local function endRoundIfExpired(session: Session)
	if RoundLogic.expire(session.round, Config, now()) then
		PackageVisual.remove(session.player.Character)
		push(session)
	end
end

-- Ends the round when its time runs out, unless it already finished or a
-- newer round replaced it.
local function scheduleTimeUp(session: Session, roundId: number)
	local function check()
		if sessions[session.player] ~= session or session.round.roundId ~= roundId then
			return -- the player left, or a newer round started
		end
		endRoundIfExpired(session)
		local deadline = session.round.deadline
		if RoundLogic.isRunning(session.round) and deadline then
			-- task.delay can wake slightly before the server clock passes
			-- the deadline; if so, check again shortly.
			local remaining = deadline + Config.GRACE_SECONDS - now()
			task.delay(math.max(remaining, 0) + 0.05, check)
		end
	end
	task.delay(Config.ROUND_SECONDS + Config.GRACE_SECONDS, check)
end

-- Where a character stands when a round starts: just above the StartPad,
-- facing the Depot, on the next of the START_SPOTS.
local function nextStartCFrame(): CFrame
	nextStartSpot = nextStartSpot % #START_SPOTS + 1
	local pad = mapParts.startPad
	local depot = mapParts.depot.Position
	local top = pad.Position + Vector3.new(0, pad.Size.Y / 2 + 3, 0)
	local facing = CFrame.lookAt(top, Vector3.new(depot.X, top.Y, depot.Z))
	-- Step sideways, across the direction to the Depot, but stay on the pad
	-- even if a hand-made pad is narrow (or is not a flat box).
	local maxSideways = math.max(0, math.min(pad.Size.X, pad.Size.Z) / 2 - 1.5)
	local sideways = math.clamp(START_SPOTS[nextStartSpot], -maxSideways, maxSideways)
	return facing * CFrame.new(sideways, 0, 0)
end

local function startRound(session: Session)
	local player = session.player
	if RoundLogic.isRunning(session.round) then
		return -- a second press while playing; ignore it
	end
	local root = getLivingRoot(player)
	if root == nil then
		refuse(session, "NoCharacter")
		return
	end
	local targetId = RoundLogic.chooseTarget(
		mapParts.destinationIds,
		session.round.targetId,
		function(count)
			return random:NextInteger(1, count)
		end
	)
	if targetId == nil then
		return -- MapContract guarantees at least one destination
	end

	local started, reason = RoundLogic.start(session.round, Config, now(), targetId)
	if not started then
		refuse(session, reason or "NotRunning")
		return
	end

	-- Every round starts on the StartPad so scores are comparable.
	local character = player.Character
	if character then
		PackageVisual.remove(character)
		character:PivotTo(nextStartCFrame())
	end

	scheduleTimeUp(session, session.round.roundId)
	push(session)
end

local function onDepotTriggered(player: Player)
	local session = sessions[player]
	local root = getLivingRoot(player)
	if session == nil or root == nil or not isNear(root, mapParts.depot) then
		return
	end
	local ok, reason = RoundLogic.pickUp(session.round, Config, now())
	if ok then
		local character = player.Character
		if character then
			PackageVisual.attach(character)
		end
		push(session)
	elseif reason == "TimeUp" then
		PackageVisual.remove(player.Character)
		push(session)
	elseif reason then
		refuse(session, reason)
	end
end

local function onDestinationTriggered(player: Player, targetId: string)
	local session = sessions[player]
	local root = getLivingRoot(player)
	local part: BasePart? = mapParts.destinations[targetId]
	if session == nil or root == nil or part == nil or not isNear(root, part) then
		return
	end
	local minTravelSeconds = (part.Position - mapParts.depot.Position).Magnitude
		/ Config.MAX_TRAVEL_SPEED
	local ok, reason = RoundLogic.deliver(session.round, Config, now(), targetId, minTravelSeconds)
	if ok then
		PackageVisual.remove(player.Character)
		push(session)
	elseif reason == "TimeUp" then
		PackageVisual.remove(player.Character)
		push(session)
	elseif reason == "WrongTarget" then
		local wanted = session.round.targetId
		local wantedName = if wanted then mapParts.displayNames[wanted] else "another address"
		push(session, `Wrong address. This package goes to {wantedName}.`)
	elseif reason then
		refuse(session, reason)
	end
end

local function onCharacterAdded(session: Session, character: Model)
	-- A character that respawns mid-delivery keeps the package; the timer
	-- kept running, so dying already cost time.
	if session.round.phase ~= "ToDropoff" then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if
		root
		and sessions[session.player] == session
		and session.player.Character == character
		and session.round.phase == "ToDropoff"
	then
		PackageVisual.attach(character)
	end
end

local function addPlayer(player: Player)
	if sessions[player] then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local bestValue = Instance.new("IntValue")
	bestValue.Name = "Best"
	bestValue.Parent = leaderstats
	leaderstats.Parent = player

	local session: Session = {
		player = player,
		round = RoundLogic.newRound(),
		seq = 0,
		lastStartRequest = -math.huge,
		bestValue = bestValue,
	}
	sessions[player] = session

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(session, character)
	end)
end

-- Connects everything. Called once by Main.server.luau.
function RoundService.start(
	parts: MapContract.MapParts,
	prompts: MapContract.Prompts,
	netRemotes: Net.Remotes
)
	mapParts = parts
	remotes = netRemotes

	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
	-- Players who joined before this script finished loading.
	for _, player in Players:GetPlayers() do
		addPlayer(player)
	end

	-- StartRound takes no arguments; anything a client adds is ignored.
	remotes.StartRound.OnServerEvent:Connect(function(player)
		local session = sessions[player]
		if session == nil then
			return
		end
		local clock = os.clock()
		if clock - session.lastStartRequest < Config.START_COOLDOWN_SECONDS then
			return
		end
		session.lastStartRequest = clock
		startRound(session)
	end)

	remotes.GetRoundState.OnServerInvoke = function(player: Player): Net.Snapshot?
		local session = sessions[player]
		if session == nil then
			return nil -- the player is leaving
		end
		return snapshot(session)
	end

	prompts.depot.Triggered:Connect(onDepotTriggered)
	for targetId, prompt in prompts.destinations do
		prompt.Triggered:Connect(function(player)
			onDestinationTriggered(player, targetId)
		end)
	end
end

return RoundService
