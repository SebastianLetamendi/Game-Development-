--!strict
-- Client entry point. Runs once on each player's computer when they join.
-- It only displays what the server reports and forwards button presses;
-- it never decides anything about a round.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage:WaitForChild("CampusDeliveryDash"):WaitForChild("Net"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Marker = require(script.Parent:WaitForChild("Marker"))

-- How long to wait for the server to create the remotes before showing a
-- setup problem. Building the greybox map takes well under a second.
local REMOTES_TIMEOUT_SECONDS = 30

local player = Players.LocalPlayer
local remotes: Net.Remotes? = nil

local hud = Hud.create(player:WaitForChild("PlayerGui"), function()
	if remotes then
		remotes.StartRound:FireServer()
	end
end)
local marker = Marker.create()

remotes = Net.waitForRemotes(REMOTES_TIMEOUT_SECONDS)
if remotes == nil then
	hud.showSetupProblem()
	return
end

local current: Net.Snapshot? = nil

-- Snapshots can arrive out of order (the first one is fetched with
-- GetRoundState while RoundState events may already be arriving), so keep
-- only the newest by its sequence number.
local function apply(snapshot: Net.Snapshot?)
	if snapshot == nil or (current ~= nil and snapshot.seq <= current.seq) then
		return
	end
	current = snapshot
	hud.render(snapshot)
	marker.render(snapshot)
end

remotes.RoundState.OnClientEvent:Connect(apply)

local ok, initial = pcall(function()
	return (remotes :: Net.Remotes).GetRoundState:InvokeServer()
end)
if ok then
	apply(initial)
else
	warn(`[CampusDeliveryDash] Could not fetch the round state: {initial}`)
end

RunService.RenderStepped:Connect(function()
	local snapshot = current
	if snapshot then
		hud.tick(snapshot, Workspace:GetServerTimeNow())
	end
	marker.update()
end)
