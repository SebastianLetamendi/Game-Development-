--!strict
-- Server entry point. Runs once when a server (or a Studio play test) starts.
--
-- 1. Use Workspace.CampusMap, or build the greybox map if it is missing.
-- 2. Check the map has a StartPad, a Depot and at least one destination.
-- 3. Create the ProximityPrompts and the remotes clients talk through.
-- 4. Hand everything to RoundService, which runs the rounds.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.CampusDeliveryDash.Config)
local Net = require(ReplicatedStorage.CampusDeliveryDash.Net)
local MapBuilder = require(script.Parent.MapBuilder)
local MapContract = require(script.Parent.MapContract)
local RoundService = require(script.Parent.RoundService)

local LOG_PREFIX = "[CampusDeliveryDash]"

local map: Instance? = Workspace:FindFirstChild(Config.MAP_NAME)
if map == nil then
	print(
		`{LOG_PREFIX} No {Config.MAP_NAME} in Workspace, so the greybox map was built for this test.`
	)
	print(`{LOG_PREFIX} To edit the map by hand, see the comment at the top of MapBuilder.`)
	map = MapBuilder.build(Workspace)
end
assert(map, "unreachable: the map was just found or built")

local parts, problems = MapContract.find(map)
for _, problem in problems do
	warn(`{LOG_PREFIX} Map problem: {problem}`)
end
if parts == nil then
	warn(`{LOG_PREFIX} The game did not start. Fix the map problems above, then press Play again.`)
	return
end

local prompts = MapContract.createPrompts(parts, Config)
local remotes = Net.createRemotes()
RoundService.start(parts, prompts, remotes)

print(
	`{LOG_PREFIX} Ready: {#parts.destinationIds} destinations, {Config.ROUND_SECONDS}-second rounds.`
)
