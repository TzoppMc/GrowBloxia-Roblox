--!nocheck
-- Server-authoritative session inventory. Persistence is intentionally separate
-- from this MVP so the farming loop can be tested in Studio without API access.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local InventoryService = {}
InventoryService._profiles = {}
InventoryService._syncRemote = nil

local function copyDictionary(source)
	local result = {}
	for key, value in pairs(source) do
		result[key] = value
	end
	return result
end

local function copyArray(source)
	local result = {}
	for index, value in ipairs(source) do
		result[index] = value
	end
	return result
end

function InventoryService:_createProfile(player)
	local profile = {
		items = copyDictionary(Config.StartingInventory),
		hotbar = copyArray(Config.DefaultHotbar),
	}

	self._profiles[player] = profile
	return profile
end

function InventoryService:_getProfile(player)
	return self._profiles[player] or self:_createProfile(player)
end

function InventoryService:Init(syncRemote)
	self._syncRemote = syncRemote

	local function onPlayerAdded(player)
		self:_getProfile(player)
		-- The client also explicitly requests a sync after its LocalScript starts.
		task.defer(function()
			if player.Parent then
				self:Sync(player)
			end
		end)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		self._profiles[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

function InventoryService:GetCount(player, itemId)
	local profile = self:_getProfile(player)
	return profile.items[itemId] or 0
end

function InventoryService:HasItem(player, itemId, amount)
	return self:GetCount(player, itemId) >= (amount or 1)
end

function InventoryService:AddItem(player, itemId, amount)
	if not Config.Items[itemId] then
		warn(string.format("[GrowBloxia] Tried to add unknown item '%s'.", tostring(itemId)))
		return false
	end

	amount = math.floor(tonumber(amount) or 0)
	if amount <= 0 then
		return false
	end

	local profile = self:_getProfile(player)
	profile.items[itemId] = (profile.items[itemId] or 0) + amount
	self:Sync(player)
	return true
end

function InventoryService:RemoveItem(player, itemId, amount)
	if not Config.Items[itemId] then
		return false
	end

	amount = math.floor(tonumber(amount) or 0)
	if amount <= 0 then
		return false
	end

	local profile = self:_getProfile(player)
	local current = profile.items[itemId] or 0
	if current < amount then
		return false
	end

	profile.items[itemId] = current - amount
	self:Sync(player)
	return true
end

function InventoryService:GetPublicState(player)
	local profile = self:_getProfile(player)
	return {
		inventory = copyDictionary(profile.items),
		hotbar = copyArray(profile.hotbar),
	}
end

function InventoryService:Sync(player)
	if not self._syncRemote or not player.Parent then
		return
	end

	self._syncRemote:FireClient(player, self:GetPublicState(player))
end

return InventoryService
