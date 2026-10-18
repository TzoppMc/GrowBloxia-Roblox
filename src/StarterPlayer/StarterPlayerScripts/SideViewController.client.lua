--!nocheck
-- Locks the Roblox character to the X/Y tile plane and presents the game with a
-- side-view camera. The world remains normal Roblox physics, just viewed as a
-- 2D platform sandbox.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local currentCharacter = nil
local currentHumanoid = nil
local currentRoot = nil
local leftHeld = false
local rightHeld = false

local function configureCharacter(character)
	currentCharacter = character
	currentHumanoid = character:WaitForChild("Humanoid", 10)
	currentRoot = character:WaitForChild("HumanoidRootPart", 10)
	if not currentHumanoid or not currentRoot then
		return
	end

	currentHumanoid.AutoRotate = false
	currentHumanoid.WalkSpeed = 14
	currentHumanoid.UseJumpPower = true
	currentHumanoid.JumpPower = 48

	local position = currentRoot.Position
	currentRoot.CFrame = CFrame.new(position.X, position.Y, Config.Camera.PlaneZ)
end

local function bindHorizontal(actionName, inputState)
	local active = inputState == Enum.UserInputState.Begin or inputState == Enum.UserInputState.Change
	if actionName == "GrowBloxiaMoveLeft" then
		leftHeld = active
	elseif actionName == "GrowBloxiaMoveRight" then
		rightHeld = active
	end
	return Enum.ContextActionResult.Sink
end

local function bindJump(_, inputState)
	if inputState == Enum.UserInputState.Begin and currentHumanoid then
		currentHumanoid.Jump = true
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindActionAtPriority(
	"GrowBloxiaMoveLeft",
	bindHorizontal,
	true,
	3000,
	Enum.KeyCode.A,
	Enum.KeyCode.Left
)
ContextActionService:BindActionAtPriority(
	"GrowBloxiaMoveRight",
	bindHorizontal,
	true,
	3000,
	Enum.KeyCode.D,
	Enum.KeyCode.Right
)
ContextActionService:BindActionAtPriority(
	"GrowBloxiaJump",
	bindJump,
	true,
	3000,
	Enum.KeyCode.Space,
	Enum.KeyCode.Up
)

-- Native touch buttons are only displayed on touch-capable devices.
ContextActionService:SetTitle("GrowBloxiaMoveLeft", "◀")
ContextActionService:SetTitle("GrowBloxiaMoveRight", "▶")
ContextActionService:SetTitle("GrowBloxiaJump", "JUMP")
ContextActionService:SetPosition("GrowBloxiaMoveLeft", UDim2.new(0, 34, 1, -128))
ContextActionService:SetPosition("GrowBloxiaMoveRight", UDim2.new(0, 106, 1, -128))
ContextActionService:SetPosition("GrowBloxiaJump", UDim2.new(1, -244, 1, -128))

player.CharacterAdded:Connect(configureCharacter)
if player.Character then
	task.spawn(configureCharacter, player.Character)
end

RunService:BindToRenderStep("GrowBloxiaSideMove", Enum.RenderPriority.Input.Value + 2, function()
	if not currentHumanoid or not currentRoot or not currentRoot.Parent then
		return
	end

	local direction = (rightHeld and 1 or 0) - (leftHeld and 1 or 0)
	currentHumanoid:Move(Vector3.new(direction, 0, 0), false)
end)

RunService.Heartbeat:Connect(function()
	if not currentRoot or not currentRoot.Parent then
		return
	end

	local velocity = currentRoot.AssemblyLinearVelocity
	currentRoot.AssemblyLinearVelocity = Vector3.new(velocity.X, velocity.Y, 0)
	local position = currentRoot.Position
	if math.abs(position.Z - Config.Camera.PlaneZ) > 0.01 then
		currentRoot.CFrame = CFrame.new(position.X, position.Y, Config.Camera.PlaneZ)
	end
end)

RunService:BindToRenderStep("GrowBloxiaSideCamera", Enum.RenderPriority.Camera.Value + 1, function()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = Config.Camera.FieldOfView

	local focusPosition
	if currentRoot and currentRoot.Parent then
		focusPosition = currentRoot.Position + Vector3.new(0, Config.Camera.TargetHeight, 0)
	else
		focusPosition = Vector3.new(0, Config.Camera.TargetHeight, Config.Camera.PlaneZ)
	end

	local cameraPosition = focusPosition + Vector3.new(0, Config.Camera.VerticalOffset, -Config.Camera.Distance)
	camera.CFrame = CFrame.lookAt(cameraPosition, focusPosition)
	camera.Focus = CFrame.new(focusPosition)
end)
