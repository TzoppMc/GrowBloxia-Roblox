--!nocheck
-- Entry point for the playable GrowBloxia farming prototype.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Services = script.Parent:WaitForChild("Services")
local WorldService = require(Services:WaitForChild("WorldService"))
local InventoryService = require(Services:WaitForChild("InventoryService"))
local FarmService = require(Services:WaitForChild("FarmService"))

local function getOrCreate(parent, className, name)
	local current = parent:FindFirstChild(name)
	if current and current:IsA(className) then
		return current
	end

	if current then
		current:Destroy()
	end

	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local remotes = getOrCreate(ReplicatedStorage, "Folder", "GrowBloxiaRemotes")
local actionRequest = getOrCreate(remotes, "RemoteEvent", "ActionRequest")
local requestState = getOrCreate(remotes, "RemoteEvent", "RequestState")
local syncInventory = getOrCreate(remotes, "RemoteEvent", "SyncInventory")
local notify = getOrCreate(remotes, "RemoteEvent", "Notify")

-- Bright, clean lighting makes the generated placeholder blocks read like pixel art.
Lighting.Brightness = 2.2
Lighting.ClockTime = 13.5
Lighting.EnvironmentDiffuseScale = 0.45
Lighting.EnvironmentSpecularScale = 0.2
Lighting.OutdoorAmbient = Color3.fromRGB(156, 181, 203)
Lighting.Ambient = Color3.fromRGB(115, 132, 160)

WorldService:Init()
InventoryService:Init(syncInventory)
FarmService:Init(WorldService, InventoryService, notify)

requestState.OnServerEvent:Connect(function(player)
	InventoryService:Sync(player)
end)

actionRequest.OnServerEvent:Connect(function(player, payload)
	FarmService:HandleAction(player, payload)
end)

local function placeCharacterAtGarden(character)
	task.delay(0.15, function()
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root.Parent then
			root.CFrame = CFrame.new(WorldService:GetSpawnPosition())
		end
	end)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(placeCharacterAtGarden)
	if player.Character then
		placeCharacterAtGarden(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
