--!nocheck
-- Server-authoritative 2D tile farming and block interaction service. Clients
-- only request an action; range checks, tile mutation, growth, and item grants
-- remain on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local FarmService = {}
FarmService.World = nil
FarmService.Inventory = nil
FarmService.NotifyRemote = nil
FarmService._cooldowns = {}

local function isInteger(value)
	return typeof(value) == "number" and value == value and value % 1 == 0
end

function FarmService:Init(worldService, inventoryService, notifyRemote)
	self.World = worldService
	self.Inventory = inventoryService
	self.NotifyRemote = notifyRemote

	Players.PlayerRemoving:Connect(function(player)
		self._cooldowns[player] = nil
	end)

	task.spawn(function()
		while true do
			self:UpdateGrowth()
			task.wait(Config.Farming.GrowthUpdateSeconds)
		end
	end)
end

function FarmService:Notify(player, text, kind)
	if self.NotifyRemote and player.Parent then
		self.NotifyRemote:FireClient(player, {
			text = text,
			kind = kind or "info",
		})
	end
end

function FarmService:_advancePlant(cell, now)
	local plant = cell.plant
	if not plant then
		return
	end

	local lastUpdate = plant.lastGrowthAt or now
	if now <= lastUpdate then
		return
	end

	local elapsed = now - lastUpdate
	local wateredUntil = plant.wateredUntil or 0
	local boostedSeconds = math.max(0, math.min(now, wateredUntil) - lastUpdate)
	boostedSeconds = math.min(boostedSeconds, elapsed)
	local drySeconds = elapsed - boostedSeconds

	plant.growth = (plant.growth or 0)
		+ drySeconds
		+ boostedSeconds * Config.Farming.WaterGrowthMultiplier
	plant.lastGrowthAt = now
end

function FarmService:_getStage(crop, growth)
	local progress = math.clamp(growth / crop.growSeconds, 0, 1)
	return math.clamp(math.floor(progress * crop.stageCount) + 1, 1, crop.stageCount)
end

function FarmService:_refreshPlant(cell, now)
	local plant = cell.plant
	if not plant then
		return
	end

	local crop = Config.Crops[plant.cropId]
	if not crop then
		return
	end

	self:_advancePlant(cell, now)
	plant.stage = self:_getStage(crop, plant.growth)
	self.World:RefreshPlantVisual(cell, false)
end

function FarmService:UpdateGrowth()
	if not self.World then
		return
	end

	local now = os.time()
	for _, cell in ipairs(self.World:GetCells()) do
		if cell.plant then
			self:_refreshPlant(cell, now)
		end
	end
end

function FarmService:_isPlayerNearCell(player, cell)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end

	local targetPosition = self.World:GetCellWorldPosition(cell)
	return (root.Position - targetPosition).Magnitude <= Config.Interaction.MaxDistance
end

function FarmService:_plantSeed(player, cell, itemId, cropId, crop)
	if cell.tileType ~= "Farmland" then
		self:Notify(player, "Benih hanya bisa ditanam di tanah kebun.", "warning")
		return
	end

	if cell.plant then
		self:Notify(player, "Petak ini sudah terisi tanaman.", "warning")
		return
	end

	if not self.Inventory:RemoveItem(player, itemId, 1) then
		self:Notify(player, "Benih itu tidak ada di inventori.", "warning")
		return
	end

	local now = os.time()
	self.World:SetPlant(cell, {
		cropId = cropId,
		growth = 0,
		stage = 1,
		lastGrowthAt = now,
		wateredUntil = 0,
	})
	self:Notify(player, string.format("%s ditanam. Siram agar lebih cepat tumbuh!", crop.displayName), "success")
end

function FarmService:_waterPlant(player, cell, now)
	local plant = cell.plant
	if not plant then
		self:Notify(player, "Arahkan penyiram ke tanaman.", "warning")
		return
	end

	local crop = Config.Crops[plant.cropId]
	if not crop then
		return
	end

	self:_refreshPlant(cell, now)
	if plant.growth >= crop.growSeconds then
		self:Notify(player, "Tanaman ini sudah siap dipanen.", "info")
		return
	end

	local currentEnd = math.max(now, plant.wateredUntil or 0)
	plant.wateredUntil = math.min(
		currentEnd + Config.Farming.WaterDuration,
		now + Config.Farming.WaterDuration * 2
	)
	self.World:RefreshPlantVisual(cell, true)
	self:Notify(player, "Disiram! Pertumbuhan tanaman dipercepat.", "success")
end

function FarmService:_harvest(player, cell, crop)
	local amount = math.random(crop.yieldMin, crop.yieldMax)
	self.World:SetPlant(cell, nil)
	self.Inventory:AddItem(player, crop.harvestItem, amount)

	local message = string.format("Panen berhasil: +%d %s", amount, crop.displayName)
	if math.random() <= crop.seedReturnChance then
		self.Inventory:AddItem(player, crop.seedItem, 1)
		message = message .. " dan +1 benih"
	end

	self:Notify(player, message, "success")
end

function FarmService:_useOnPlant(player, cell, itemId, now)
	local plant = cell.plant
	local crop = plant and Config.Crops[plant.cropId]
	if not crop then
		return
	end

	self:_refreshPlant(cell, now)
	if plant.growth >= crop.growSeconds then
		self:_harvest(player, cell, crop)
		return
	end

	if itemId == "water_can" then
		self:_waterPlant(player, cell, now)
	else
		self:Notify(player, "Belum matang. Gunakan penyiram atau tunggu sebentar.", "info")
	end
end

function FarmService:_placeBlock(player, cell, itemId, item)
	if cell.tileType ~= "Air" then
		self:Notify(player, "Blok hanya dapat diletakkan di ruang kosong.", "warning")
		return
	end

	if not self.World:HasSolidNeighbor(cell) then
		self:Notify(player, "Blok harus tersambung ke blok lain.", "warning")
		return
	end

	if not self.Inventory:RemoveItem(player, itemId, 1) then
		self:Notify(player, "Blok itu tidak ada di inventori.", "warning")
		return
	end

	self.World:SetTileType(cell, item.placeTile)
	self:Notify(player, string.format("%s diletakkan.", item.displayName), "success")
end

function FarmService:_useOnTile(player, cell, itemId)
	local item = Config.Items[itemId]
	if not item then
		return
	end

	if item.kind == "block" and item.placeTile then
		self:_placeBlock(player, cell, itemId, item)
		return
	end

	if itemId == "hoe" then
		if not self.Inventory:HasItem(player, itemId, 1) then
			return
		end
		if cell.tileType == "Grass" or cell.tileType == "Dirt" then
			self.World:SetTileType(cell, "Farmland")
			self:Notify(player, "Blok diolah menjadi tanah kebun.", "success")
		elseif cell.tileType == "Farmland" then
			self:Notify(player, "Petak ini sudah siap ditanami.", "info")
		else
			self:Notify(player, "Cangkul hanya dapat digunakan pada rumput atau tanah.", "warning")
		end
		return
	end

	if itemId == "water_can" then
		self:Notify(player, "Arahkan penyiram ke tanaman yang belum matang.", "warning")
		return
	end

	local cropId, crop = Config.getCropForSeed(itemId)
	if cropId then
		self:_plantSeed(player, cell, itemId, cropId, crop)
		return
	end

	self:Notify(player, "Item ini tidak dapat digunakan pada tile tersebut.", "warning")
end

function FarmService:_breakCell(player, cell, now)
	if cell.plant then
		local plant = cell.plant
		local crop = Config.Crops[plant.cropId]
		if not crop then
			return
		end

		self:_refreshPlant(cell, now)
		if plant.growth >= crop.growSeconds then
			self:_harvest(player, cell, crop)
		else
			self.World:SetPlant(cell, nil)
			self.Inventory:AddItem(player, crop.seedItem, 1)
			self:Notify(player, "Tanaman dicabut. Satu benih dikembalikan.", "info")
		end
		return
	end

	if cell.tileType == "Air" then
		self:Notify(player, "Tidak ada blok di sini.", "info")
		return
	end

	if cell.tileType == "Farmland" then
		self.World:SetTileType(cell, "Dirt")
		self:Notify(player, "Tanah kebun dikembalikan menjadi blok tanah.", "info")
		return
	end

	local tileData = Config.TileTypes[cell.tileType]
	if not tileData or not tileData.dropItem then
		return
	end

	self.World:SetTileType(cell, "Air")
	self.Inventory:AddItem(player, tileData.dropItem, 1)
	self:Notify(player, string.format("Blok dibongkar: +1 %s", Config.Items[tileData.dropItem].displayName), "success")
end

function FarmService:HandleAction(player, payload)
	if type(payload) ~= "table" then
		return
	end

	local action = payload.action
	local itemId = payload.itemId
	local x = payload.x
	local y = payload.y

	if (action ~= "use" and action ~= "break") or not isInteger(x) or not isInteger(y) then
		return
	end

	if action == "use" and (type(itemId) ~= "string" or not Config.Items[itemId]) then
		return
	end

	local cell = self.World:GetCell(x, y)
	if not cell or not self:_isPlayerNearCell(player, cell) then
		return
	end

	local time = os.clock()
	if time - (self._cooldowns[player] or 0) < Config.Interaction.ActionCooldown then
		return
	end
	self._cooldowns[player] = time

	local now = os.time()
	if action == "break" then
		self:_breakCell(player, cell, now)
	elseif cell.plant then
		self:_useOnPlant(player, cell, itemId, now)
	else
		self:_useOnTile(player, cell, itemId)
	end
end

return FarmService
