-- CoinUI.client.lua
-- Displays the player's coin count in the bottom right

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local coinEvent = ReplicatedStorage:WaitForChild("CoinUpdateEvent")
local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
local requestEvent = nil
if eventsFolder then
	requestEvent = eventsFolder:FindFirstChild("RequestCoinCount")
end

local screenGui
local coinLabel
-- UI scale multiplier for easy resizing
local UI_SCALE = 1.15

local function createGui()
	-- clean up existing if present
	if screenGui and screenGui.Parent then
		screenGui:Destroy()
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CoinGui"
	screenGui.ResetOnSpawn = false -- persist across character respawns
	screenGui.Parent = player:WaitForChild("PlayerGui")
	screenGui.Enabled = false -- Start hidden

	-- Container centered above the progress bar
		local coinContainer = Instance.new("Frame")
		coinContainer.Name = "CoinContainer"
		coinContainer.Size = UDim2.new(0, math.floor(200 * UI_SCALE), 0, math.floor(90 * UI_SCALE))
		local screenY = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize and workspace.CurrentCamera.ViewportSize.Y or 1080
		local downOffset = math.floor(screenY * 0.04 * UI_SCALE) -- ~4% down, scaled
		coinContainer.Position = UDim2.new(1, -math.floor(180 * UI_SCALE), 1, -math.floor(100 * UI_SCALE) + downOffset)
	coinContainer.AnchorPoint = Vector2.new(0, 0)
	coinContainer.BackgroundTransparency = 1
	coinContainer.Parent = screenGui

	-- Top label centered
	local topLabel = Instance.new("TextLabel")
	topLabel.Name = "CoinsLabel"
		topLabel.Size = UDim2.new(0, math.floor(160 * UI_SCALE), 0, math.floor(28 * UI_SCALE))
		topLabel.Position = UDim2.new(0.5, 0, 0, math.floor(6 * UI_SCALE))
	topLabel.AnchorPoint = Vector2.new(0.5, 0)
	topLabel.BackgroundTransparency = 1
	topLabel.Text = "Coins"
	topLabel.Font = Enum.Font.FredokaOne
	topLabel.TextScaled = true
	topLabel.TextColor3 = Color3.fromRGB(255,255,255)
	topLabel.Parent = coinContainer
		local topStroke = Instance.new("UIStroke")
		topStroke.Color = Color3.fromRGB(50,100,150)
		topStroke.Thickness = 2
		topStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		topStroke.Parent = topLabel

	-- Bar background (full-width visual)
	local barBg = Instance.new("Frame")
	barBg.Name = "CoinBarBackground"
		-- halve the bar width for a more compact look
		barBg.Size = UDim2.new(0, math.floor(100 * UI_SCALE), 0, math.floor(22 * UI_SCALE))
		barBg.Position = UDim2.new(0.5, 0, 0, math.floor(36 * UI_SCALE))
	barBg.AnchorPoint = Vector2.new(0.5, 0)
		barBg.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
	barBg.BorderSizePixel = 0
	barBg.Parent = coinContainer

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0,6)
	bgCorner.Parent = barBg

	local barStroke = Instance.new("UIStroke")
	barStroke.Color = Color3.fromRGB(50, 100, 150)
	barStroke.Thickness = 3
	barStroke.Parent = barBg

	local barGradient = Instance.new("UIGradient")
	barGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200))
	barGradient.Rotation = 90
	barGradient.Parent = barBg

	-- Number displayed centered inside the bar
	local numberInBar = Instance.new("TextLabel")
	numberInBar.Name = "NumberInBar"
	numberInBar.Size = UDim2.new(1, -8, 1, 0)
		numberInBar.Position = UDim2.new(0.5, 0, 0.5, 0)
		numberInBar.AnchorPoint = Vector2.new(0.5, 0.5)
		numberInBar.TextXAlignment = Enum.TextXAlignment.Center
		numberInBar.TextYAlignment = Enum.TextYAlignment.Center
	numberInBar.BackgroundTransparency = 1
	numberInBar.Font = Enum.Font.FredokaOne
	numberInBar.TextScaled = true
	numberInBar.TextColor3 = Color3.fromRGB(255,255,255)
	numberInBar.Text = "0"
	numberInBar.Parent = barBg

	local numStroke = Instance.new("UIStroke")
		numStroke.Color = Color3.fromRGB(50,100,150)
		numStroke.Thickness = 2
		numStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		numStroke.Parent = numberInBar

	-- Expose numberInBar for updates
	coinLabel = numberInBar

	-- Hide/show based on main menu state for this GUI
	task.spawn(function()
		local inMainMenu = player:FindFirstChild("InMainMenu") or player:WaitForChild("InMainMenu", 10)
		if inMainMenu then
			screenGui.Enabled = not inMainMenu.Value
			inMainMenu.Changed:Connect(function()
				screenGui.Enabled = not inMainMenu.Value
			end)
		end
	end)

	-- No ancestry watcher: we keep this GUI persistent across respawns
end

-- Create initial GUI
createGui()

-- Ensure UI persists across respawns: re-parent or recreate if removed
local function ensureGui()
	if not screenGui or not screenGui.Parent then
		createGui()
	else
		if screenGui.Parent ~= player:FindFirstChild("PlayerGui") then
			screenGui.Parent = player:WaitForChild("PlayerGui")
		end
	end
	-- request latest coins on respawn
	if requestEvent then
		requestEvent:FireServer()
	else
		local ev = ReplicatedStorage:FindFirstChild("Events")
		if ev then
			local req = ev:FindFirstChild("RequestCoinCount")
			if req then req:FireServer() end
		end
	end
end

player.CharacterAdded:Connect(function()
	-- Don't recreate/reparent the GUI on respawn; just request current coin count
	task.delay(0.1, function()
		if requestEvent then
			requestEvent:FireServer()
		else
			local ev = ReplicatedStorage:FindFirstChild("Events")
			if ev then
				local req = ev:FindFirstChild("RequestCoinCount")
				if req then req:FireServer() end
			end
		end
	end)
end)

-- (Ancestry watcher is attached inside createGui)

-- Update coin count
local function updateCoins(amount)
	if coinLabel then
		coinLabel.Text = tostring(amount)
	end
	print("[CoinUI] Updated coins to", amount)
end

coinEvent.OnClientEvent:Connect(function(amount)
	print("[CoinUI] Received CoinUpdateEvent ->", amount)
	updateCoins(amount)
end)

-- Request current coin count from server in case we missed initial event
task.spawn(function()
	if requestEvent then
		print("[CoinUI] Requesting current coin count from server")
		requestEvent:FireServer()
	else
		-- Try to find request event and fire if it appears shortly after
		local ev = ReplicatedStorage:WaitForChild("Events", 5)
		if ev then
			local req = ev:FindFirstChild("RequestCoinCount")
			if req then
				print("[CoinUI] Requesting current coin count (late)")
				req:FireServer()
			end
		end
	end
end)
