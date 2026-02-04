local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RespawnEvent = ReplicatedStorage:WaitForChild("RespawnEvent")
local ContinueEvent = ReplicatedStorage:WaitForChild("ContinueEvent")
local ContinueResponse = ReplicatedStorage:FindFirstChild("ContinueResponse")

-- Stage name mapping for continue menu (add more entries here as needed)
local StageNameMap = {
	{min = 0, max = 49, name = "Green Meadows"},
	{min = 50, max = 99, name = "Sunny Beach"},
	{min = 100, max = 149, name = "Sakura Fields"},
}

local function getStageName(stage)
	for _, entry in ipairs(StageNameMap) do
		if stage >= entry.min and stage <= entry.max then
			return entry.name
		end
	end
	return "Unknown"
end

-- Store stage at death for continue button
local deathStage = 0

-- Create the death menu UI
local function createDeathMenu()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DeathMenu"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	
	-- Main menu container (no overlay, just centered box)
	local menuFrame = Instance.new("Frame")
	menuFrame.Name = "MenuFrame"
	menuFrame.Size = UDim2.new(0.35, 0, 0.35, 0)
	menuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	menuFrame.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
	menuFrame.BorderSizePixel = 0
	menuFrame.Parent = screenGui
	local menuCorner = Instance.new("UICorner")
	menuCorner.CornerRadius = UDim.new(0.08, 0)
	menuCorner.Parent = menuFrame
	local menuStroke = Instance.new("UIStroke")
	menuStroke.Color = Color3.fromRGB(255, 255, 255)
	menuStroke.Thickness = 3
	menuStroke.Transparency = 0.2
	menuStroke.Parent = menuFrame
	local menuGradient = Instance.new("UIGradient")
	menuGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200))
	menuGradient.Rotation = 90
	menuGradient.Parent = menuFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.3, 0)
	title.Position = UDim2.new(0, 0, 0.05, 0)
	title.BackgroundTransparency = 1
	title.Text = "YOU DIED"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.Parent = menuFrame
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(50, 100, 150)
	titleStroke.Thickness = 2
	titleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	titleStroke.Parent = title
	
	-- Stage text
	local stageLabel = Instance.new("TextLabel")
	stageLabel.Name = "StageLabel"
	stageLabel.Size = UDim2.new(1, 0, 0.2, 0)
	stageLabel.Position = UDim2.new(0, 0, 0.35, 0)
	stageLabel.BackgroundTransparency = 1
	stageLabel.Text = "You reached Stage 0"
	stageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	stageLabel.Font = Enum.Font.FredokaOne
	stageLabel.TextScaled = true
	stageLabel.Parent = menuFrame
	local stageStroke = Instance.new("UIStroke")
	stageStroke.Color = Color3.fromRGB(50, 100, 150)
	stageStroke.Thickness = 1
	stageStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stageStroke.Parent = stageLabel
	
	-- Respawn button (left side)
	local respawnButton = Instance.new("TextButton")
	respawnButton.Name = "RespawnButton"
	respawnButton.Size = UDim2.new(0.35, 0, 0.25, 0)
	respawnButton.Position = UDim2.new(0.27, 0, 0.65, 0)
	respawnButton.AnchorPoint = Vector2.new(0.5, 0)
	respawnButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	respawnButton.BorderSizePixel = 0
	respawnButton.Text = "Respawn"
	respawnButton.Text = "Restart"
	respawnButton.TextColor3 = Color3.fromRGB(100, 180, 255)
	respawnButton.Font = Enum.Font.FredokaOne
	respawnButton.TextScaled = true
	respawnButton.Parent = menuFrame
	local respawnCorner = Instance.new("UICorner")
	respawnCorner.CornerRadius = UDim.new(0.25, 0)
	respawnCorner.Parent = respawnButton
	local respawnStroke = Instance.new("UIStroke")
	respawnStroke.Color = Color3.fromRGB(50, 100, 150)
	respawnStroke.Thickness = 3
	respawnStroke.Parent = respawnButton
	local respawnTextStroke = Instance.new("UIStroke")
	respawnTextStroke.Color = Color3.fromRGB(50, 100, 150)
	respawnTextStroke.Thickness = 1.5
	respawnTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	respawnTextStroke.Parent = respawnButton
	local respawnGradient = Instance.new("UIGradient")
	respawnGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(220, 220, 220))
	respawnGradient.Rotation = 90
	respawnGradient.Parent = respawnButton
	
	-- Respawn functionality
	respawnButton.MouseButton1Click:Connect(function()
		screenGui.Enabled = false
		RespawnEvent:FireServer()
	end)
	
	-- Continue button (right side)
	local continueButton = Instance.new("TextButton")
	continueButton.Name = "ContinueButton"
	continueButton.Size = UDim2.new(0.35, 0, 0.25, 0)
	continueButton.Position = UDim2.new(0.73, 0, 0.65, 0)
	continueButton.AnchorPoint = Vector2.new(0.5, 0)
	continueButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	continueButton.BorderSizePixel = 0
	continueButton.Text = "Continue"
	continueButton.TextColor3 = Color3.fromRGB(100, 180, 255)
	continueButton.Font = Enum.Font.FredokaOne
	continueButton.TextScaled = true
	continueButton.Parent = menuFrame
	local continueCorner = Instance.new("UICorner")
	continueCorner.CornerRadius = UDim.new(0.25, 0)
	continueCorner.Parent = continueButton
	local continueStroke = Instance.new("UIStroke")
	continueStroke.Color = Color3.fromRGB(50, 100, 150)
	continueStroke.Thickness = 3
	continueStroke.Parent = continueButton

	-- Cost label shown under Continue button
	local costLabel = Instance.new("TextLabel")
	costLabel.Name = "ContinueCostLabel"
	costLabel.Size = UDim2.new(0.35, 0, 0.08, 0)
	costLabel.Position = UDim2.new(0.73, 0, 0.92, 0)
	costLabel.AnchorPoint = Vector2.new(0.5, 0)
	costLabel.BackgroundTransparency = 1
	costLabel.Text = "20 coins"
	costLabel.TextColor3 = Color3.fromRGB(255, 223, 0)
	costLabel.Font = Enum.Font.FredokaOne
	costLabel.TextScaled = true
	costLabel.Parent = menuFrame

	-- Stage name label under Restart (left) button, white text
	local stageNameLabel = Instance.new("TextLabel")
	stageNameLabel.Name = "StageNameLabel"
	stageNameLabel.Size = UDim2.new(0.35, 0, 0.08, 0)
	stageNameLabel.Position = UDim2.new(0.27, 0, 0.92, 0)
	stageNameLabel.AnchorPoint = Vector2.new(0.5, 0)
	stageNameLabel.BackgroundTransparency = 1
	stageNameLabel.Text = "Green Meadows"
	stageNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	stageNameLabel.Font = Enum.Font.FredokaOne
	stageNameLabel.TextScaled = true
	stageNameLabel.Parent = menuFrame
	
	-- Continue functionality
	continueButton.MouseButton1Click:Connect(function()
		-- Prevent double clicks
		continueButton.Active = false
		continueButton.AutoButtonColor = false

		-- Check local coin UI to optimistically hide the death menu if player appears to have >= 20 coins
		local didHideEarly = false
		local coinGui = PlayerGui:FindFirstChild("CoinGui")
		if coinGui then
			local container = coinGui:FindFirstChild("CoinContainer")
			local numLabel = container and container:FindFirstChild("CoinBarBackground") and container.CoinBarBackground:FindFirstChild("NumberInBar")
			local coinCount = numLabel and tonumber(numLabel.Text)
			if coinCount and coinCount >= 20 then
				didHideEarly = true
				local deathMenuGui = PlayerGui:FindFirstChild("DeathMenu")
				if deathMenuGui then
					deathMenuGui.Enabled = false
				end
			end
		end

		-- Temporary listener for server response
		local conn
		conn = ContinueResponse and ContinueResponse.OnClientEvent:Connect(function(accepted)
			if conn then conn:Disconnect() end
			continueButton.Active = true
			continueButton.AutoButtonColor = true
			if accepted then
				-- Show local 3-second countdown UI
				local existing = PlayerGui:FindFirstChild("ContinueCountdownGui")
				if existing then existing:Destroy() end

				local countdownGui = Instance.new("ScreenGui")
				countdownGui.Name = "ContinueCountdownGui"
				countdownGui.ResetOnSpawn = false
				countdownGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
				countdownGui.Parent = PlayerGui

				local label = Instance.new("TextLabel")
				label.Name = "CountdownLabel"
				label.Size = UDim2.new(0.4, 0, 0.18, 0)
				label.Position = UDim2.new(0.5, 0, 0.5, 0)
				label.AnchorPoint = Vector2.new(0.5, 0.5)
				label.BackgroundTransparency = 0.4
				label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				label.TextColor3 = Color3.fromRGB(255, 255, 255)
				label.Font = Enum.Font.FredokaOne
				label.TextScaled = true
				label.Parent = countdownGui

				for i = 3, 1, -1 do
					label.Text = "Continuing in " .. tostring(i) .. "..."
					task.wait(1)
				end

				countdownGui:Destroy()
				-- if we didn't hide early, hide now
				if not didHideEarly then
					local deathMenuGui = PlayerGui:FindFirstChild("DeathMenu")
					if deathMenuGui then deathMenuGui.Enabled = false end
				end
			else
				-- Server rejected (likely insufficient coins). If we hid the menu early, re-show it.
				if didHideEarly then
					local deathMenuGui = PlayerGui:FindFirstChild("DeathMenu")
					if deathMenuGui then deathMenuGui.Enabled = true end
				end
				-- Show feedback for insufficient coins
				local notice = Instance.new("TextLabel")
				notice.Size = UDim2.new(0.6,0,0.15,0)
				notice.Position = UDim2.new(0.5,0,0.5,0)
				notice.AnchorPoint = Vector2.new(0.5,0.5)
				notice.BackgroundTransparency = 0.4
				notice.BackgroundColor3 = Color3.fromRGB(0,0,0)
				notice.TextColor3 = Color3.fromRGB(255,0,0)
				notice.Font = Enum.Font.FredokaOne
				notice.TextScaled = true
				notice.Text = "Not enough coins"
				notice.Parent = PlayerGui
				task.delay(2, function()
					if notice then notice:Destroy() end
				end)
			end
		end)

		-- Fire server to request continue/resume at stage
		ContinueEvent:FireServer(deathStage)
	end)
	
	screenGui.Parent = PlayerGui
	return screenGui
end

-- Show death menu with stage info
local function showDeathMenu(stageValue)
	deathStage = stageValue  -- Store for continue button
	
	local deathMenu = PlayerGui:FindFirstChild("DeathMenu")
	if not deathMenu then
		deathMenu = createDeathMenu()
	end
	
	local stageLabel = deathMenu:FindFirstChild("MenuFrame"):FindFirstChild("StageLabel")
	if stageLabel then
		stageLabel.Text = "You reached Stage " .. tostring(stageValue)
	end

	-- Update and show stage name based on the mapping
	local nameLabel = deathMenu:FindFirstChild("MenuFrame"):FindFirstChild("StageNameLabel")
	if nameLabel then
		nameLabel.Text = getStageName(stageValue)
	end

	deathMenu.Enabled = true
end

-- Setup death detection
local function setupCharacter(char)
	local humanoid = char:WaitForChild("Humanoid")
	
	humanoid.Died:Connect(function()
		local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
		local stage = leaderstats and leaderstats:FindFirstChild("Stage")
		local stageValue = stage and stage.Value or 0
		
		-- Small delay to let death animation play
		task.wait(0.5)
		showDeathMenu(stageValue)
	end)
end

-- Initialize for current and future characters
if LocalPlayer.Character then
	setupCharacter(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(setupCharacter)
