local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")

local function waitForCamera()
	local cam
	repeat
		cam = workspace.CurrentCamera
		task.wait()
	until cam and cam.CameraType
	return cam
end

local function waitForControls()
	local controlsModule = nil
	repeat
		pcall(function()
			controlsModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
		end)
		task.wait()
	until controlsModule
	return controlsModule:GetControls()
end

local function waitForCharacter()
	local char = player.Character
	while not char or not char.Parent do
		player.CharacterAdded:Wait()
		char = player.Character
	end
	return char
end

local function waitForHRPandHumanoid(char)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChild("Humanoid")
	while not (hrp and humanoid) do
		hrp = char:FindFirstChild("HumanoidRootPart")
		humanoid = char:FindFirstChild("Humanoid")
		task.wait()
	end
	return hrp, humanoid
end

local function setupFlappyMode(char, hrp, humanoid, cam, controls)
	task.wait(0.15) -- Extra wait for mobile initialization

	local renderConn = nil

	-- Ensure FlappyMode BoolValue exists and is shared with other scripts
	local flappyMode = char:FindFirstChild("FlappyMode")
	if not flappyMode then
		flappyMode = Instance.new("BoolValue")
		flappyMode.Name = "FlappyMode"
		flappyMode.Value = false
		flappyMode.Parent = char
		print("Created FlappyMode for " .. char.Name)
	else
		print("Found existing FlappyMode for " .. char.Name)
	end
	flappyMode.Value = false

	-- === ALWAYS RESET CAMERA ON RESPAWN ===
	cam.CameraType = Enum.CameraType.Custom
	cam.CameraSubject = hrp
	task.wait()

	-- Make sure FlappyMode turns off on death too
	humanoid.Died:Connect(function()
		if renderConn then
			renderConn:Disconnect()
			renderConn = nil
		end
		cam.CFrame = cam.CFrame
		task.wait(3.0)
		if flappyMode then
			flappyMode.Value = false
		end
		cam.CameraType = Enum.CameraType.Custom
	end)

	-- Always enable flappy camera (permanent side-view)
	player.CameraMode = Enum.CameraMode.Classic
	cam.CameraType = Enum.CameraType.Scriptable
	cam.FieldOfView = 60
	player.CameraMinZoomDistance = 5
	player.CameraMaxZoomDistance = 5

	renderConn = RunService.RenderStepped:Connect(function()
		cam.CFrame = CFrame.new(Vector3.new(hrp.Position.X, 5, hrp.Position.Z + 35), Vector3.new(hrp.Position.X + 0.1, 5, hrp.Position.Z))
	end)
	print("Flappy camera enabled permanently.")

	-- Always disable default controls (PlayerMovement handles everything)
	controls:Disable()
	
	-- Jump with spacebar (only in FlappyMode - normal mode uses PlayerMovement)
	local UIS = game:GetService("UserInputService")
	UIS.InputBegan:Connect(function(input, processed)
		if flappyMode.Value and input.KeyCode == Enum.KeyCode.Space and not processed then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
end

-- Main connection, robust for mobile first join and respawn
player.CharacterAdded:Connect(function()
	local char = waitForCharacter()
	local hrp, humanoid = waitForHRPandHumanoid(char)
	local cam = waitForCamera()
	local controls = waitForControls()
	setupFlappyMode(char, hrp, humanoid, cam, controls)
end)

if player.Character then
	local char = waitForCharacter()
	local hrp, humanoid = waitForHRPandHumanoid(char)
	local cam = waitForCamera()
	local controls = waitForControls()
	setupFlappyMode(char, hrp, humanoid, cam, controls)
end
