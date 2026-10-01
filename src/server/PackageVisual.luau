--!strict
-- The package a character carries between the Depot and the destination.
-- It is only a visual: whether a player "has" the package is decided by the
-- round state in RoundService, never by this part existing.
--
-- To use your own model later (for example a package made in Blender),
-- put a single MeshPart or Part named "PackageTemplate" in ServerStorage.
-- It is cloned instead of the default brown box.

local ServerStorage = game:GetService("ServerStorage")

local CARRIED_NAME = "CarriedPackage"

local PackageVisual = {}

local function makePackage(): BasePart
	local template = ServerStorage:FindFirstChild("PackageTemplate")
	if template and template:IsA("BasePart") then
		return template:Clone()
	end
	local box = Instance.new("Part")
	box.Size = Vector3.new(2, 1.6, 1.6)
	box.Color = Color3.fromRGB(170, 120, 70)
	box.Material = Enum.Material.Cardboard
	return box
end

-- Removes the carried package from `character`, if there is one.
function PackageVisual.remove(character: Model?)
	if character == nil then
		return
	end
	local existing = character:FindFirstChild(CARRIED_NAME)
	if existing then
		existing:Destroy()
	end
end

-- Puts a package in front of the character's chest. Does nothing if the
-- character has no HumanoidRootPart (for example while it is respawning).
function PackageVisual.attach(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return
	end
	PackageVisual.remove(character)

	local package = makePackage()
	package.Name = CARRIED_NAME
	package.Anchored = false
	-- Massless and non-colliding so it never changes how the character moves.
	package.Massless = true
	package.CanCollide = false
	package.CanTouch = false
	package.CanQuery = false
	package.CFrame = root.CFrame * CFrame.new(0, 0.3, -1.6)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = package
	weld.Parent = package

	package.Parent = character
end

return PackageVisual
