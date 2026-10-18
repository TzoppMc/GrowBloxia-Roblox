--!nocheck
-- Shared balancing, world geometry, and item data for GrowBloxia's 2D side-view
-- farming sandbox. This module is required by both server and client.

local Config = {}

Config.World = {
	GridWidth = 72,
	GridHeight = 28,
	TileSize = 4,
	TileDepth = 0.8,
	BaseY = 0,
	GroundSurfaceY = 7,
	StarterFarmStartX = 17,
	StarterFarmEndX = 21,
	SpawnCellX = 12,
}

Config.Camera = {
	PlaneZ = 0,
	Distance = 96,
	VerticalOffset = 4,
	TargetHeight = 6,
	FieldOfView = 24,
}

Config.Interaction = {
	MaxDistance = 23,
	ActionCooldown = 0.12,
}

Config.Farming = {
	GrowthUpdateSeconds = 1,
	WaterDuration = 75,
	WaterGrowthMultiplier = 1.65,
}

Config.TileTypes = {
	Air = {
		displayName = "Udara",
		solid = false,
		color = Color3.fromRGB(0, 0, 0),
		material = Enum.Material.SmoothPlastic,
	},
	Grass = {
		displayName = "Blok Rumput",
		solid = true,
		dropItem = "grass_block",
		color = Color3.fromRGB(86, 176, 78),
		material = Enum.Material.SmoothPlastic,
	},
	Dirt = {
		displayName = "Blok Tanah",
		solid = true,
		dropItem = "dirt_block",
		color = Color3.fromRGB(137, 88, 52),
		material = Enum.Material.SmoothPlastic,
	},
	Stone = {
		displayName = "Blok Batu",
		solid = true,
		dropItem = "stone_block",
		color = Color3.fromRGB(111, 119, 131),
		material = Enum.Material.SmoothPlastic,
	},
	Farmland = {
		displayName = "Tanah Kebun",
		solid = true,
		color = Color3.fromRGB(121, 74, 45),
		material = Enum.Material.SmoothPlastic,
	},
}

Config.Items = {
	hoe = {
		displayName = "Cangkul",
		shortName = "CANGKUL",
		kind = "tool",
		color = Color3.fromRGB(207, 182, 123),
		description = "Ubah blok rumput atau tanah menjadi tanah kebun.",
	},
	turnip_seed = {
		displayName = "Benih Lobak",
		shortName = "BENIH\nLOBAK",
		kind = "seed",
		color = Color3.fromRGB(237, 239, 218),
		description = "Tanam pada tanah kebun untuk menumbuhkan lobak.",
	},
	carrot_seed = {
		displayName = "Benih Wortel",
		shortName = "BENIH\nWORTEL",
		kind = "seed",
		color = Color3.fromRGB(251, 160, 72),
		description = "Tanam pada tanah kebun untuk menumbuhkan wortel.",
	},
	water_can = {
		displayName = "Penyiram",
		shortName = "SIRAM",
		kind = "tool",
		color = Color3.fromRGB(85, 169, 223),
		description = "Mempercepat tanaman yang belum matang.",
	},
	dirt_block = {
		displayName = "Blok Tanah",
		shortName = "BLOK\nTANAH",
		kind = "block",
		placeTile = "Dirt",
		color = Color3.fromRGB(142, 91, 55),
		description = "Letakkan pada ruang kosong yang bersebelahan dengan blok.",
	},
	grass_block = {
		displayName = "Blok Rumput",
		shortName = "BLOK\nRUMPUT",
		kind = "block",
		placeTile = "Grass",
		color = Color3.fromRGB(91, 173, 77),
		description = "Blok rumput hasil bongkar.",
	},
	stone_block = {
		displayName = "Blok Batu",
		shortName = "BLOK\nBATU",
		kind = "block",
		placeTile = "Stone",
		color = Color3.fromRGB(119, 128, 143),
		description = "Blok batu hasil bongkar.",
	},
	turnip = {
		displayName = "Lobak",
		shortName = "LOBAK",
		kind = "harvest",
		color = Color3.fromRGB(240, 243, 221),
		description = "Hasil panen lobak.",
	},
	carrot = {
		displayName = "Wortel",
		shortName = "WORTEL",
		kind = "harvest",
		color = Color3.fromRGB(255, 144, 55),
		description = "Hasil panen wortel.",
	},
}

Config.Crops = {
	turnip = {
		displayName = "Lobak",
		seedItem = "turnip_seed",
		harvestItem = "turnip",
		growSeconds = 45,
		stageCount = 3,
		yieldMin = 1,
		yieldMax = 3,
		seedReturnChance = 0.38,
		stemColor = Color3.fromRGB(69, 145, 68),
		leafColor = Color3.fromRGB(110, 194, 79),
		fruitColor = Color3.fromRGB(239, 239, 205),
	},
	carrot = {
		displayName = "Wortel",
		seedItem = "carrot_seed",
		harvestItem = "carrot",
		growSeconds = 75,
		stageCount = 3,
		yieldMin = 2,
		yieldMax = 4,
		seedReturnChance = 0.30,
		stemColor = Color3.fromRGB(67, 139, 61),
		leafColor = Color3.fromRGB(99, 190, 79),
		fruitColor = Color3.fromRGB(249, 141, 54),
	},
}

Config.DefaultHotbar = {
	"hoe",
	"turnip_seed",
	"carrot_seed",
	"water_can",
	"dirt_block",
	"grass_block",
	"stone_block",
}

Config.StartingInventory = {
	hoe = 1,
	turnip_seed = 10,
	carrot_seed = 6,
	water_can = 1,
	dirt_block = 8,
}

function Config.cellKey(x, y)
	return string.format("%d:%d", x, y)
end

function Config.cellToWorld(x, y, zOffset)
	local xOffset = (x - (Config.World.GridWidth + 1) / 2) * Config.World.TileSize
	local yOffset = Config.World.BaseY + (y - 0.5) * Config.World.TileSize
	return Vector3.new(xOffset, yOffset, zOffset or Config.Camera.PlaneZ)
end

function Config.getCropForSeed(seedItem)
	for cropId, crop in pairs(Config.Crops) do
		if crop.seedItem == seedItem then
			return cropId, crop
		end
	end

	return nil, nil
end

return Config
