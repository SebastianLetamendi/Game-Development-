--!strict
-- Shows the player where to go next:
--   * a tall glowing beacon over the Depot or the destination mailbox
--   * a label above it with the place name and the distance
--   * a guide line (Beam) from the character to the beacon
-- It also hides every ProximityPrompt that is not useful right now, so
-- players only see "Pick up package" or "Deliver package" where it counts.
--
-- Everything here exists only on this player's computer. Hiding a prompt is
-- a convenience, not security: the server re-checks every pickup and
-- delivery no matter which prompt was used.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage:WaitForChild("CampusDeliveryDash"):WaitForChild("Net"))

-- Must match MapContract.PROMPT_TAG on the server.
local PROMPT_TAG = "CampusDeliveryDashPrompt"
local BEACON_HEIGHT = 60

local PICKUP_COLOR = Color3.fromRGB(255, 180, 40)
local DROPOFF_COLOR = Color3.fromRGB(80, 220, 120)

export type Marker = {
	render: (snapshot: Net.Snapshot) -> (),
	update: () -> (),
}

local Marker = {}

function Marker.create(): Marker
	local player = Players.LocalPlayer

	local folder = Instance.new("Folder")
	folder.Name = "CampusDeliveryDashMarker"

	local beacon = Instance.new("Part")
	beacon.Name = "Beacon"
	beacon.Shape = Enum.PartType.Cylinder
	beacon.Size = Vector3.new(BEACON_HEIGHT, 3, 3)
	beacon.Anchored = true
	beacon.CanCollide = false
	beacon.CanQuery = false
	beacon.CanTouch = false
	beacon.CastShadow = false
	beacon.Material = Enum.Material.Neon
	beacon.Transparency = 1
	beacon.Parent = folder

	-- Invisible point the label and guide line attach to.
	local anchor = Instance.new("Part")
	anchor.Name = "LabelAnchor"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Parent = folder

	local targetAttachment = Instance.new("Attachment")
	targetAttachment.Name = "Target"
	targetAttachment.Parent = anchor

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Adornee = anchor
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Size = UDim2.fromOffset(220, 60)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Enabled = false
	billboard.Parent = folder

	local placeLabel = Instance.new("TextLabel")
	placeLabel.Name = "Place"
	placeLabel.BackgroundTransparency = 1
	placeLabel.Size = UDim2.fromScale(1, 0.6)
	placeLabel.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	placeLabel.TextScaled = true
	placeLabel.TextColor3 = Color3.new(1, 1, 1)
	placeLabel.TextStrokeTransparency = 0.2
	placeLabel.Parent = billboard

	local distanceLabel = Instance.new("TextLabel")
	distanceLabel.Name = "Distance"
	distanceLabel.BackgroundTransparency = 1
	distanceLabel.Position = UDim2.fromScale(0, 0.6)
	distanceLabel.Size = UDim2.fromScale(1, 0.4)
	distanceLabel.FontFace = Font.fromEnum(Enum.Font.Gotham)
	distanceLabel.TextScaled = true
	distanceLabel.TextColor3 = Color3.new(1, 1, 1)
	distanceLabel.TextStrokeTransparency = 0.2
	distanceLabel.Parent = billboard

	local beam = Instance.new("Beam")
	beam.Name = "GuideLine"
	beam.Attachment1 = targetAttachment
	beam.FaceCamera = true
	beam.Width0 = 0.4
	beam.Width1 = 0.4
	beam.LightEmission = 1
	beam.Segments = 1
	beam.Transparency = NumberSequence.new(0.35)
	beam.Enabled = false
	beam.Parent = folder

	folder.Parent = Workspace

	local active = false
	local wantedPrompt: { kind: string, targetId: string? } = { kind = "None" }
	local characterRoot: BasePart? = nil

	local function applyPrompt(prompt: Instance)
		if not prompt:IsA("ProximityPrompt") then
			return
		end
		local kind = prompt:GetAttribute("Kind")
		local enabled = kind == wantedPrompt.kind
		if enabled and kind == "Destination" then
			enabled = prompt:GetAttribute("TargetId") == wantedPrompt.targetId
		end
		prompt.Enabled = enabled
	end

	local function applyAllPrompts()
		for _, prompt in CollectionService:GetTagged(PROMPT_TAG) do
			applyPrompt(prompt)
		end
	end
	-- Prompts that load later (for example with instance streaming) get the
	-- right visibility as soon as they appear.
	CollectionService:GetInstanceAddedSignal(PROMPT_TAG):Connect(applyPrompt)
	applyAllPrompts()

	local function render(snapshot: Net.Snapshot)
		local position = snapshot.objectivePosition
		active = position ~= nil and (snapshot.phase == "ToPickup" or snapshot.phase == "ToDropoff")

		if snapshot.phase == "ToPickup" then
			wantedPrompt = { kind = "Depot" }
		elseif snapshot.phase == "ToDropoff" then
			wantedPrompt = { kind = "Destination", targetId = snapshot.targetId }
		else
			wantedPrompt = { kind = "None" }
		end
		applyAllPrompts()

		if not active or position == nil then
			beacon.Transparency = 1
			billboard.Enabled = false
			beam.Enabled = false
			return
		end

		local color = if snapshot.phase == "ToPickup" then PICKUP_COLOR else DROPOFF_COLOR
		-- Cylinders point along X, so rotate this one to stand upright with
		-- its base just below the objective.
		beacon.CFrame = CFrame.new(position + Vector3.new(0, BEACON_HEIGHT / 2 - 3, 0))
			* CFrame.Angles(0, 0, math.rad(90))
		beacon.Color = color
		beacon.Transparency = 0.55
		anchor.Position = position + Vector3.new(0, 5, 0)
		placeLabel.Text = if snapshot.phase == "ToPickup"
			then "DEPOT"
			else string.upper(snapshot.targetName or "DESTINATION")
		billboard.Enabled = true
		beam.Color = ColorSequence.new(color)
	end

	-- Called every frame: keeps the guide line attached to the current
	-- character (it changes after a respawn) and updates the distance.
	local function update()
		local character = player.Character
		local found = character and character:FindFirstChild("HumanoidRootPart")
		local root: BasePart? = if found and found:IsA("BasePart") then found else nil

		if root ~= characterRoot then
			characterRoot = root
			if characterRoot then
				local attachment = Instance.new("Attachment")
				attachment.Name = "CampusDeliveryDashGuide"
				attachment.Parent = characterRoot
				beam.Attachment0 = attachment
			else
				beam.Attachment0 = nil
			end
		end

		beam.Enabled = active and characterRoot ~= nil
		if active and characterRoot then
			local studs = (characterRoot.Position - anchor.Position).Magnitude
			distanceLabel.Text = `{math.floor(studs)} studs`
		end
	end

	return {
		render = render,
		update = update,
	}
end

return Marker
