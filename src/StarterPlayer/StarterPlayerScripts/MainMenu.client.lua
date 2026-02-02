local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- Wait for events
local PlayEvent = ReplicatedStorage:WaitForChild("PlayEvent")

local menuOpen = true

-- Static camera position from Studio
local CAMERA_START_POS = Vector3.new(-187.951, 6.347, -123.057)
local CAMERA_START_ORIENTATION = Vector3.new(-9.931, -28.403, 0) -- pitch, yaw, roll in degrees

local CAMERA_END_POS = Vector3.new(-140.577, 4.46, -122.969)
local CAMERA_END_ORIENTATION = Vector3.new(-4.232, -36.002, 0)

local CAMERA_FOV = 70

-- Panning settings
local PAN_DURATION = 15 -- seconds to reach end point
local FADE_DURATION = 0.5
local FADE_OPACITY = 0 -- fully black

-- Positions to stream in for full map visibility (grid covering visible area)
local STREAM_POSITIONS = {
	CAMERA_START_POS,
	CAMERA_END_POS,
	-- Grid of positions to load more of the map
	Vector3.new(-200, 10, -160),
	Vector3.new(-200, 10, -140),
	Vector3.new(-200, 10, -120),
	Vector3.new(-180, 10, -160),
	Vector3.new(-180, 10, -140),
	Vector3.new(-180, 10, -120),
	Vector3.new(-160, 10, -160),
	Vector3.new(-160, 10, -140),
	Vector3.new(-160, 10, -120),
	Vector3.new(-140, 10, -160),
	Vector3.new(-140, 10, -140),
	Vector3.new(-140, 10, -120),
	Vector3.new(-120, 10, -160),
	Vector3.new(-120, 10, -140),
	Vector3.new(-120, 10, -120),
}

-- Forward declare
local mainMenu
local cameraConnection = nil
local fadeOverlay = nil

-- Build the camera CFrame by interpolating between start and end
local function getMenuCameraCFrame(alpha)
	alpha = alpha or 0
	-- Lerp position
	local pos = CAMERA_START_POS:Lerp(CAMERA_END_POS, alpha)
	-- Lerp orientation
	local orientation = CAMERA_START_ORIENTATION:Lerp(CAMERA_END_ORIENTATION, alpha)
	local pitch = math.rad(orientation.X)
	local yaw = math.rad(orientation.Y)
	local roll = math.rad(orientation.Z)
	return CFrame.new(pos) * CFrame.Angles(pitch, yaw, roll)
end

-- Wait for streaming to complete
local function waitForStreaming()
	-- Wait for the game to fully load
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	
	-- Request streaming around camera positions (this actually loads the geometry)
	if workspace.StreamingEnabled then
		for _, pos in ipairs(STREAM_POSITIONS) do
			LocalPlayer:RequestStreamAroundAsync(pos)
		end
	end
	
	-- Also preload textures/sounds
	ContentProvider:PreloadAsync(workspace:GetDescendants())
end

-- Fade to black, then immediately fade back in and reset camera
local function doFadeTransition(resetCallback)
	if not fadeOverlay then return end
	
	-- Fade to black
	local fadeOut = TweenService:Create(fadeOverlay, TweenInfo.new(FADE_DURATION), {BackgroundTransparency = 0})
	fadeOut:Play()
	fadeOut.Completed:Connect(function()
		-- Reset camera position
		if resetCallback then
			resetCallback()
		end
		-- Immediately fade back in
		local fadeIn = TweenService:Create(fadeOverlay, TweenInfo.new(FADE_DURATION), {BackgroundTransparency = 1})
		fadeIn:Play()
	end)
end

-- Initial fade in from black
local function initialFadeIn()
	if not fadeOverlay then return end
	local tween = TweenService:Create(fadeOverlay, TweenInfo.new(FADE_DURATION), {BackgroundTransparency = 1})
	tween:Play()
end

-- Start menu camera system with panning
local function startMenuCamera()
	Camera.CameraType = Enum.CameraType.Scriptable
	Camera.FieldOfView = CAMERA_FOV
	
	local startTime = tick()
	local hasFadedOut = false
	local needsFadeIn = true
	
	Camera.CFrame = getMenuCameraCFrame(0)
	
	-- Lock camera every frame and pan
	if cameraConnection then
		cameraConnection:Disconnect()
	end
	cameraConnection = RunService.RenderStepped:Connect(function(dt)
		if menuOpen then
			Camera.CameraType = Enum.CameraType.Scriptable
			Camera.FieldOfView = CAMERA_FOV
			
			-- Calculate pan progress (0 to 1 over PAN_DURATION)
			local elapsed = tick() - startTime
			local alpha = math.min(elapsed / PAN_DURATION, 1)
			
			-- Initial fade in at the very start
			if needsFadeIn and fadeOverlay then
				needsFadeIn = false
				initialFadeIn()
			end
			
			-- Start fade transition near end of cycle (at 90%)
			if alpha >= 0.9 and not hasFadedOut then
				hasFadedOut = true
				doFadeTransition(function()
					-- Reset when screen is fully black
					startTime = tick()
					hasFadedOut = false
					Camera.CFrame = getMenuCameraCFrame(0)
				end)
			end
			
			Camera.CFrame = getMenuCameraCFrame(alpha)
		end
	end)
end

-- Stop menu camera
local function stopMenuCamera()
	menuOpen = false
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end
	Camera.CameraType = Enum.CameraType.Custom
end

-- Create the main menu UI
local function createMainMenu()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MainMenu"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 100
	screenGui.IgnoreGuiInset = true
	screenGui.Enabled = true
	
	-- Transparent background (shows camera view)
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundTransparency = 1
	background.BorderSizePixel = 0
	background.ZIndex = 5
	background.Parent = screenGui
	
	-- Fade overlay for transitions (starts black for initial fade-in)
	-- ZIndex 2 keeps it behind UI elements (ZIndex 5) but covers camera
	fadeOverlay = Instance.new("Frame")
	fadeOverlay.Name = "FadeOverlay"
	fadeOverlay.Size = UDim2.new(1, 0, 1, 0)
	fadeOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	fadeOverlay.BackgroundTransparency = 0 -- Start fully black
	fadeOverlay.BorderSizePixel = 0
	fadeOverlay.ZIndex = 2
	fadeOverlay.Parent = screenGui
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 0.2, 0)
	title.Position = UDim2.new(0.5, 0, 0.15, 0)
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.BackgroundTransparency = 1
	title.Text = "FLAPPY BLOX"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.ZIndex = 5
	title.Parent = background
	
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(50, 100, 150)
	titleStroke.Thickness = 4
	titleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	titleStroke.Parent = title
	
	-- Button container (positioned near bottom of screen)
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Size = UDim2.new(0.2, 0, 0.12, 0)
	buttonContainer.Position = UDim2.new(0.5, 0, 0.78, 0)
	buttonContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.ZIndex = 5
	buttonContainer.Parent = background
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.Padding = UDim.new(0.05, 0)
	listLayout.Parent = buttonContainer
	
	-- Helper function to create styled buttons
	local function createButton(name, text, layoutOrder)
		local button = Instance.new("TextButton")
		button.Name = name
		button.Size = UDim2.new(1, 0, 1, 0)
		button.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.Text = text
		button.Font = Enum.Font.FredokaOne
		button.TextScaled = true
		button.LayoutOrder = layoutOrder
		button.ZIndex = 5
		button.Parent = buttonContainer
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.25, 0)
		corner.Parent = button
		
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(50, 100, 150)
		stroke.Thickness = 3
		stroke.Parent = button
		
		local textStroke = Instance.new("UIStroke")
		textStroke.Color = Color3.fromRGB(50, 100, 150)
		textStroke.Thickness = 1.5
		textStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		textStroke.Parent = button
		
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200))
		gradient.Rotation = 90
		gradient.Parent = button
		
		return button
	end
	
	-- Create buttons
	local playButton = createButton("PlayButton", "Play", 1)
	
	-- Play button action
	playButton.MouseButton1Click:Connect(function()
		-- Fire server to spawn character
		PlayEvent:FireServer()
		
		-- Wait for character to load while keeping menu camera
		local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		character:WaitForChild("HumanoidRootPart")
		
		-- Give camera a moment to attach to character
		task.wait(0.1)
		
		-- Now stop menu camera and hide UI
		menuOpen = false
		screenGui.Enabled = false
		stopMenuCamera()
	end)
	
	-- Remove any logic or event connections for spectateButton, optionsButton, and menuButton
	-- ...existing code...
	
	screenGui.Parent = PlayerGui
	return screenGui
end

-- Wait for game to load
if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- Create and show the menu
mainMenu = createMainMenu()

-- Start camera panning
startMenuCamera()

-- Store globally so other scripts can access it
local menuValue = Instance.new("BoolValue")
menuValue.Name = "InMainMenu"
menuValue.Value = true
menuValue.Parent = LocalPlayer

-- Create event for other scripts to show main menu
local showMenuEvent = Instance.new("BindableEvent")
showMenuEvent.Name = "ShowMainMenu"
showMenuEvent.Parent = LocalPlayer

showMenuEvent.Event:Connect(function()
	menuOpen = true
	if mainMenu then
		mainMenu.Enabled = true
		menuValue.Value = true
		startMenuCamera()
	end
end)

-- Update the value when menu state changes
mainMenu:GetPropertyChangedSignal("Enabled"):Connect(function()
	menuValue.Value = mainMenu.Enabled
end)
