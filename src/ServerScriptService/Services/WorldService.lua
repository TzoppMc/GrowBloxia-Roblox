--!nocheck
-- Server-owned 2D side-view tile world. Blocks sit on the X/Y plane while a
-- scriptable client camera looks straight down the Z axis.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local WorldService = {}
WorldService.Cells = {}
WorldService.CellList = {}
WorldService.WorldModel = nil
WorldService.TilesFolder = nil
WorldService.PlantsFolder = nil
WorldService.PropsFolder = nil
WorldService.Spawn = nil

local function makePart(name, size, cframe, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = true
	part.CanTouch = false
	part.CanQuery = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function tagCell(instance, cell, targetKind)
	instance:SetAttribute("CellX", cell.x)
	instance:SetAttribute("CellY", cell.y)
	instance:SetAttribute("TargetKind", targetKind)
end

function WorldService:_destroyTileVisual(cell)
	if cell.tilePart then
		cell.tilePart:Destroy()
	end
	cell.tilePart = nil
end

function WorldService:_applyTileAppearance(cell)
	local tileData = Config.TileTypes[cell.tileType]
	if not tileData then
		return
	end

	if cell.tileType == "Air" then
		self:_destroyTileVisual(cell)
		return
	end

	if not cell.tilePart then
		local position = Config.cellToWorld(cell.x, cell.y, Config.Camera.PlaneZ)
		local part = makePart(
			string.format("Tile_%d_%d", cell.x, cell.y),
			Vector3.new(Config.World.TileSize - 0.06, Config.World.TileSize - 0.06, Config.World.TileDepth),
			CFrame.new(position),
			tileData.color,
			tileData.material,
			self.TilesFolder
		)
		tagCell(part, cell, "Tile")
		cell.tilePart = part
	end

	cell.tilePart.Color = tileData.color
	cell.tilePart.Material = tileData.material
	cell.tilePart.CanCollide = tileData.solid == true
	cell.tilePart:SetAttribute("TileType", cell.tileType)
	cell.tilePart:SetAttribute("HasPlant", cell.plant ~= nil)
end

function WorldService:_createPlantPart(cell, model, name, size, position, color, shape)
	local part = makePart(name, size, CFrame.new(position), color, Enum.Material.SmoothPlastic, model)
	part.CanCollide = false
	part.CanQuery = true
	part.CastShadow = false
	if shape then
		part.Shape = shape
	end

	tagCell(part, cell, "Plant")
	return part
end

function WorldService:_destroyPlantVisual(cell)
	if cell.plantModel then
		cell.plantModel:Destroy()
	end
	cell.plantModel = nil
	cell.plantVisualSignature = nil
end

function WorldService:RefreshPlantVisual(cell, force)
	local plant = cell.plant
	if not plant then
		self:_destroyPlantVisual(cell)
		self:_applyTileAppearance(cell)
		return
	end

	local crop = Config.Crops[plant.cropId]
	if not crop then
		warn(string.format("[GrowBloxia] Unknown crop '%s'.", tostring(plant.cropId)))
		return
	end

	local stage = plant.stage or 1
	local ready = plant.growth >= crop.growSeconds
	local watered = (plant.wateredUntil or 0) > os.time()
	local signature = string.format("%s:%d:%s:%s", plant.cropId, stage, tostring(ready), tostring(watered))

	if not force and cell.plantModel and cell.plantVisualSignature == signature then
		return
	end

	self:_destroyPlantVisual(cell)

	local model = Instance.new("Model")
	model.Name = string.format("%s_%d_%d", crop.displayName, cell.x, cell.y)
	tagCell(model, cell, "Plant")
	model:SetAttribute("CropId", plant.cropId)
	model:SetAttribute("CropName", crop.displayName)
	model:SetAttribute("Ready", ready)
	model:SetAttribute("Watered", watered)
	model.Parent = self.PlantsFolder

	local tileCenter = Config.cellToWorld(cell.x, cell.y, Config.Camera.PlaneZ)
	local groundY = tileCenter.Y + Config.World.TileSize / 2
	local frontZ = Config.Camera.PlaneZ - Config.World.TileDepth / 2 - 0.35
	local stemHeight = 0.9 + stage * 0.52
	self:_createPlantPart(
		cell,
		model,
		"Stem",
		Vector3.new(0.48, stemHeight, 0.36),
		Vector3.new(tileCenter.X, groundY + stemHeight / 2, frontZ),
		crop.stemColor
	)

	if stage >= 2 then
		local leafY = groundY + stemHeight * 0.68
		self:_createPlantPart(
			cell,
			model,
			"LeafLeft",
			Vector3.new(1.35, 0.35, 0.34),
			Vector3.new(tileCenter.X - 0.58, leafY, frontZ - 0.03),
			crop.leafColor
		)
		self:_createPlantPart(
			cell,
			model,
			"LeafRight",
			Vector3.new(1.35, 0.35, 0.34),
			Vector3.new(tileCenter.X + 0.58, leafY + 0.2, frontZ - 0.03),
			crop.leafColor
		)
	end

	if stage >= 3 then
		self:_createPlantPart(
			cell,
			model,
			"TopLeaf",
			Vector3.new(0.65, 0.35, 1.15),
			Vector3.new(tileCenter.X, groundY + stemHeight + 0.1, frontZ),
			crop.leafColor
		)
	end

	if ready then
		self:_createPlantPart(
			cell,
			model,
			"Harvest",
			Vector3.new(1.18, 1.18, 0.72),
			Vector3.new(tileCenter.X, groundY + 0.57, frontZ - 0.06),
			crop.fruitColor,
			Enum.PartType.Ball
		)
	end

	if watered and not ready then
		local waterMarker = self:_createPlantPart(
			cell,
			model,
			"WateredMarker",
			Vector3.new(1.8, 0.12, 0.12),
			Vector3.new(tileCenter.X, groundY + 0.1, frontZ - 0.08),
			Color3.fromRGB(77, 190, 245)
		)
		waterMarker.Transparency = 0.20
		waterMarker.CanQuery = false
	end

	cell.plantModel = model
	cell.plantVisualSignature = signature
	self:_applyTileAppearance(cell)
end

function WorldService:SetTileType(cell, tileType)
	if not Config.TileTypes[tileType] then
		return false
	end

	if tileType == "Air" and cell.plant then
		self:SetPlant(cell, nil)
	end

	cell.tileType = tileType
	self:_applyTileAppearance(cell)
	return true
end

function WorldService:SetPlant(cell, plant)
	self:_destroyPlantVisual(cell)
	cell.plant = plant
	self:_applyTileAppearance(cell)

	if plant then
		self:RefreshPlantVisual(cell, true)
	end
end

function WorldService:GetCell(x, y)
	return self.Cells[Config.cellKey(x, y)]
end

function WorldService:GetCells()
	return self.CellList
end

function WorldService:GetCellWorldPosition(cell)
	return Config.cellToWorld(cell.x, cell.y, Config.Camera.PlaneZ)
end

function WorldService:HasSolidNeighbor(cell)
	for _, offset in ipairs({
		{ 1, 0 },
		{ -1, 0 },
		{ 0, 1 },
		{ 0, -1 },
	}) do
		local neighbor = self:GetCell(cell.x + offset[1], cell.y + offset[2])
		local tileData = neighbor and Config.TileTypes[neighbor.tileType]
		if tileData and tileData.solid then
			return true
		end
	end
	return false
end

function WorldService:GetSpawnPosition()
	if self.Spawn then
		return self.Spawn.Position + Vector3.new(0, 4, 0)
	end

	local fallback = Config.cellToWorld(Config.World.SpawnCellX, Config.World.GroundSurfaceY + 1, Config.Camera.PlaneZ)
	return fallback + Vector3.new(0, 4, 0)
end

function WorldService:_createBackdrop()
	local width = Config.World.GridWidth * Config.World.TileSize + 48
	local height = Config.World.GridHeight * Config.World.TileSize + 32
	local center = Config.cellToWorld((Config.World.GridWidth + 1) / 2, (Config.World.GridHeight + 1) / 2, Config.Camera.PlaneZ + 3)
	local backdrop = makePart(
		"SkyBackdrop",
		Vector3.new(width, height, 0.1),
		CFrame.new(center),
		Color3.fromRGB(112, 190, 232),
		Enum.Material.SmoothPlastic,
		self.PropsFolder
	)
	backdrop.CanCollide = false
	backdrop.CanQuery = false
	backdrop.CastShadow = false

	for index, xOffset in ipairs({ -80, -18, 54, 112 }) do
		local cloud = makePart(
			"Cloud" .. index,
			Vector3.new(11, 2.2, 0.12),
			CFrame.new(center + Vector3.new(xOffset, 28 - (index % 2) * 7, -0.18)),
			Color3.fromRGB(240, 250, 255),
			Enum.Material.SmoothPlastic,
			self.PropsFolder
		)
		cloud.CanCollide = false
		cloud.CanQuery = false
		cloud.CastShadow = false
	end
end

function WorldService:_createSpawn()
	local surface = Config.World.GroundSurfaceY
	local base = Config.cellToWorld(Config.World.SpawnCellX, surface, Config.Camera.PlaneZ - 0.15)
	local topY = base.Y + Config.World.TileSize / 2

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "GardenSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Size = Vector3.new(Config.World.TileSize * 1.65, 0.45, Config.World.TileDepth * 2)
	spawn.CFrame = CFrame.new(base.X, topY + 0.23, Config.Camera.PlaneZ)
	spawn.Color = Color3.fromRGB(83, 181, 222)
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.14
	spawn.Parent = self.WorldModel
	self.Spawn = spawn

	local signAnchor = makePart(
		"WelcomeSign",
		Vector3.new(4.6, 2.2, 0.16),
		CFrame.new(base.X, topY + 4.0, Config.Camera.PlaneZ - 0.65),
		Color3.fromRGB(53, 71, 93),
		Enum.Material.Wood,
		self.PropsFolder
	)
	signAnchor.CanCollide = false
	signAnchor.CanQuery = false

	local surface = Instance.new("SurfaceGui")
	surface.Name = "Text"
	surface.Face = Enum.NormalId.Front
	surface.CanvasSize = Vector2.new(460, 220)
	surface.Parent = signAnchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "KEBUN\nBLOXIA"
	label.TextColor3 = Color3.fromRGB(255, 237, 166)
	label.TextStrokeTransparency = 0.55
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = surface
end

function WorldService:_getInitialTileType(x, y)
	local surfaceY = Config.World.GroundSurfaceY
	if y > surfaceY then
		return "Air"
	end

	if y == surfaceY then
		if x >= Config.World.StarterFarmStartX and x <= Config.World.StarterFarmEndX then
			return "Farmland"
		end
		return "Grass"
	end

	if y >= surfaceY - 2 then
		return "Dirt"
	end

	return "Stone"
end

function WorldService:Init()
	local oldWorld = Workspace:FindFirstChild("GrowBloxiaWorld")
	if oldWorld then
		oldWorld:Destroy()
	end

	self.Cells = {}
	self.CellList = {}

	local world = Instance.new("Model")
	world.Name = "GrowBloxiaWorld"
	world.Parent = Workspace
	self.WorldModel = world

	local props = Instance.new("Folder")
	props.Name = "Props"
	props.Parent = world
	self.PropsFolder = props
	self:_createBackdrop()

	local tiles = Instance.new("Folder")
	tiles.Name = "Tiles"
	tiles.Parent = world
	self.TilesFolder = tiles

	local plants = Instance.new("Folder")
	plants.Name = "Plants"
	plants.Parent = world
	self.PlantsFolder = plants

	for x = 1, Config.World.GridWidth do
		for y = 1, Config.World.GridHeight do
			local cell = {
				x = x,
				y = y,
				tileType = self:_getInitialTileType(x, y),
				plant = nil,
				tilePart = nil,
				plantModel = nil,
				plantVisualSignature = nil,
			}
			self.Cells[Config.cellKey(x, y)] = cell
			table.insert(self.CellList, cell)
			self:_applyTileAppearance(cell)
		end
	end

	self:_createSpawn()
	Workspace.FallenPartsDestroyHeight = -60
end

return WorldService
