--!strict
-- Finds the few parts the game logic needs inside the map and checks that
-- the map is usable. Everything else in the map is scenery the scripts ignore,
-- so you can redesign the campus freely as long as these still exist:
--
--   CampusMap (Model in Workspace)
--     StartPad       BasePart: where a character is placed when a round starts
--     Depot          BasePart: where the package is picked up
--     Destinations   Folder: one BasePart per delivery address
--                    (or a Model with a PrimaryPart). The child's Name is the
--                    address id; an optional "DisplayName" string attribute is
--                    what players see.
--
-- StartPad, Depot and every destination part must be Anchored (or welded to
-- an anchored part), or the game does not start (see isFixed).
--
-- This module also creates the ProximityPrompts players use at the Depot and
-- at each destination.

local CollectionService = game:GetService("CollectionService")

-- Tag on every prompt this game creates. The client uses it to show only
-- the prompt that matters for the current step.
local PROMPT_TAG = "CampusDeliveryDashPrompt"

export type MapParts = {
	model: Instance,
	startPad: BasePart,
	depot: BasePart,
	destinations: { [string]: BasePart }, -- address id -> part
	destinationIds: { string }, -- the same ids, sorted, for picking at random
	displayNames: { [string]: string }, -- address id -> name shown to players
}

export type Prompts = {
	depot: ProximityPrompt,
	destinations: { [string]: ProximityPrompt },
}

export type PromptSettings = {
	PROMPT_DISTANCE: number,
	PROMPT_HOLD_SECONDS: number,
}

local MapContract = {}

MapContract.PROMPT_TAG = PROMPT_TAG

-- A BasePart stands for itself; a Model stands for its PrimaryPart.
local function asPart(instance: Instance?): BasePart?
	if instance == nil then
		return nil
	end
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") then
		return instance.PrimaryPart
	end
	return nil
end

-- The parts the rules depend on must not move. An unanchored part is
-- simulated by a nearby player's computer, so a cheater could drag a mailbox
-- next to the Depot or carry the Depot away.
local function isFixed(part: BasePart, problems: { string }): boolean
	if part:IsGrounded() then
		return true
	end
	table.insert(problems, `{part:GetFullName()} must be Anchored (or welded to an anchored part)`)
	return false
end

-- Returns the parts, or nil plus a list of human-readable problems.
-- Problems that do not stop the game (for example an ignored child) are
-- returned alongside the parts so the server can warn about them.
function MapContract.find(map: Instance): (MapParts?, { string })
	local problems: { string } = {}
	local fatal = false

	local startPad = asPart(map:FindFirstChild("StartPad"))
	if startPad == nil then
		table.insert(problems, `{map:GetFullName()} needs a part named StartPad`)
		fatal = true
	elseif not isFixed(startPad, problems) then
		fatal = true
	end

	local depot = asPart(map:FindFirstChild("Depot"))
	if depot == nil then
		table.insert(problems, `{map:GetFullName()} needs a part named Depot`)
		fatal = true
	elseif not isFixed(depot, problems) then
		fatal = true
	end

	local destinations: { [string]: BasePart } = {}
	local destinationIds: { string } = {}
	local displayNames: { [string]: string } = {}
	local folder = map:FindFirstChild("Destinations")
	if folder == nil then
		table.insert(problems, `{map:GetFullName()} needs a folder named Destinations`)
		fatal = true
	else
		for _, child in folder:GetChildren() do
			local part = asPart(child)
			if part == nil then
				table.insert(
					problems,
					`Ignoring {child:GetFullName()}: use a part, or a Model with a PrimaryPart`
				)
			elseif destinations[child.Name] then
				table.insert(
					problems,
					`Ignoring {child:GetFullName()}: another destination has the same name`
				)
			else
				if not isFixed(part, problems) then
					fatal = true
				end
				destinations[child.Name] = part
				table.insert(destinationIds, child.Name)
				local label = child:GetAttribute("DisplayName")
				displayNames[child.Name] = if typeof(label) == "string" and label ~= ""
					then label
					else child.Name
			end
		end
		if #destinationIds == 0 then
			table.insert(problems, `{folder:GetFullName()} has no destination parts`)
			fatal = true
		end
	end

	if fatal or startPad == nil or depot == nil then
		return nil, problems
	end

	table.sort(destinationIds)
	return {
		model = map,
		startPad = startPad,
		depot = depot,
		destinations = destinations,
		destinationIds = destinationIds,
		displayNames = displayNames,
	},
		problems
end

local function makePrompt(
	part: BasePart,
	actionText: string,
	objectText: string,
	kind: string,
	settings: PromptSettings
): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CampusDeliveryDashPrompt"
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = settings.PROMPT_HOLD_SECONDS
	prompt.MaxActivationDistance = settings.PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Kind", kind)
	prompt.Parent = part
	CollectionService:AddTag(prompt, PROMPT_TAG)
	return prompt
end

-- Creates one prompt on the Depot and one on each destination.
function MapContract.createPrompts(parts: MapParts, settings: PromptSettings): Prompts
	local depotPrompt = makePrompt(parts.depot, "Pick up package", "Depot", "Depot", settings)

	local destinationPrompts: { [string]: ProximityPrompt } = {}
	for _, id in parts.destinationIds do
		local prompt = makePrompt(
			parts.destinations[id],
			"Deliver package",
			parts.displayNames[id],
			"Destination",
			settings
		)
		prompt:SetAttribute("TargetId", id)
		destinationPrompts[id] = prompt
	end

	return { depot = depotPrompt, destinations = destinationPrompts }
end

return MapContract
