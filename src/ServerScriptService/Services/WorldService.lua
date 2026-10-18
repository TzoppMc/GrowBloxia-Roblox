--!nocheck
-- Creates and owns the server-side grid. All parts are generated at runtime so
-- the project is immediately playable before final Roblox assets are imported.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local WorldService = {}
WorldService.Cells = {}
WorldService.CellList = {}
WorldService.WorldModel = nil
WorldService.TilesFolder = nil
WorldService.PlantsFolder = nil
WorldService.Spawn = nil

local function makePart(name, size, cframe, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = true
	part.CanTouch = false
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
	instance:SetAttribute("CellZ", cell.z)
	instance:SetAttribute("TargetKind", targetKind)
end

function WorldService:_createTile(cell)
	local position = Config.cellToWorld(cell.x, cell.z, 0)
	local tile = makePart(
		string.format("Tile_%d_%d", cell.x, cell.z),
		Vector3.new(Config.World.TileSize - 0.12, Config.World.TileHeight, Config.World.TileSize - 0.12),
		CFrame.new(position),
		Color3.new(1, 1, 1),
		Enum.Material.Grass,
		self.TilesFolder
	)

	tagCell(tile, cell, "Tile")
	cell.tilePart = tile
	self:_applyTileAppearance(cell)
end

function WorldService:_applyTileAppearance(cell)
	local tileData = Config.TileTypes[cell.tileType]
	if not tileData or not cell.tilePart then
		return
	end

	cell.tilePart.Color = tileData.color
	cell.tilePart.Material = tileData.material
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
	model.Name = string.format("%s_%d_%d", crop.displayName, cell.x, cell.z)
	tagCell(model, cell, "Plant")
	model:SetAttribute("CropId", plant.cropId)
	model:SetAttribute("CropName", crop.displayName)
	model:SetAttribute("Ready", ready)
	model:SetAttribute("Watered", watered)
	model.Parent = self.PlantsFolder

	local base = Config.cellToWorld(cell.x, cell.z, Config.World.TileHeight / 2)
	local stemHeight = 0.85 + stage * 0.45
	self:_createPlantPart(
		cell,
		model,
		"Stem",
		Vector3.new(0.48, stemHeight, 0.48),
		base + Vector3.new(0, stemHeight / 2, 0),
		crop.stemColor
	)

	if stage >= 2 then
		local leafY = stemHeight * 0.68
		self:_createPlantPart(
			cell,
			model,
			"LeafLeft",
			Vector3.new(1.35, 0.35, 0.7),
			base + Vector3.new(-0.58, leafY, 0),
			crop.leafColor
		)
		self:_createPlantPart(
			cell,
			model,
			"LeafRight",
			Vector3.new(1.35, 0.35, 0.7),
			base + Vector3.new(0.58, leafY + 0.2, 0),
			crop.leafColor
		)
	end

	if stage >= 3 then
		self:_createPlantPart(
			cell,
			model,
			"TopLeaf",
			Vector3.new(0.65, 0.35, 1.35),
			base + Vector3.new(0, stemHeight + 0.1, 0),
			crop.leafColor
		)
	end

	if ready then
		local fruitY = 0.52
		self:_createPlantPart(
			cell,
			model,
			"Harvest",
			Vector3.new(1.18, 1.18, 1.18),
			base + Vector3.new(0, fruitY, 0),
			crop.fruitColor,
			Enum.PartType.Ball
		)
	end

	if watered and not ready then
		local waterMarker = self:_createPlantPart(
			cell,
			model,
			"WateredMarker",
			Vector3.new(1.8, 0.12, 1.8),
			base + Vector3.new(0, 0.08, 0),
			Color3.fromRGB(77, 190, 245)
		)
		waterMarker.Transparency = 0.25
	end

	cell.plantModel = model
	cell.plantVisualSignature = signature
	self:_applyTileAppearance(cell)
end

function WorldService:SetTileType(cell, tileType)
	if not Config.TileTypes[tileType] then
		return false
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

function WorldService:GetCell(x, z)
	return self.Cells[Config.cellKey(x, z)]
end

function WorldService:GetCells()
	return self.CellList
end

function WorldService:GetCellWorldPosition(cell)
	return Config.cellToWorld(cell.x, cell.z, Config.World.TileHeight / 2)
end

function WorldService:GetSpawnPosition()
	if self.Spawn then
		return self.Spawn.Position + Vector3.new(0, 4, 0)
	end

	return Vector3.new(0, 8, 0)
end

function WorldService:_createSpawn()
	local spawnPosition = Config.cellToWorld(2, 2, Config.World.TileHeight / 2 + 0.3)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "GardenSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Size = Vector3.new(Config.World.TileSize * 1.35, 0.6, Config.World.TileSize * 1.35)
	spawn.CFrame = CFrame.new(spawnPosition)
	spawn.Color = Color3.fromRGB(83, 181, 222)
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.08
	spawn.Parent = self.WorldModel
	self.Spawn = spawn

	local signBase = makePart(
		"WelcomeSign",
		Vector3.new(4.2, 2.4, 0.3),
		CFrame.new(spawnPosition + Vector3.new(0, 2.15, -2.1)),
		Color3.fromRGB(53, 71, 93),
		Enum.Material.Wood,
		self.WorldModel
	)
	signBase.CanCollide = false

	local surface = Instance.new("SurfaceGui")
	surface.Name = "Text"
	surface.Face = Enum.NormalId.Front
	surface.CanvasSize = Vector2.new(420, 240)
	surface.Parent = signBase

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

	local tiles = Instance.new("Folder")
	tiles.Name = "Tiles"
	tiles.Parent = world
	self.TilesFolder = tiles

	local plants = Instance.new("Folder")
	plants.Name = "Plants"
	plants.Parent = world
	self.PlantsFolder = plants

	local centerX = (Config.World.GridWidth + 1) / 2
	local centerZ = (Config.World.GridDepth + 1) / 2

	for x = 1, Config.World.GridWidth do
		for z = 1, Config.World.GridDepth do
			local insideStarterFarm = math.abs(x - centerX) <= Config.World.StarterFarmHalfWidth
				and math.abs(z - centerZ) <= Config.World.StarterFarmHalfDepth
			local cell = {
				x = x,
				z = z,
				tileType = insideStarterFarm and "Farmland" or "Grass",
				plant = nil,
				tilePart = nil,
				plantModel = nil,
				plantVisualSignature = nil,
			}
			self.Cells[Config.cellKey(x, z)] = cell
			table.insert(self.CellList, cell)
			self:_createTile(cell)
		end
	end

	self:_createSpawn()
	Workspace.FallenPartsDestroyHeight = -80
end

return WorldService
