local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RespawnEvent = ReplicatedStorage:WaitForChild("RespawnEvent")

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
	
	-- Respawn button
	local respawnButton = Instance.new("TextButton")
	respawnButton.Name = "RespawnButton"
	respawnButton.Size = UDim2.new(0.6, 0, 0.25, 0)
	respawnButton.Position = UDim2.new(0.5, 0, 0.65, 0)
	respawnButton.AnchorPoint = Vector2.new(0.5, 0)
	respawnButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	respawnButton.BorderSizePixel = 0
	respawnButton.Text = "Respawn"
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
	
	screenGui.Parent = PlayerGui
	return screenGui
end

-- Show death menu with stage info
local function showDeathMenu(stageValue)
	local deathMenu = PlayerGui:FindFirstChild("DeathMenu")
	if not deathMenu then
		deathMenu = createDeathMenu()
	end
	
	local stageLabel = deathMenu:FindFirstChild("MenuFrame"):FindFirstChild("StageLabel")
	if stageLabel then
		stageLabel.Text = "You reached Stage " .. tostring(stageValue)
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
