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
local isLoading = true

-- Static camera position from Studio
local CAMERA_POSITION = Vector3.new(-187.951, 6.347, -123.057)
local CAMERA_ORIENTATION = Vector3.new(-9.931, -28.403, 0) -- pitch, yaw, roll in degrees
local CAMERA_FOV = 70

-- Positions to stream in for full map visibility (grid covering visible area)
local STREAM_POSITIONS = {
	CAMERA_POSITION,
	CAMERA_LOOK_AT,
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
local loadingScreen
local cameraConnection = nil

-- Build the camera CFrame using position and orientation
local function getMenuCameraCFrame()
	local pitch = math.rad(CAMERA_ORIENTATION.X)
	local yaw = math.rad(CAMERA_ORIENTATION.Y)
	local roll = math.rad(CAMERA_ORIENTATION.Z)
	return CFrame.new(CAMERA_POSITION) * CFrame.Angles(pitch, yaw, roll)
end

-- Create loading screen
local function createLoadingScreen()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LoadingScreen"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 200 -- Above main menu
	screenGui.IgnoreGuiInset = true
	screenGui.Enabled = true
	
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BorderSizePixel = 0
	background.Parent = screenGui
	
	local loadingText = Instance.new("TextLabel")
	loadingText.Name = "LoadingText"
	loadingText.Size = UDim2.new(0.5, 0, 0.1, 0)
	loadingText.Position = UDim2.new(0.5, 0, 0.5, 0)
	loadingText.AnchorPoint = Vector2.new(0.5, 0.5)
	loadingText.BackgroundTransparency = 1
	loadingText.Text = "Loading..."
	loadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
	loadingText.Font = Enum.Font.FredokaOne
	loadingText.TextScaled = true
	loadingText.Parent = background
	
	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.fromRGB(50, 100, 150)
	textStroke.Thickness = 2
	textStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	textStroke.Parent = loadingText
	
	screenGui.Parent = PlayerGui
	return screenGui, background
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

-- Start menu camera system
local function startMenuCamera()
	Camera.CameraType = Enum.CameraType.Scriptable
	Camera.FieldOfView = CAMERA_FOV
	
	local menuCFrame = getMenuCameraCFrame()
	Camera.CFrame = menuCFrame
	
	-- Lock camera every frame to prevent Roblox from overriding
	if cameraConnection then
		cameraConnection:Disconnect()
	end
	cameraConnection = RunService.RenderStepped:Connect(function()
		if menuOpen then
			Camera.CameraType = Enum.CameraType.Scriptable
			Camera.FieldOfView = CAMERA_FOV
			Camera.CFrame = menuCFrame
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
	background.Parent = screenGui
	
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
	
	-- Button container
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Size = UDim2.new(0.3, 0, 0.5, 0)
	buttonContainer.Position = UDim2.new(0.5, 0, 0.55, 0)
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
		button.Size = UDim2.new(1, 0, 0.2, 0)
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
	local spectateButton = createButton("SpectateButton", "Spectate", 2)
	local optionsButton = createButton("OptionsButton", "Options", 3)
	
	-- Play button action
	playButton.MouseButton1Click:Connect(function()
		menuOpen = false
		screenGui.Enabled = false
		stopMenuCamera()
		PlayEvent:FireServer()
	end)
	
	-- Spectate button action (spectate without spawning)
	spectateButton.MouseButton1Click:Connect(function()
		menuOpen = false
		screenGui.Enabled = false
		stopMenuCamera()
		-- Don't fire any event - just close menu and let them spectate
	end)
	
	-- Options button action (placeholder)
	optionsButton.MouseButton1Click:Connect(function()
		-- Does nothing yet
	end)
	
	screenGui.Parent = PlayerGui
	return screenGui
end

-- Create loading screen first (hidden behind black screen while loading)
loadingScreen = createLoadingScreen()

-- Set up camera immediately so streaming happens at the right location
startMenuCamera()

-- Wait for map to stream in
waitForStreaming()

-- Create the menu (but keep it hidden initially)
mainMenu = createMainMenu()
mainMenu.Enabled = false

-- Fade out loading screen and show main menu
local loadingBg = loadingScreen:FindFirstChild("Background")
if loadingBg then
	local fadeOut = TweenService:Create(loadingBg, TweenInfo.new(0.5), {BackgroundTransparency = 1})
	fadeOut:Play()
	fadeOut.Completed:Wait()
end
loadingScreen:Destroy()
mainMenu.Enabled = true
isLoading = false

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
