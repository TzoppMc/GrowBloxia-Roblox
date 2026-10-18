--!nocheck
-- Shared balancing and presentation data for GrowBloxia.
-- Keep asset IDs in AssetManifest.lua; this file is deliberately usable by both
-- server and client so gameplay rules stay consistent.

local Config = {}

Config.World = {
	GridWidth = 18,
	GridDepth = 14,
	TileSize = 6,
	TileHeight = 1,
	OriginY = 0,
	StarterFarmHalfWidth = 2,
	StarterFarmHalfDepth = 1,
}

Config.Interaction = {
	MaxDistance = 28,
	ActionCooldown = 0.12,
}

Config.Farming = {
	GrowthUpdateSeconds = 1,
	WaterDuration = 75,
	WaterGrowthMultiplier = 1.65,
}

Config.TileTypes = {
	Grass = {
		displayName = "Rumput",
		color = Color3.fromRGB(91, 173, 77),
		material = Enum.Material.Grass,
	},
	Farmland = {
		displayName = "Tanah Kebun",
		color = Color3.fromRGB(125, 79, 48),
		material = Enum.Material.Ground,
	},
}

Config.Items = {
	hoe = {
		displayName = "Cangkul",
		shortName = "CANGKUL",
		kind = "tool",
		color = Color3.fromRGB(207, 182, 123),
		description = "Ubah rumput menjadi tanah kebun.",
	},
	turnip_seed = {
		displayName = "Benih Lobak",
		shortName = "BENIH\nLOBAK",
		kind = "seed",
		color = Color3.fromRGB(237, 239, 218),
		description = "Tumbuh cepat dan cocok untuk panen pertama.",
	},
	carrot_seed = {
		displayName = "Benih Wortel",
		shortName = "BENIH\nWORTEL",
		kind = "seed",
		color = Color3.fromRGB(251, 160, 72),
		description = "Butuh waktu lebih lama, hasil panen lebih banyak.",
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
		color = Color3.fromRGB(142, 91, 55),
		description = "Letakkan di rumput untuk membuat petak kebun.",
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
}

Config.StartingInventory = {
	hoe = 1,
	turnip_seed = 10,
	carrot_seed = 6,
	water_can = 1,
	dirt_block = 8,
}

function Config.cellKey(x, z)
	return string.format("%d:%d", x, z)
end

function Config.cellToWorld(x, z, yOffset)
	local xOffset = (x - (Config.World.GridWidth + 1) / 2) * Config.World.TileSize
	local zOffset = (z - (Config.World.GridDepth + 1) / 2) * Config.World.TileSize
	return Vector3.new(xOffset, Config.World.OriginY + (yOffset or 0), zOffset)
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
