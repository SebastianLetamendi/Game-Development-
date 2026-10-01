--!strict
-- The network contract between server and clients.
--
-- Clients may only *ask* for things:
--   StartRound     RemoteEvent     client -> server, no arguments
--   GetRoundState  RemoteFunction  client -> server, returns a Snapshot
--
-- Only the server *decides* things and reports them:
--   RoundState     RemoteEvent     server -> one client, sends a Snapshot
--
-- There is deliberately no remote that accepts a score, a time or a
-- position from a client. Pickups and deliveries arrive through
-- ProximityPrompt.Triggered on the server, which RoundService re-checks.

-- Everything a client needs to draw the HUD and the destination marker.
export type Snapshot = {
	seq: number, -- increases with every snapshot for this player; older ones are ignored
	phase: string, -- a RoundLogic.Phase
	roundId: number,
	roundSeconds: number,
	deadline: number?, -- Workspace:GetServerTimeNow() value when the timer hits zero
	objective: string?, -- e.g. "Pick up the package at the Depot"
	objectivePosition: Vector3?, -- where the marker should point
	targetId: string?,
	targetName: string?,
	lastScore: number?,
	lastSeconds: number?,
	best: number,
	newBest: boolean,
	message: string?, -- one-off feedback such as "Wrong address"
}

export type Remotes = {
	StartRound: RemoteEvent,
	RoundState: RemoteEvent,
	GetRoundState: RemoteFunction,
}

local FOLDER_NAME = "Remotes"

local Net = {}

-- Server only: creates the remotes inside this module's folder
-- (ReplicatedStorage.CampusDeliveryDash.Remotes) and returns them.
function Net.createRemotes(): Remotes
	local existing = script.Parent:FindFirstChild(FOLDER_NAME)
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME

	local startRound = Instance.new("RemoteEvent")
	startRound.Name = "StartRound"
	startRound.Parent = folder

	local roundState = Instance.new("RemoteEvent")
	roundState.Name = "RoundState"
	roundState.Parent = folder

	local getRoundState = Instance.new("RemoteFunction")
	getRoundState.Name = "GetRoundState"
	getRoundState.Parent = folder

	-- Parent last so clients see a complete folder in one step.
	folder.Parent = script.Parent

	return {
		StartRound = startRound,
		RoundState = roundState,
		GetRoundState = getRoundState,
	}
end

-- Client only: waits up to `timeoutSeconds` for the server to create the
-- remotes. Returns nil if they never appear, which means the server failed to
-- start the game (its Output window will say why).
function Net.waitForRemotes(timeoutSeconds: number): Remotes?
	local folder = script.Parent:WaitForChild(FOLDER_NAME, timeoutSeconds)
	if folder == nil then
		return nil
	end
	local startRound = folder:WaitForChild("StartRound", timeoutSeconds)
	local roundState = folder:WaitForChild("RoundState", timeoutSeconds)
	local getRoundState = folder:WaitForChild("GetRoundState", timeoutSeconds)
	if
		startRound == nil
		or not startRound:IsA("RemoteEvent")
		or roundState == nil
		or not roundState:IsA("RemoteEvent")
		or getRoundState == nil
		or not getRoundState:IsA("RemoteFunction")
	then
		return nil
	end
	return {
		StartRound = startRound,
		RoundState = roundState,
		GetRoundState = getRoundState,
	}
end

return Net
