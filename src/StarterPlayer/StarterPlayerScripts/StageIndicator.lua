local player = game.Players.LocalPlayer

local stageGui = Instance.new("ScreenGui")
stageGui.Name = "StageGui"
stageGui.ResetOnSpawn = false
stageGui.Parent = player:WaitForChild("PlayerGui")

local stageLabel = Instance.new("TextLabel")
stageLabel.Name = "StageLabel"
stageLabel.AnchorPoint = Vector2.new(0.5, 0)
stageLabel.Position = UDim2.new(0.5, 0, 0, -40)
stageLabel.Size = UDim2.new(0, 80, 0, 60)
stageLabel.BackgroundTransparency = 1
stageLabel.TextColor3 = Color3.fromRGB(255,255,120)
stageLabel.Font = Enum.Font.FredokaOne
stageLabel.TextSize = 60
stageLabel.TextStrokeTransparency = 0.3
stageLabel.Text = "0"
stageLabel.Visible = false -- Start hidden!
stageLabel.Parent = stageGui

local function updateStageLabel()
	local stageValue = 0
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local stage = leaderstats:FindFirstChild("Stage")
		if stage then
			stageValue = stage.Value
		end
	end
	stageLabel.Text = tostring(stageValue)
end

local function setupStageTracking()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		player.ChildAdded:Wait()
		leaderstats = player:FindFirstChild("leaderstats")
	end

	local stage = leaderstats and leaderstats:FindFirstChild("Stage")
	if stage then
		stage.Changed:Connect(updateStageLabel)
		updateStageLabel()
	end
end

-- === NEW: Track FlappyMode for visibility ===
local function setupFlappyModeWatcher()
	local function updateVisibility()
		local char = player.Character
		if char then
			local flappy = char:FindFirstChild("FlappyMode")
			if flappy and flappy.Value then
				stageLabel.Visible = true
			else
				stageLabel.Visible = false
			end
		else
			stageLabel.Visible = false
		end
	end

	-- Set up watcher when character is added
	player.CharacterAdded:Connect(function(char)
		local function connectFlappy()
			local flappy = char:FindFirstChild("FlappyMode")
			if flappy then
				flappy.Changed:Connect(updateVisibility)
				updateVisibility()
			else
				-- Wait for FlappyMode to appear if it's added after character loads
				char.ChildAdded:Connect(function(child)
					if child.Name == "FlappyMode" then
						child.Changed:Connect(updateVisibility)
						updateVisibility()
					end
				end)
			end
		end
		connectFlappy()
	end)

	-- Also call now for current character, if present
	if player.Character then
		local char = player.Character
		local flappy = char:FindFirstChild("FlappyMode")
		if flappy then
			flappy.Changed:Connect(updateVisibility)
			updateVisibility()
		end
	end
end

setupStageTracking()
setupFlappyModeWatcher()

player.ChildAdded:Connect(function(child)
	if child.Name == "leaderstats" then
		setupStageTracking()
	end
end)
