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

	coinLabel = Instance.new("TextLabel")
	coinLabel.Name = "CoinLabel"
	coinLabel.Size = UDim2.new(0, 180, 0, 50)
	coinLabel.Position = UDim2.new(1, -190, 1, -70) -- Bottom right, moved up slightly
	coinLabel.AnchorPoint = Vector2.new(0, 0)
	coinLabel.BackgroundTransparency = 0
	coinLabel.BackgroundColor3 = Color3.fromRGB(100, 180, 255) -- Match button color
	coinLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Match button text
	coinLabel.Font = Enum.Font.FredokaOne -- Match button font
	coinLabel.TextScaled = true
	coinLabel.Text = "Coins: 0"
	coinLabel.Parent = screenGui

	local coinCorner = Instance.new("UICorner")
	coinCorner.CornerRadius = UDim.new(0.25, 0)
	coinCorner.Parent = coinLabel
	local coinStroke = Instance.new("UIStroke")
	coinStroke.Color = Color3.fromRGB(50, 100, 150)
	coinStroke.Thickness = 3
	coinStroke.Parent = coinLabel
	local coinTextStroke = Instance.new("UIStroke")
	coinTextStroke.Color = Color3.fromRGB(50, 100, 150)
	coinTextStroke.Thickness = 1.5
	coinTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	coinTextStroke.Parent = coinLabel
	local coinGradient = Instance.new("UIGradient")
	coinGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200))
	coinGradient.Rotation = 90
	coinGradient.Parent = coinLabel

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
	coinLabel.Text = "Coins: " .. tostring(amount)
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
