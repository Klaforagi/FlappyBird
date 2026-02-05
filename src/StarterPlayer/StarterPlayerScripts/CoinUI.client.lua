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

	-- Container (we'll size/position based on viewport)
	local coinContainer = Instance.new("Frame")
	coinContainer.Name = "CoinContainer"
	coinContainer.AnchorPoint = Vector2.new(0, 0)
	coinContainer.BackgroundTransparency = 1
	coinContainer.Parent = screenGui

	-- Top label centered above the bar
	local topLabel = Instance.new("TextLabel")
	topLabel.Name = "CoinsLabel"
	-- Anchor the top label so its bottom aligns to the container top (so it sits above)
	topLabel.AnchorPoint = Vector2.new(0.5, 1)
	topLabel.BackgroundTransparency = 1
	topLabel.Text = "Coins"
	topLabel.Font = Enum.Font.FredokaOne
	topLabel.TextScaled = false
	topLabel.TextColor3 = Color3.fromRGB(255,255,255)
	topLabel.Parent = coinContainer
	local topStroke = Instance.new("UIStroke")
	topStroke.Color = Color3.fromRGB(50,100,150)
	topStroke.Thickness = 2
	topStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	topStroke.Parent = topLabel

	-- Bar background
	local barBg = Instance.new("Frame")
	barBg.Name = "CoinBarBackground"
	-- anchor at top-left so positioning inside the left container is correct
	barBg.AnchorPoint = Vector2.new(0, 0)
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

	-- Numeric label inside/right of the bar
	local numberInBar = Instance.new("TextLabel")
	numberInBar.Name = "NumberInBar"
	numberInBar.BackgroundTransparency = 1
	numberInBar.Font = Enum.Font.FredokaOne
	numberInBar.TextScaled = false
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

	-- Responsive layout: sizes and positions based on viewport
	local function applyLayout()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
		local scale = math.clamp(vp.Y / 1080, 0.6, 1.5) * UI_SCALE

		-- Place coin UI on left side; width matches Spectate button (0.10 of screen)
		coinContainer.Size = UDim2.new(0.10, 0, 0.06, 0)
		-- Move the coin UI much lower on screen (around 80% down)
		coinContainer.Position = UDim2.new(0.02, 0, 0.55, 0)

		-- Top label centered above bar (position its bottom at container top, then nudge up)
		topLabel.Size = UDim2.new(0, math.floor(160 * scale), 0, math.floor(28 * scale))
		topLabel.Position = UDim2.new(0.5, 0, 0, -math.floor(8 * scale))
		topLabel.TextSize = math.max(12, math.floor(20 * scale))

		-- Bar fills the small container with a small downward offset
		barBg.Size = UDim2.new(1, 0, 1, 0)
		barBg.Position = UDim2.new(0, 0, 0, math.floor(-5 * scale))

		-- Numeric label centered in bar
		numberInBar.Size = UDim2.new(1, -8, 1, 0)
		numberInBar.Position = UDim2.new(0.5, 0, 0.5, 0)
		numberInBar.AnchorPoint = Vector2.new(0.5, 0.5)
		numberInBar.TextSize = math.max(12, math.floor(18 * scale))
		numberInBar.TextXAlignment = Enum.TextXAlignment.Center
		numberInBar.TextYAlignment = Enum.TextYAlignment.Center
	end

	local cam = workspace.CurrentCamera
	if cam then
		applyLayout()
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout)
	else
		task.delay(0.1, applyLayout)
	end

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
