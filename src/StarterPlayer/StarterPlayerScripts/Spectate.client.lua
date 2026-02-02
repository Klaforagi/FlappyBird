local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local spectating = false
local spectateIndex = 1
local spectateConn
local flappyMode
local spectateTarget = nil

-- Create a BindableEvent to signal other scripts that we're spectating
local spectatingValue = Instance.new("BoolValue")
spectatingValue.Name = "IsSpectating"
spectatingValue.Value = false
spectatingValue.Parent = LocalPlayer

-- UI Setup
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local spectateGui = Instance.new("ScreenGui")
spectateGui.Name = "SpectateGui"
spectateGui.ResetOnSpawn = false
spectateGui.Enabled = false -- Start hidden until menu closes
spectateGui.Parent = playerGui

-- Hide/show based on main menu state
task.spawn(function()
	local inMainMenu = LocalPlayer:WaitForChild("InMainMenu", 10)
	if inMainMenu then
		spectateGui.Enabled = not inMainMenu.Value
		inMainMenu.Changed:Connect(function()
			spectateGui.Enabled = not inMainMenu.Value
		end)
	end
end)

-- Menu button - positioned above spectate button
local menuButton = Instance.new("TextButton")
menuButton.Name = "MenuButton"
menuButton.Size = UDim2.new(0.13, 0, 0.08, 0)
menuButton.Position = UDim2.new(0.02, 0, 0.50, 0)
menuButton.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
menuButton.TextColor3 = Color3.fromRGB(255, 255, 255)
menuButton.Text = "Menu"
menuButton.Font = Enum.Font.FredokaOne
menuButton.TextScaled = true
menuButton.Parent = spectateGui
local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0.25, 0)
menuCorner.Parent = menuButton
local menuStroke = Instance.new("UIStroke")
menuStroke.Color = Color3.fromRGB(50, 100, 150)
menuStroke.Thickness = 3
menuStroke.Parent = menuButton
local menuTextStroke = Instance.new("UIStroke")
menuTextStroke.Color = Color3.fromRGB(50, 100, 150)
menuTextStroke.Thickness = 1.5
menuTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
menuTextStroke.Parent = menuButton
local menuGradient = Instance.new("UIGradient")
menuGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200))
menuGradient.Rotation = 90
menuGradient.Parent = menuButton

-- Menu button click handler
menuButton.MouseButton1Click:Connect(function()
	local showMenuEvent = LocalPlayer:FindFirstChild("ShowMainMenu")
	if showMenuEvent then
		showMenuEvent:Fire()
	end
end)

-- Spectate button - positioned above pause button (pause is at 0.02, 0.70)
local spectateButton = Instance.new("TextButton")
spectateButton.Name = "SpectateButton"
spectateButton.Size = UDim2.new(0.13, 0, 0.08, 0)
spectateButton.Position = UDim2.new(0.02, 0, 0.60, 0)
spectateButton.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
spectateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
spectateButton.Text = "Spectate"
spectateButton.Font = Enum.Font.FredokaOne
spectateButton.TextScaled = true
spectateButton.Parent = spectateGui
local spectateCorner = Instance.new("UICorner")
spectateCorner.CornerRadius = UDim.new(0.25, 0)
spectateCorner.Parent = spectateButton
local spectateStroke = Instance.new("UIStroke")
spectateStroke.Color = Color3.fromRGB(50, 100, 150)
spectateStroke.Thickness = 3
spectateStroke.Parent = spectateButton
local spectateTextStroke = Instance.new("UIStroke")
spectateTextStroke.Color = Color3.fromRGB(50, 100, 150)
spectateTextStroke.Thickness = 1.5
spectateTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
spectateTextStroke.Parent = spectateButton
local spectateGradient = Instance.new("UIGradient")
spectateGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200))
spectateGradient.Rotation = 90
spectateGradient.Parent = spectateButton

-- Container for bottom spectate info (centered)
local bottomContainer = Instance.new("Frame")
bottomContainer.Name = "BottomContainer"
bottomContainer.Size = UDim2.new(0.5, 0, 0.06, 0)
bottomContainer.Position = UDim2.new(0.5, 0, 0.92, 0)
bottomContainer.AnchorPoint = Vector2.new(0.5, 0.5)
bottomContainer.BackgroundTransparency = 1
bottomContainer.Visible = false
bottomContainer.Parent = spectateGui

-- Left arrow
local leftArrow = Instance.new("TextButton")
leftArrow.Name = "LeftArrow"
leftArrow.Size = UDim2.new(0.12, 0, 1, 0)
leftArrow.Position = UDim2.new(0, 0, 0, 0)
leftArrow.Text = "<"
leftArrow.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
leftArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
leftArrow.Font = Enum.Font.FredokaOne
leftArrow.TextScaled = true
leftArrow.Parent = bottomContainer
local leftCorner = Instance.new("UICorner")
leftCorner.CornerRadius = UDim.new(0.25, 0)
leftCorner.Parent = leftArrow
local leftStroke = Instance.new("UIStroke")
leftStroke.Color = Color3.fromRGB(50, 100, 150)
leftStroke.Thickness = 3
leftStroke.Parent = leftArrow
local leftTextStroke = Instance.new("UIStroke")
leftTextStroke.Color = Color3.fromRGB(50, 100, 150)
leftTextStroke.Thickness = 1.5
leftTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
leftTextStroke.Parent = leftArrow
local leftGradient = Instance.new("UIGradient")
leftGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200))
leftGradient.Rotation = 90
leftGradient.Parent = leftArrow

-- Name label at center
local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "SpectateNameLabel"
nameLabel.Size = UDim2.new(0.76, 0, 1, 0)
nameLabel.Position = UDim2.new(0.12, 0, 0, 0)
nameLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
nameLabel.BackgroundTransparency = 0.5
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.Font = Enum.Font.SourceSansBold
nameLabel.TextScaled = true
nameLabel.Text = ""
nameLabel.Parent = bottomContainer

-- Right arrow
local rightArrow = Instance.new("TextButton")
rightArrow.Name = "RightArrow"
rightArrow.Size = UDim2.new(0.12, 0, 1, 0)
rightArrow.Position = UDim2.new(0.88, 0, 0, 0)
rightArrow.Text = ">"
rightArrow.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
rightArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
rightArrow.Font = Enum.Font.FredokaOne
rightArrow.TextScaled = true
rightArrow.Parent = bottomContainer
local rightCorner = Instance.new("UICorner")
rightCorner.CornerRadius = UDim.new(0.25, 0)
rightCorner.Parent = rightArrow
local rightStroke = Instance.new("UIStroke")
rightStroke.Color = Color3.fromRGB(50, 100, 150)
rightStroke.Thickness = 3
rightStroke.Parent = rightArrow
local rightTextStroke = Instance.new("UIStroke")
rightTextStroke.Color = Color3.fromRGB(50, 100, 150)
rightTextStroke.Thickness = 1.5
rightTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
rightTextStroke.Parent = rightArrow
local rightGradient = Instance.new("UIGradient")
rightGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200))
rightGradient.Rotation = 90
rightGradient.Parent = rightArrow

-- Helper: get all players with characters (excluding self)
local function getSpectatablePlayers()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(list, p)
		end
	end
	return list
end

local function updateNameLabel()
	if spectateTarget then
		nameLabel.Text = "Spectating: " .. spectateTarget.Name
		bottomContainer.Visible = true
	else
		nameLabel.Text = ""
		bottomContainer.Visible = false
	end
end

local function startSpectate()
	local spectateList = getSpectatablePlayers()
	if #spectateList == 0 then
		nameLabel.Text = "No players to spectate"
		bottomContainer.Visible = true
		return
	end
	
	if spectateIndex < 1 then spectateIndex = #spectateList end
	if spectateIndex > #spectateList then spectateIndex = 1 end
	
	spectateTarget = spectateList[spectateIndex]
	if not spectateTarget then return end

	updateNameLabel()
	spectatingValue.Value = true

	if spectateConn then spectateConn:Disconnect() end

	-- Use a high priority to override other camera scripts
	spectateConn = RunService:BindToRenderStep("SpectateCamera", Enum.RenderPriority.Camera.Value + 1, function()
		if spectateTarget and spectateTarget.Character and spectateTarget.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = spectateTarget.Character.HumanoidRootPart
			workspace.CurrentCamera.CFrame = CFrame.new(
				Vector3.new(hrp.Position.X, 5, hrp.Position.Z + 35),
				Vector3.new(hrp.Position.X + 0.1, 5, hrp.Position.Z)
			)
		end
	end)
end

local function stopSpectate()
	if spectateConn then
		RunService:UnbindFromRenderStep("SpectateCamera")
		spectateConn = nil
	end
	spectateTarget = nil
	spectatingValue.Value = false
	updateNameLabel()
end

spectateButton.MouseButton1Click:Connect(function()
	-- Only allow spectating when NOT in FlappyMode
	if flappyMode and flappyMode.Value then
		return
	end
	
	if not spectating then
		local list = getSpectatablePlayers()
		if #list == 0 then
			nameLabel.Text = "No players to spectate"
			bottomContainer.Visible = true
			task.delay(2, function()
				if not spectating then
					bottomContainer.Visible = false
				end
			end)
			return
		end
		spectating = true
		-- Disable player movement
		local char = LocalPlayer.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 0
				humanoid.JumpPower = 0
			end
		end
		startSpectate()
	else
		spectating = false
		stopSpectate()
		-- Re-enable player movement
		local char = LocalPlayer.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 16
				humanoid.JumpPower = 50
			end
		end
	end
end)

leftArrow.MouseButton1Click:Connect(function()
	if not spectating then return end
	local list = getSpectatablePlayers()
	if #list == 0 then return end
	spectateIndex = spectateIndex - 1
	if spectateIndex < 1 then spectateIndex = #list end
	startSpectate()
end)

rightArrow.MouseButton1Click:Connect(function()
	if not spectating then return end
	local list = getSpectatablePlayers()
	if #list == 0 then return end
	spectateIndex = spectateIndex + 1
	if spectateIndex > #list then spectateIndex = 1 end
	startSpectate()
end)

-- Update UI visibility based on FlappyMode
local function updateSpectateUI()
	if flappyMode and flappyMode.Value then
		-- In FlappyMode - hide spectate button and stop spectating
		spectateButton.Visible = false
		if spectating then
			spectating = false
			stopSpectate()
			-- Re-enable player movement
			local char = LocalPlayer.Character
			if char then
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = 16
					humanoid.JumpPower = 50
				end
			end
		end
		bottomContainer.Visible = false
	else
		-- Not in FlappyMode - show spectate button
		spectateButton.Visible = true
		if spectating then
			updateNameLabel()
		end
	end
end

-- Wait for FlappyMode to exist
local function setupFlappyModeListener()
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	flappyMode = char:WaitForChild("FlappyMode", 10)
	if flappyMode then
		flappyMode.Changed:Connect(updateSpectateUI)
		updateSpectateUI()
	else
		spectateButton.Visible = true
	end
end

setupFlappyModeListener()

-- Handle respawn
LocalPlayer.CharacterAdded:Connect(function()
	-- Stop spectating on respawn
	if spectating then
		spectating = false
		stopSpectate()
	end
	setupFlappyModeListener()
end)

-- Handle target player leaving
Players.PlayerRemoving:Connect(function(p)
	if spectating and spectateTarget == p then
		local list = getSpectatablePlayers()
		if #list > 0 then
			spectateIndex = 1
			startSpectate()
		else
			spectating = false
			stopSpectate()
			-- Re-enable player movement
			local char = LocalPlayer.Character
			if char then
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = 16
					humanoid.JumpPower = 50
				end
			end
		end
	end
end)
