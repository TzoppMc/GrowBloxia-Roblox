--!nocheck
-- Pixel-styled HUD and input controller. It never changes game state directly:
-- every click is validated by FarmService on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local AssetManifest = require(Shared:WaitForChild("AssetManifest"))
local AssetResolver = require(Shared:WaitForChild("AssetResolver"))
local remotes = ReplicatedStorage:WaitForChild("GrowBloxiaRemotes")
local actionRequest = remotes:WaitForChild("ActionRequest")
local requestState = remotes:WaitForChild("RequestState")
local syncInventory = remotes:WaitForChild("SyncInventory")
local notify = remotes:WaitForChild("Notify")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local function create(className, properties)
	local instance = Instance.new(className)
	for property, value in pairs(properties or {}) do
		instance[property] = value
	end
	return instance
end

local function addStroke(parent, color, thickness)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness or 2,
		Parent = parent,
	})
end

-- AssetManifest values stay optional so a blank/missing Roblox image ID never
-- breaks the playable fallback UI.
local function addOptionalImage(parent, assetReference, properties)
	local image = AssetResolver.toContentId(assetReference)
	if not image then
		return nil
	end

	local options = properties or {}
	options.Image = image
	options.BackgroundTransparency = 1
	options.Parent = parent
	return create("ImageLabel", options)
end

local oldGui = playerGui:FindFirstChild("GrowBloxiaHUD")
if oldGui then
	oldGui:Destroy()
end

local gui = create("ScreenGui", {
	Name = "GrowBloxiaHUD",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 5,
	Parent = playerGui,
})

local topPanel = create("Frame", {
	Name = "TopPanel",
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.fromOffset(14, 14),
	Size = UDim2.fromOffset(356, 70),
	BackgroundColor3 = Color3.fromRGB(35, 49, 72),
	BorderSizePixel = 0,
	Parent = gui,
})
addStroke(topPanel, Color3.fromRGB(255, 222, 133), 2)
addOptionalImage(topPanel, AssetManifest.UI.panelFrame, {
	Name = "AssetFrame",
	Size = UDim2.fromScale(1, 1),
	ScaleType = Enum.ScaleType.Slice,
	SliceCenter = Rect.new(6, 6, 26, 26),
	ImageTransparency = 0.10,
})

local pocketPanel = create("Frame", {
	Name = "PocketPanel",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 14),
	Size = UDim2.fromOffset(214, 70),
	BackgroundColor3 = Color3.fromRGB(35, 49, 72),
	BorderSizePixel = 0,
	Parent = gui,
})
addStroke(pocketPanel, Color3.fromRGB(117, 192, 138), 2)
addOptionalImage(pocketPanel, AssetManifest.UI.panelFrame, {
	Name = "AssetFrame",
	Size = UDim2.fromScale(1, 1),
	ScaleType = Enum.ScaleType.Slice,
	SliceCenter = Rect.new(6, 6, 26, 26),
	ImageTransparency = 0.10,
})

create("TextLabel", {
	Position = UDim2.fromOffset(10, 7),
	Size = UDim2.fromOffset(190, 20),
	BackgroundTransparency = 1,
	Text = "HASIL PANEN",
	TextColor3 = Color3.fromRGB(182, 232, 171),
	TextSize = 12,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = pocketPanel,
})

local pocketLabel = create("TextLabel", {
	Position = UDim2.fromOffset(10, 30),
	Size = UDim2.fromOffset(194, 30),
	BackgroundTransparency = 1,
	Text = "LOBAK x0  •  WORTEL x0",
	TextColor3 = Color3.fromRGB(244, 245, 232),
	TextSize = 12,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = pocketPanel,
})

create("TextLabel", {
	Name = "Title",
	Position = UDim2.fromOffset(12, 8),
	Size = UDim2.fromOffset(240, 27),
	BackgroundTransparency = 1,
	Text = "GROWBLOXIA",
	TextColor3 = Color3.fromRGB(255, 231, 151),
	TextStrokeColor3 = Color3.fromRGB(39, 42, 60),
	TextStrokeTransparency = 0.1,
	TextSize = 24,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = topPanel,
})

create("TextLabel", {
	Name = "Subtitle",
	Position = UDim2.fromOffset(13, 38),
	Size = UDim2.fromOffset(326, 22),
	BackgroundTransparency = 1,
	Text = "KEBUN BLOK • TANAM • SIRAM • PANEN",
	TextColor3 = Color3.fromRGB(185, 220, 236),
	TextSize = 12,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = topPanel,
})

local helpPanel = create("Frame", {
	Name = "HelpPanel",
	Position = UDim2.fromOffset(14, 94),
	Size = UDim2.fromOffset(356, 73),
	BackgroundColor3 = Color3.fromRGB(35, 49, 72),
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
	Parent = gui,
})
addStroke(helpPanel, Color3.fromRGB(109, 166, 196), 1)
addOptionalImage(helpPanel, AssetManifest.UI.panelFrame, {
	Name = "AssetFrame",
	Size = UDim2.fromScale(1, 1),
	ScaleType = Enum.ScaleType.Slice,
	SliceCenter = Rect.new(6, 6, 26, 26),
	ImageTransparency = 0.16,
})

create("TextLabel", {
	Position = UDim2.fromOffset(10, 7),
	Size = UDim2.new(1, -20, 1, -14),
	BackgroundTransparency = 1,
	Text = "[1–5] PILIH ITEM\n[KLIK KIRI] GUNAKAN / PANEN\n[KLIK KANAN] CABUT / BONGKAR",
	TextColor3 = Color3.fromRGB(231, 240, 245),
	TextSize = 12,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Center,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.Code,
	Parent = helpPanel,
})

local contextPanel = create("Frame", {
	Name = "ContextPanel",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 15),
	Size = UDim2.fromOffset(290, 36),
	BackgroundColor3 = Color3.fromRGB(28, 39, 54),
	BackgroundTransparency = 0.06,
	BorderSizePixel = 0,
	Visible = false,
	Parent = gui,
})
addStroke(contextPanel, Color3.fromRGB(120, 206, 142), 1)

local contextLabel = create("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = Color3.fromRGB(237, 245, 233),
	TextSize = 13,
	Font = Enum.Font.GothamBold,
	Parent = contextPanel,
})

local toast = create("TextLabel", {
	Name = "Toast",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -125),
	Size = UDim2.fromOffset(480, 42),
	BackgroundColor3 = Color3.fromRGB(41, 53, 73),
	BackgroundTransparency = 0.04,
	BorderSizePixel = 0,
	Text = "",
	TextColor3 = Color3.fromRGB(245, 245, 245),
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	TextWrapped = true,
	Visible = false,
	Parent = gui,
})
local toastStroke = addStroke(toast, Color3.fromRGB(130, 181, 214), 2)

local hotbarFrame = create("Frame", {
	Name = "Hotbar",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -18),
	Size = UDim2.fromOffset(434, 88),
	BackgroundTransparency = 1,
	Parent = gui,
})

create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = hotbarFrame,
})

local actionPanel = create("Frame", {
	Name = "ActionPanel",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -24),
	Size = UDim2.fromOffset(144, 132),
	BackgroundTransparency = 1,
	Parent = gui,
})

local function makeActionButton(name, position, color, text)
	local button = create("TextButton", {
		Name = name,
		Position = position,
		Size = UDim2.fromOffset(144, 59),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		TextWrapped = true,
		Font = Enum.Font.GothamBlack,
		Parent = actionPanel,
	})
	addStroke(button, Color3.fromRGB(30, 39, 56), 2)
	return button
end

local useButton = makeActionButton("Use", UDim2.fromOffset(0, 0), Color3.fromRGB(74, 157, 104), "GUNAKAN\nKLIK KIRI")
local breakButton = makeActionButton("Break", UDim2.fromOffset(0, 68), Color3.fromRGB(179, 90, 77), "BONGKAR\nKLIK KANAN")

local inventory = {}
local hotbar = {}
local selectedIndex = 1
local hotbarButtons = {}
local toastNonce = 0
local lastActionAt = 0

local function refreshPocket()
	pocketLabel.Text = string.format(
		"LOBAK x%d  •  WORTEL x%d",
		inventory.turnip or 0,
		inventory.carrot or 0
	)
end

local function showToast(text, kind)
	toastNonce = toastNonce + 1
	local nonce = toastNonce
	local palette = {
		success = Color3.fromRGB(114, 219, 139),
		warning = Color3.fromRGB(241, 166, 86),
		info = Color3.fromRGB(128, 190, 229),
	}
	toastStroke.Color = palette[kind] or palette.info
	toast.Text = tostring(text or "")
	toast.Visible = true

	task.delay(3.2, function()
		if toastNonce == nonce then
			toast.Visible = false
		end
	end)
end

local function currentItemId()
	return hotbar[selectedIndex]
end

local function refreshHotbar()
	refreshPocket()
	for _, button in pairs(hotbarButtons) do
		button:Destroy()
	end
	hotbarButtons = {}

	if #hotbar == 0 then
		return
	end
	selectedIndex = math.clamp(selectedIndex, 1, #hotbar)
	hotbarFrame.Size = UDim2.fromOffset(math.max(#hotbar * 82 + (#hotbar - 1) * 6, 82), 88)

	for index, itemId in ipairs(hotbar) do
		local item = Config.Items[itemId] or {
			displayName = itemId,
			shortName = itemId,
			color = Color3.fromRGB(100, 100, 100),
		}
		local selected = index == selectedIndex
		local count = inventory[itemId] or 0
		local button = create("TextButton", {
			Name = "Slot" .. index,
			LayoutOrder = index,
			Size = UDim2.fromOffset(82, 82),
			BackgroundColor3 = selected and Color3.fromRGB(255, 213, 106) or Color3.fromRGB(43, 57, 78),
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Parent = hotbarFrame,
		})
		addStroke(button, selected and Color3.fromRGB(255, 244, 197) or Color3.fromRGB(23, 31, 46), selected and 3 or 2)
		addOptionalImage(button, AssetManifest.UI.itemBox, {
			Name = "AssetSlotFrame",
			Size = UDim2.fromScale(1, 1),
			ImageRectOffset = Vector2.new(0, 0),
			ImageRectSize = Vector2.new(64, 64),
			ImageTransparency = selected and 0 or 0.18,
		})
		if selected then
			addOptionalImage(button, AssetManifest.UI.inventorySelection, {
				Name = "AssetSelection",
				Size = UDim2.fromScale(1, 1),
				ImageTransparency = 0.05,
			})
		end

		create("TextLabel", {
			Name = "Key",
			Position = UDim2.fromOffset(5, 3),
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = Color3.fromRGB(26, 34, 49),
			BorderSizePixel = 0,
			Text = tostring(index),
			TextColor3 = Color3.fromRGB(255, 239, 176),
			TextSize = 12,
			Font = Enum.Font.GothamBlack,
			Parent = button,
		})

		create("Frame", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 11),
			Size = UDim2.fromOffset(29, 29),
			BackgroundColor3 = item.color,
			BorderSizePixel = 0,
			Parent = button,
		})

		create("TextLabel", {
			Name = "Name",
			Position = UDim2.fromOffset(3, 42),
			Size = UDim2.fromOffset(76, 26),
			BackgroundTransparency = 1,
			Text = item.shortName or item.displayName,
			TextColor3 = selected and Color3.fromRGB(48, 50, 55) or Color3.fromRGB(238, 245, 247),
			TextSize = 9,
			TextWrapped = true,
			Font = Enum.Font.GothamBold,
			Parent = button,
		})

		create("TextLabel", {
			Name = "Count",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -5, 1, -4),
			Size = UDim2.fromOffset(30, 18),
			BackgroundTransparency = 1,
			Text = "x" .. tostring(count),
			TextColor3 = count > 0 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(244, 131, 125),
			TextStrokeTransparency = 0.45,
			TextSize = 12,
			Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = button,
		})

		button.Activated:Connect(function()
			selectedIndex = index
			refreshHotbar()
		end)

		hotbarButtons[index] = button
	end
end

local function copyTable(source)
	local result = {}
	for key, value in pairs(source or {}) do
		result[key] = value
	end
	return result
end

local function getCellFromInstance(instance)
	local current = instance
	while current do
		local x = current:GetAttribute("CellX")
		local z = current:GetAttribute("CellZ")
		if typeof(x) == "number" and typeof(z) == "number" then
			return x, z, current
		end
		if current == Workspace then
			break
		end
		current = current.Parent
	end
	return nil, nil, nil
end

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

local function getCellAtScreenPosition(screenPosition)
	local camera = Workspace.CurrentCamera
	if camera and screenPosition then
		local character = player.Character
		raycastParams.FilterDescendantsInstances = character and { character } or {}
		local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
		local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, raycastParams)
		if result then
			local x, z, instance = getCellFromInstance(result.Instance)
			if x then
				return x, z, instance
			end
		end
	end

	return getCellFromInstance(mouse.Target)
end

local targetHighlight = create("Highlight", {
	Name = "GrowBloxiaTarget",
	FillColor = Color3.fromRGB(255, 220, 104),
	FillTransparency = 0.76,
	OutlineColor = Color3.fromRGB(255, 247, 200),
	OutlineTransparency = 0.05,
	DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
	Enabled = false,
	Parent = Workspace,
})

local function findAttribute(instance, attribute)
	local current = instance
	while current do
		local value = current:GetAttribute(attribute)
		if value ~= nil then
			return value
		end
		if current == Workspace then
			break
		end
		current = current.Parent
	end
	return nil
end

local function getTileForCell(x, z)
	local world = Workspace:FindFirstChild("GrowBloxiaWorld")
	local tiles = world and world:FindFirstChild("Tiles")
	return tiles and tiles:FindFirstChild(string.format("Tile_%d_%d", x, z))
end

local function updateTargetDisplay()
	local x, z, hit = getCellFromInstance(mouse.Target)
	if not x then
		targetHighlight.Enabled = false
		contextPanel.Visible = false
		return
	end

	local tile = getTileForCell(x, z)
	targetHighlight.Adornee = tile or hit
	targetHighlight.Enabled = targetHighlight.Adornee ~= nil
	contextPanel.Visible = true

	local cropName = findAttribute(hit, "CropName")
	if cropName then
		local ready = findAttribute(hit, "Ready")
		local watered = findAttribute(hit, "Watered")
		if ready then
			contextLabel.Text = string.upper(cropName) .. " • SIAP DIPANEN"
		elseif watered then
			contextLabel.Text = string.upper(cropName) .. " • SEDANG DISIRAM"
		else
			contextLabel.Text = string.upper(cropName) .. " • SEDANG TUMBUH"
		end
	else
		local tileType = findAttribute(hit, "TileType") or "Grass"
		local tileData = Config.TileTypes[tileType]
		contextLabel.Text = string.upper(tileData and tileData.displayName or tostring(tileType))
	end
end

local function sendAction(action, screenPosition)
	if os.clock() - lastActionAt < 0.07 then
		return
	end

	local x, z = getCellAtScreenPosition(screenPosition)
	if not x then
		showToast("Arahkan kursor ke petak kebun terlebih dahulu.", "warning")
		return
	end

	lastActionAt = os.clock()
	actionRequest:FireServer({
		action = action,
		itemId = currentItemId(),
		x = x,
		z = z,
	})
end

useButton.Activated:Connect(function()
	sendAction("use", nil)
end)

breakButton.Activated:Connect(function()
	sendAction("break", nil)
end)

local numberKeys = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	local keyIndex = numberKeys[input.KeyCode]
	if keyIndex then
		if hotbar[keyIndex] then
			selectedIndex = keyIndex
			refreshHotbar()
		end
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		sendAction("use", input.Position)
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		sendAction("break", input.Position)
	elseif input.UserInputType == Enum.UserInputType.Touch then
		sendAction("use", input.Position)
	end
end)

syncInventory.OnClientEvent:Connect(function(state)
	if type(state) ~= "table" then
		return
	end

	inventory = copyTable(state.inventory)
	hotbar = copyTable(state.hotbar)
	refreshHotbar()
end)

notify.OnClientEvent:Connect(function(data)
	if type(data) == "table" then
		showToast(data.text, data.kind)
	elseif type(data) == "string" then
		showToast(data, "info")
	end
end)

RunService.RenderStepped:Connect(updateTargetDisplay)

-- Covers the brief window where the server's first automatic sync happens before
-- this LocalScript subscribes to SyncInventory.
requestState:FireServer()
showToast("Pilih item di hotbar, lalu mulai berkebun!", "info")
