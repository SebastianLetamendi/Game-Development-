--!strict
-- Builds the greybox campus out of plain, anchored parts: ground, a central
-- plaza, the Depot, a StartPad, six buildings with mailboxes, paths, hedges
-- and a few obstacles. It is a placeholder for testing the game loop, not
-- final art.
--
-- Main.server.luau calls MapBuilder.build(workspace) only when Workspace has
-- no model named Config.MAP_NAME ("CampusMap"). To get a copy you can edit
-- by hand, run this once in Studio's Command Bar while *not* playing, then
-- save the place:
--
--   require(game.ServerScriptService.CampusDeliveryDash.MapBuilder).build(workspace)
--
-- After that the server uses your edited map instead of building a new one.
-- The parts the game logic depends on are listed in docs/ARCHITECTURE.md
-- ("Map contract"): StartPad, Depot and the Destinations folder.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.CampusDeliveryDash.Config)

-- Height of the top of our ground slab. A template Baseplate's top is at 0;
-- sitting slightly above it avoids flickering where the two surfaces meet.
local GROUND_TOP = 0.2
local GROUND_SIZE = 640
local PLAZA_RADIUS = 36
local PATH_WIDTH = 10

local COLORS = {
	ground = Color3.fromRGB(106, 148, 86),
	plaza = Color3.fromRGB(206, 201, 190),
	path = Color3.fromRGB(186, 180, 166),
	hedge = Color3.fromRGB(58, 105, 60),
	trunk = Color3.fromRGB(105, 76, 52),
	canopy = Color3.fromRGB(76, 130, 70),
	depot = Color3.fromRGB(240, 160, 40),
	startPad = Color3.fromRGB(80, 200, 120),
	box = Color3.fromRGB(170, 120, 70),
	mailbox = Color3.fromRGB(40, 70, 140),
	post = Color3.fromRGB(70, 70, 75),
	door = Color3.fromRGB(60, 50, 45),
	barrier = Color3.fromRGB(235, 120, 30),
	bench = Color3.fromRGB(125, 90, 60),
	terrace = Color3.fromRGB(150, 150, 150),
}

type Building = {
	id: string, -- name of the mailbox part in Destinations; must be unique
	displayName: string, -- shown to players
	position: Vector3, -- centre of the building's footprint (Y is ignored)
	size: Vector3, -- width, height, depth
	color: Color3,
	terraceHeight: number?, -- if set, the building stands on a raised terrace with a ramp
}

-- Each building faces the plaza at the origin. Distances are chosen so a
-- direct walk from the Depot takes roughly 10-20 seconds at the default
-- WalkSpeed of 16 studs per second.
local BUILDINGS: { Building } = {
	{
		id = "Library",
		displayName = "Library",
		position = Vector3.new(-170, 0, -150),
		size = Vector3.new(56, 30, 36),
		color = Color3.fromRGB(110, 140, 190),
	},
	{
		id = "ScienceHall",
		displayName = "Science Hall",
		position = Vector3.new(185, 0, -165),
		size = Vector3.new(50, 26, 34),
		color = Color3.fromRGB(150, 120, 190),
		terraceHeight = 8,
	},
	{
		id = "NorthDorm",
		displayName = "North Dorm",
		position = Vector3.new(10, 0, -255),
		size = Vector3.new(60, 34, 30),
		color = Color3.fromRGB(185, 105, 90),
	},
	{
		id = "Cafeteria",
		displayName = "Cafeteria",
		position = Vector3.new(245, 0, 40),
		size = Vector3.new(48, 20, 40),
		color = Color3.fromRGB(225, 165, 85),
	},
	{
		id = "Gym",
		displayName = "Gym",
		position = Vector3.new(30, 0, 235),
		size = Vector3.new(64, 28, 44),
		color = Color3.fromRGB(80, 160, 160),
	},
	{
		id = "ArtStudio",
		displayName = "Art Studio",
		position = Vector3.new(-235, 0, 75),
		size = Vector3.new(40, 22, 32),
		color = Color3.fromRGB(205, 120, 160),
	},
}

local DEPOT_POSITION = Vector3.new(0, 0, 16)
local START_PAD_POSITION = Vector3.new(0, 0, -14)

type PartSpec = {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	parent: Instance,
	material: Enum.Material?,
	shape: Enum.PartType?,
	canCollide: boolean?,
}

local function newPart(spec: PartSpec): Part
	local part = Instance.new("Part")
	part.Name = spec.name
	part.Anchored = true
	part.Size = spec.size
	part.CFrame = spec.cframe
	part.Color = spec.color
	part.Material = spec.material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if spec.shape then
		part.Shape = spec.shape
	end
	if spec.canCollide ~= nil then
		part.CanCollide = spec.canCollide
	end
	part.Parent = spec.parent
	return part
end

-- Big readable text on one face of a part.
local function addSign(part: BasePart, face: Enum.NormalId, text: string)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Sign" .. face.Name
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 25

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui

	gui.Parent = part
end

-- Point on the ground (Y = GROUND_TOP) with the same X and Z.
local function onGround(position: Vector3): Vector3
	return Vector3.new(position.X, GROUND_TOP, position.Z)
end

-- Flat strip of path lying on the ground from `from` to `to`.
local function addPath(parent: Instance, name: string, from: Vector3, to: Vector3)
	local a, b = onGround(from), onGround(to)
	local thickness = 0.1
	local middle = (a + b) / 2 + Vector3.new(0, thickness / 2, 0)
	newPart({
		name = name,
		size = Vector3.new(PATH_WIDTH, thickness, (b - a).Magnitude),
		cframe = CFrame.lookAt(middle, b + Vector3.new(0, thickness / 2, 0)),
		color = COLORS.path,
		material = Enum.Material.Concrete,
		parent = parent,
	})
end

-- Sloped slab whose top surface runs from `low` to `high`.
local function addRamp(parent: Instance, name: string, low: Vector3, high: Vector3, width: number)
	local thickness = 1
	local look = CFrame.lookAt((low + high) / 2, high)
	newPart({
		name = name,
		size = Vector3.new(width, thickness, (high - low).Magnitude),
		cframe = look * CFrame.new(0, -thickness / 2, 0),
		color = COLORS.terrace,
		material = Enum.Material.Concrete,
		parent = parent,
	})
end

local function addTree(parent: Instance, position: Vector3)
	local base = onGround(position)
	newPart({
		name = "TreeTrunk",
		size = Vector3.new(8, 1.6, 1.6),
		-- Cylinders point along X; rotate so this one stands upright.
		cframe = CFrame.new(base + Vector3.new(0, 4, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		color = COLORS.trunk,
		shape = Enum.PartType.Cylinder,
		parent = parent,
	})
	newPart({
		name = "TreeCanopy",
		size = Vector3.new(9, 9, 9),
		cframe = CFrame.new(base + Vector3.new(0, 10, 0)),
		color = COLORS.canopy,
		material = Enum.Material.Grass,
		shape = Enum.PartType.Ball,
		parent = parent,
	})
end

local function addBench(parent: Instance, position: Vector3, facing: Vector3)
	local base = CFrame.lookAt(onGround(position), onGround(facing))
	newPart({
		name = "BenchSeat",
		size = Vector3.new(6, 0.6, 2),
		cframe = base * CFrame.new(0, 1.5, 0),
		color = COLORS.bench,
		material = Enum.Material.WoodPlanks,
		parent = parent,
	})
	newPart({
		name = "BenchBase",
		size = Vector3.new(5, 1.2, 1),
		cframe = base * CFrame.new(0, 0.6, 0),
		color = COLORS.post,
		parent = parent,
	})
	newPart({
		name = "BenchBack",
		size = Vector3.new(6, 2, 0.4),
		cframe = base * CFrame.new(0, 2.6, 0.8),
		color = COLORS.bench,
		material = Enum.Material.WoodPlanks,
		parent = parent,
	})
end

-- Low hedge ring around the plaza with gaps wherever a path leaves it.
local function addHedgeRing(parent: Instance, exitAngles: { number })
	local radius = PLAZA_RADIUS + 4
	local segments = 40
	local gapHalfWidth = math.rad(11)
	for i = 0, segments - 1 do
		local angle = (i + 0.5) / segments * 2 * math.pi
		local blocked = false
		for _, exit in exitAngles do
			-- Smallest difference between two angles, between 0 and pi.
			local difference = math.abs((angle - exit + math.pi) % (2 * math.pi) - math.pi)
			if difference < gapHalfWidth then
				blocked = true
				break
			end
		end
		if not blocked then
			local position =
				Vector3.new(math.cos(angle) * radius, GROUND_TOP + 1.5, math.sin(angle) * radius)
			newPart({
				name = "Hedge",
				size = Vector3.new(2 * math.pi * radius / segments, 3, 2),
				cframe = CFrame.lookAt(position, Vector3.new(0, position.Y, 0)),
				color = COLORS.hedge,
				material = Enum.Material.Grass,
				parent = parent,
			})
		end
	end
end

local function addBuilding(scenery: Instance, destinations: Instance, building: Building): Vector3
	local terraceHeight = building.terraceHeight or 0
	local size = building.size
	local halfDepth = size.Z / 2
	-- Looking from the building toward the plaza; "forward" (-Z) is its front.
	local facing = CFrame.lookAt(onGround(building.position), Vector3.new(0, GROUND_TOP, 0))
	local function at(x: number, y: number, z: number): CFrame
		return facing * CFrame.new(x, y, z)
	end

	local folder = Instance.new("Model")
	folder.Name = building.id
	folder.Parent = scenery

	newPart({
		name = "Building",
		size = size,
		cframe = at(0, terraceHeight + size.Y / 2, 0),
		color = building.color,
		parent = folder,
	})
	newPart({
		name = "Door",
		size = Vector3.new(8, 10, 0.4),
		cframe = at(0, terraceHeight + 5, -halfDepth - 0.2),
		color = COLORS.door,
		parent = folder,
	})
	local signBoard = newPart({
		name = "SignBoard",
		size = Vector3.new(math.min(size.X - 6, 36), 5, 0.4),
		cframe = at(0, terraceHeight + size.Y - 5, -halfDepth - 0.2),
		color = COLORS.door,
		parent = folder,
	})
	addSign(signBoard, Enum.NormalId.Front, building.displayName)

	-- Where the path should end: on the ground in front of the entrance.
	local approach = at(0, 0, -halfDepth - 7).Position

	if terraceHeight > 0 then
		-- A raised terrace reached by a ramp, so this route has a climb.
		local apron = 30 -- how far the terrace reaches in front of the building
		newPart({
			name = "Terrace",
			size = Vector3.new(size.X + 30, terraceHeight, size.Z + apron + 10),
			cframe = at(0, terraceHeight / 2, -(apron - 10) / 2),
			color = COLORS.terrace,
			material = Enum.Material.Concrete,
			parent = folder,
		})
		local edge = at(0, terraceHeight, -halfDepth - apron).Position
		local rampRun = terraceHeight * 4 -- about a 14 degree slope
		local foot = at(0, 0, -halfDepth - apron - rampRun).Position
		addRamp(folder, "Ramp", foot, edge, 14)
		approach = foot
	end

	-- The mailbox is the delivery point: its box is the Destinations part.
	newPart({
		name = "MailboxPost",
		size = Vector3.new(0.6, 3, 0.6),
		cframe = at(7, terraceHeight + 1.5, -halfDepth - 7),
		color = COLORS.post,
		parent = folder,
	})
	local mailbox = newPart({
		name = building.id,
		size = Vector3.new(3, 2, 2.4),
		cframe = at(7, terraceHeight + 4, -halfDepth - 7),
		color = COLORS.mailbox,
		parent = destinations,
	})
	mailbox:SetAttribute("DisplayName", building.displayName)

	return approach
end

local MapBuilder = {}

-- Creates the greybox map under `parent` (normally Workspace) and returns it.
-- Errors if a model with the map name already exists, so it never overwrites
-- your work.
function MapBuilder.build(parent: Instance): Model
	if parent:FindFirstChild(Config.MAP_NAME) then
		error(`{parent:GetFullName()} already has a {Config.MAP_NAME}; delete or rename it first`)
	end

	local map = Instance.new("Model")
	map.Name = Config.MAP_NAME
	-- Persistent: the whole map is always sent to every player, even with
	-- instance streaming on, so the destination prompts always exist.
	map.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	local scenery = Instance.new("Folder")
	scenery.Name = "Scenery"
	scenery.Parent = map

	local destinations = Instance.new("Folder")
	destinations.Name = "Destinations"
	destinations.Parent = map

	newPart({
		name = "Ground",
		size = Vector3.new(GROUND_SIZE, 1, GROUND_SIZE),
		cframe = CFrame.new(0, GROUND_TOP - 0.5, 0),
		color = COLORS.ground,
		material = Enum.Material.Grass,
		parent = scenery,
	})
	newPart({
		name = "Plaza",
		size = Vector3.new(0.14, PLAZA_RADIUS * 2, PLAZA_RADIUS * 2),
		cframe = CFrame.new(0, GROUND_TOP + 0.07, 0) * CFrame.Angles(0, 0, math.rad(90)),
		color = COLORS.plaza,
		material = Enum.Material.Concrete,
		shape = Enum.PartType.Cylinder,
		parent = scenery,
	})

	-- Players spawn on the plaza if the place has no SpawnLocation of its own.
	if Workspace:FindFirstChildWhichIsA("SpawnLocation", true) == nil then
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "PlazaSpawn"
		spawn.Anchored = true
		spawn.Size = Vector3.new(10, 0.4, 10)
		spawn.CFrame = CFrame.new(0, GROUND_TOP + 0.34, 0)
		spawn.Color = COLORS.plaza
		spawn.Material = Enum.Material.Concrete
		spawn.Duration = 0 -- no force field
		spawn.Parent = scenery
	end

	local startPad = newPart({
		name = "StartPad",
		size = Vector3.new(10, 0.4, 10),
		cframe = CFrame.new(onGround(START_PAD_POSITION) + Vector3.new(0, 0.2, 0)),
		color = COLORS.startPad,
		material = Enum.Material.Neon,
		parent = map,
	})
	addSign(startPad, Enum.NormalId.Top, "START")

	-- The Depot counter faces north (toward the StartPad).
	local depotBase = CFrame.new(onGround(DEPOT_POSITION))
	newPart({
		name = "Depot",
		size = Vector3.new(14, 5, 4),
		cframe = depotBase * CFrame.new(0, 2.5, 0),
		color = COLORS.depot,
		parent = map,
	})
	local depotSign = newPart({
		name = "DepotSign",
		size = Vector3.new(14, 3, 0.4),
		cframe = depotBase * CFrame.new(0, 9, 0),
		color = COLORS.door,
		parent = scenery,
	})
	addSign(depotSign, Enum.NormalId.Front, "DEPOT")
	addSign(depotSign, Enum.NormalId.Back, "DEPOT")
	for _, offset in { -6.5, 6.5 } do
		newPart({
			name = "DepotPost",
			size = Vector3.new(0.5, 4, 0.5),
			cframe = depotBase * CFrame.new(offset, 6.5, 0),
			color = COLORS.post,
			parent = scenery,
		})
	end
	for i, offset in { -4, 0, 4 } do
		newPart({
			name = "StackedPackage",
			size = Vector3.new(2, 1.6, 1.6),
			cframe = depotBase * CFrame.new(offset, 5.8, 0) * CFrame.Angles(0, math.rad(i * 12), 0),
			color = COLORS.box,
			material = Enum.Material.Cardboard,
			parent = scenery,
		})
	end

	local exitAngles: { number } = {}
	for index, building in BUILDINGS do
		local approach = addBuilding(scenery, destinations, building)
		local direction = Vector3.new(approach.X, 0, approach.Z).Unit
		table.insert(exitAngles, math.atan2(direction.Z, direction.X))

		local pathStart = direction * (PLAZA_RADIUS - 0.5)
		addPath(scenery, `Path{building.id}`, pathStart, approach)

		-- Trees alongside each path, alternating sides.
		local side = Vector3.new(-direction.Z, 0, direction.X)
		local length = (onGround(approach) - pathStart).Magnitude
		for step = 1, 3 do
			local along = pathStart + direction * (length * step / 4)
			local sign = if (step + index) % 2 == 0 then 1 else -1
			addTree(scenery, along + side * (PATH_WIDTH / 2 + 5) * sign)
		end

		-- Road works block the middle of the Cafeteria path: walk around them.
		if building.id == "Cafeteria" then
			local middle = onGround(pathStart + direction * (length / 2))
			newPart({
				name = "RoadWorks",
				size = Vector3.new(18, 4, 1.5),
				cframe = CFrame.lookAt(
					middle + Vector3.new(0, 2, 0),
					middle + Vector3.new(0, 2, 0) + direction
				),
				color = COLORS.barrier,
				parent = scenery,
			})
		end
	end

	addHedgeRing(scenery, exitAngles)
	-- Benches sit between the path exits (angles in degrees, 0 = east, 90 = south).
	for _, angle in { 45, 122, 191, 345 } do
		local radians = math.rad(angle)
		local position = Vector3.new(math.cos(radians), 0, math.sin(radians)) * (PLAZA_RADIUS - 6)
		addBench(scenery, position, Vector3.zero)
	end

	map.Parent = parent
	return map
end

return MapBuilder
