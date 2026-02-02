local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Persistent camera connection that survives death
local persistentCameraConn = nil
local lastKnownPosition = Vector3.new(0, 5, 0)

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

-- Setup persistent camera that never changes
local function setupPersistentCamera()
	local cam = waitForCamera()
	
	player.CameraMode = Enum.CameraMode.Classic
	cam.CameraType = Enum.CameraType.Scriptable
	cam.FieldOfView = 60
	player.CameraMinZoomDistance = 5
	player.CameraMaxZoomDistance = 5
	
	-- Check for spectating value
	local isSpectating = player:FindFirstChild("IsSpectating")
	
	if persistentCameraConn then
		persistentCameraConn:Disconnect()
	end
	
	persistentCameraConn = RunService.RenderStepped:Connect(function()
		-- Don't update camera if spectating
		if isSpectating and isSpectating.Value then return end
		
		-- Get current character's HRP if available
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		
		if hrp then
			lastKnownPosition = hrp.Position
		end
		
		-- Always use side-view camera, even during death
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.new(
			Vector3.new(lastKnownPosition.X, 5, lastKnownPosition.Z + 35),
			Vector3.new(lastKnownPosition.X + 0.1, 5, lastKnownPosition.Z)
		)
	end)
	
	print("Persistent flappy camera enabled.")
end

local function setupFlappyMode(char, hrp, humanoid, cam, controls)
	task.wait(0.1)

	-- Ensure FlappyMode BoolValue exists
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

	-- Make sure FlappyMode turns off on death
	humanoid.Died:Connect(function()
		if flappyMode then
			flappyMode.Value = false
		end
	end)

	-- Enable/disable controls based on flappy mode
	local function updateControls()
		if flappyMode.Value then
			controls:Disable() -- Disable in flappy mode (we handle movement ourselves)
		else
			controls:Enable() -- Enable Roblox default controls in manual mode
		end
	end
	
	-- Listen for flappy mode changes
	flappyMode.Changed:Connect(updateControls)
	
	-- Set initial state
	updateControls()
	
	-- Jump with spacebar (only in FlappyMode)
	local UIS = game:GetService("UserInputService")
	UIS.InputBegan:Connect(function(input, processed)
		if flappyMode.Value and input.KeyCode == Enum.KeyCode.Space and not processed then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
end

-- Setup persistent camera ONCE at start
setupPersistentCamera()

-- Main connection for character-specific setup
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
