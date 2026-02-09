local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Zones (should match server)
local Zones = {
	{ name = "Green Meadows", xMin = nil,        xMax = 1360.450 },
	{ name = "Sunny Beach",   xMin = 1360.451,   xMax = 2982.672 },
	{ name = "Sakura Fields", xMin = 2982.673,   xMax = 4648.372 },
	{ name = "Snowland",      xMin = 4648.373,   xMax = 6309.000 },
	{ name = "Haunted Woods", xMin = 6309.001,   xMax = 7971.000 },
}

-- Ensure RemoteEvent exists (create client-side reference)
local teleportEvent = ReplicatedStorage:FindFirstChild("ZoneTeleportEvent")
if not teleportEvent then
	teleportEvent = Instance.new("RemoteEvent")
	teleportEvent.Name = "ZoneTeleportEvent"
	teleportEvent.Parent = ReplicatedStorage
end

-- Build left menu button
local function createMenuButton()
	local screen = PlayerGui:FindFirstChild("ZoneMenuGui")
	if screen then return screen end
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ZoneMenuGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = PlayerGui

	local button = Instance.new("TextButton")
	button.Name = "OpenZoneMenu"
	button.Size = UDim2.new(0, 48, 0, 48)
	button.Position = UDim2.new(0, 12, 0.5, -24)
	button.AnchorPoint = Vector2.new(0, 0.5)
	button.BackgroundColor3 = Color3.fromRGB(30,30,30)
	button.TextColor3 = Color3.fromRGB(255,255,255)
	button.Text = "Zones"
	button.Font = Enum.Font.SourceSansBold
	button.TextScaled = true
	button.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,8)
	corner.Parent = button

	-- Popup frame (hidden by default)
	local popup = Instance.new("Frame")
	popup.Name = "ZonePopup"
	popup.Size = UDim2.new(0.6, 0, 0.7, 0)
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = Color3.fromRGB(20,20,30)
	popup.BorderSizePixel = 0
	popup.Visible = false
	popup.Parent = screenGui

	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0,10)
	popupCorner.Parent = popup

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 0, 56)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "Zones"
	title.TextColor3 = Color3.fromRGB(255,255,255)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.Parent = popup

	local buttonsContainer = Instance.new("Frame")
	buttonsContainer.Size = UDim2.new(1, -40, 1, -100)
	buttonsContainer.Position = UDim2.new(0, 20, 0, 80)
	buttonsContainer.BackgroundTransparency = 1
	buttonsContainer.Parent = popup

	local uiList = Instance.new("UIListLayout")
	uiList.Padding = UDim.new(0, 12)
	uiList.FillDirection = Enum.FillDirection.Vertical
	uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uiList.VerticalAlignment = Enum.VerticalAlignment.Top
	uiList.Parent = buttonsContainer

	-- Create a button per zone
	for _, z in ipairs(Zones) do
		local zBtn = Instance.new("TextButton")
		zBtn.Size = UDim2.new(0.6, 0, 0, 48)
		zBtn.BackgroundColor3 = Color3.fromRGB(60,60,70)
		zBtn.TextColor3 = Color3.fromRGB(255,255,255)
		zBtn.Text = z.name
		zBtn.Font = Enum.Font.SourceSansSemibold
		zBtn.TextScaled = true
		zBtn.Parent = buttonsContainer

		local zCorner = Instance.new("UICorner")
		zCorner.CornerRadius = UDim.new(0,8)
		zCorner.Parent = zBtn

		zBtn.MouseButton1Click:Connect(function()
			-- Fire server to teleport
			teleportEvent:FireServer(z.name)
			popup.Visible = false
		end)
	end

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -48, 0, 16)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(50,50,60)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
	closeBtn.Font = Enum.Font.SourceSansBold
	closeBtn.TextScaled = true
	closeBtn.Parent = popup

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0,8)
	closeCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		popup.Visible = false
	end)

	-- Ensure attribute exists (default enabled)
	if button:GetAttribute("Enabled") == nil then
		button:SetAttribute("Enabled", true)
	end

	button.MouseButton1Click:Connect(function()
		local enabled = button:GetAttribute("Enabled")
		if enabled == false then
			return
		end
		popup.Visible = not popup.Visible
	end)

	-- State watchers: InMainMenu, FlappyMode, DeathMenu
	local inMainMenu = LocalPlayer:FindFirstChild("InMainMenu")
	local flappyVal = nil
	local humanoid = nil

	local function updateButtonState()
		local inMenu = inMainMenu and inMainMenu.Value
		local flappy = flappyVal and flappyVal.Value
		local alive = humanoid and humanoid.Health > 0
		if inMenu or flappy or not alive then
			button.Visible = false
			button:SetAttribute("Enabled", false)
			popup.Visible = false
			return
		end
		button.Visible = true
		button:SetAttribute("Enabled", true)
		popup.Visible = false
	end

	-- Monitor InMainMenu
	if inMainMenu then
		inMainMenu.Changed:Connect(updateButtonState)
	end

	-- Monitor FlappyMode on character
	local function bindFlappyForCharacter(char)
		flappyVal = char:WaitForChild("FlappyMode", 10)
		if flappyVal and flappyVal:IsA("BoolValue") then
			flappyVal.Changed:Connect(updateButtonState)
		end
		humanoid = char:WaitForChild("Humanoid")
		humanoid.HealthChanged:Connect(updateButtonState)
		updateButtonState()
	end

	if LocalPlayer.Character then
		bindFlappyForCharacter(LocalPlayer.Character)
	end
	LocalPlayer.CharacterAdded:Connect(bindFlappyForCharacter)

	-- initial check
	updateButtonState()

	return screenGui
end

createMenuButton()
