local player = game.Players.LocalPlayer
local musicFolder = workspace:WaitForChild("MusicPlaylist")
local songs = musicFolder:GetChildren()

-- Sort the songs by Name (alphabetical, e.g., 01_Song, 02_Song, ...)
table.sort(songs, function(a, b)
	return a.Name < b.Name
end)

local currentSong = nil
local songIndex = 1

local screenGui, pauseButton, skipButton, backButton, songLabel
local isPaused = false

-- Cache original volumes for each song
local originalVolumes = {}
for _, s in ipairs(songs) do
	originalVolumes[s] = s.Volume
end

local function updatePauseState()
	if pauseButton then
		pauseButton.Text = isPaused and "Play" or "Pause"
	end
	if currentSong then
		if isPaused then
			currentSong:Pause()
		else
			if currentSong.TimePosition > 0 and currentSong.TimePosition < currentSong.TimeLength then
				currentSong:Resume()
			else
				currentSong:Play()
			end
		end
	end
end

local function updateSongLabel()
	if songLabel then
		if currentSong then
			songLabel.Text = "Now Playing: " .. (currentSong.Name or "(Unknown Song)")
		else
			songLabel.Text = "Now Playing: (none)"
		end
	end
end

local function createGui()
	-- Destroy any existing GUI to avoid duplicates on respawn
	if screenGui and screenGui.Parent then
		screenGui:Destroy()
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MusicGui"
	screenGui.Parent = player:WaitForChild("PlayerGui")
	screenGui.IgnoreGuiInset = false -- Change to true if you want to ignore Roblox's top bar
	screenGui.Enabled = false -- Start hidden until menu closes
	
	-- Hide/show based on main menu state
	task.spawn(function()
		local inMainMenu = player:WaitForChild("InMainMenu", 10)
		if inMainMenu then
			screenGui.Enabled = not inMainMenu.Value
			inMainMenu.Changed:Connect(function()
				screenGui.Enabled = not inMainMenu.Value
			end)
		end
	end)

	pauseButton = Instance.new("TextButton")
	pauseButton.Name = "PauseButton"
	pauseButton.Size = UDim2.new(0.10, 0, 0.06, 0)       -- Smaller buttons
	pauseButton.Position = UDim2.new(0.02, 0, 0.18, 0)   -- Under song label
	pauseButton.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
	pauseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	pauseButton.Text = isPaused and "Play" or "Pause"
	pauseButton.Font = Enum.Font.FredokaOne
	pauseButton.TextScaled = true
	pauseButton.Parent = screenGui
	local pauseCorner = Instance.new("UICorner")
	pauseCorner.CornerRadius = UDim.new(0.25, 0)
	pauseCorner.Parent = pauseButton
	local pauseStroke = Instance.new("UIStroke")
	pauseStroke.Color = Color3.fromRGB(50, 100, 150)
	pauseStroke.Thickness = 3
	pauseStroke.Parent = pauseButton
	local pauseTextStroke = Instance.new("UIStroke")
	pauseTextStroke.Color = Color3.fromRGB(50, 100, 150)
	pauseTextStroke.Thickness = 1.5
	pauseTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	pauseTextStroke.Parent = pauseButton
	local pauseGradient = Instance.new("UIGradient")
	pauseGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200))
	pauseGradient.Rotation = 90
	pauseGradient.Parent = pauseButton

	backButton = Instance.new("TextButton")
	backButton.Name = "BackButton"
	backButton.Size = UDim2.new(0.05, 0, 0.06, 0)        -- Smaller
	backButton.Position = UDim2.new(0.13, 0, 0.18, 0)    -- After pause button
	backButton.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
	backButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	backButton.Text = "<<"
	backButton.Font = Enum.Font.FredokaOne
	backButton.TextScaled = true
	backButton.Parent = screenGui
	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0.25, 0)
	backCorner.Parent = backButton
	local backStroke = Instance.new("UIStroke")
	backStroke.Color = Color3.fromRGB(50, 100, 150)
	backStroke.Thickness = 3
	backStroke.Parent = backButton
	local backTextStroke = Instance.new("UIStroke")
	backTextStroke.Color = Color3.fromRGB(50, 100, 150)
	backTextStroke.Thickness = 1.5
	backTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	backTextStroke.Parent = backButton
	local backGradient = Instance.new("UIGradient")
	backGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200))
	backGradient.Rotation = 90
	backGradient.Parent = backButton

	skipButton = Instance.new("TextButton")
	skipButton.Name = "SkipButton"
	skipButton.Size = UDim2.new(0.05, 0, 0.06, 0)        -- Smaller
	skipButton.Position = UDim2.new(0.19, 0, 0.18, 0)    -- After back button
	skipButton.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
	skipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	skipButton.Text = ">>"
	skipButton.Font = Enum.Font.FredokaOne
	skipButton.TextScaled = true
	skipButton.Parent = screenGui
	local skipCorner = Instance.new("UICorner")
	skipCorner.CornerRadius = UDim.new(0.25, 0)
	skipCorner.Parent = skipButton
	local skipStroke = Instance.new("UIStroke")
	skipStroke.Color = Color3.fromRGB(50, 100, 150)
	skipStroke.Thickness = 3
	skipStroke.Parent = skipButton
	local skipTextStroke = Instance.new("UIStroke")
	skipTextStroke.Color = Color3.fromRGB(50, 100, 150)
	skipTextStroke.Thickness = 1.5
	skipTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	skipTextStroke.Parent = skipButton
	local skipGradient = Instance.new("UIGradient")
	skipGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200))
	skipGradient.Rotation = 90
	skipGradient.Parent = skipButton

	songLabel = Instance.new("TextLabel")
	songLabel.Name = "SongLabel"
	songLabel.Size = UDim2.new(0.30, 0, 0.05, 0)         
	songLabel.Position = UDim2.new(0.02, 0, 0.12, 0)      -- Top left, under Roblox UI
	songLabel.AnchorPoint = Vector2.new(0, 0)
	songLabel.BackgroundTransparency = 0.5
	songLabel.BackgroundColor3 = Color3.fromRGB(0,0,0)
	songLabel.TextColor3 = Color3.fromRGB(255,255,255)
	songLabel.Font = Enum.Font.SourceSansBold
	songLabel.TextSize = 24
	songLabel.Text = "Now Playing: (none)"
	songLabel.TextScaled = true
	songLabel.Parent = screenGui

	pauseButton.MouseButton1Click:Connect(function()
		isPaused = not isPaused
		updatePauseState()
	end)

	skipButton.MouseButton1Click:Connect(function()
		songIndex = songIndex + 1
		if songIndex > #songs then
			songIndex = 1
		end
		isPaused = false -- always play next song if skipped
		playNextSong()
	end)

	backButton.MouseButton1Click:Connect(function()
		songIndex = songIndex - 1
		if songIndex < 1 then
			songIndex = #songs
		end
		isPaused = false -- always play previous song if skipped back
		playNextSong()
	end)

	updatePauseState()
	updateSongLabel()
end

function playNextSong()
	if currentSong and currentSong.IsPlaying then
		currentSong:Stop()
	end
	currentSong = songs[songIndex]
	if currentSong then
		currentSong.TimePosition = 0
		updateSongLabel()
		updatePauseState()
		if not isPaused then
			currentSong:Play()
		end
		currentSong.Ended:Once(function()
			-- Move to next song automatically
			songIndex = songIndex + 1
			if songIndex > #songs then
				songIndex = 1
			end
			isPaused = false
			playNextSong()
		end)
	else
		if songLabel then
			songLabel.Text = "Now Playing: (none)"
		end
	end
end

-- Initial GUI setup
createGui()

-- Re-create GUI every time the player respawns
player.CharacterAdded:Connect(function()
	createGui()
end)

if #songs > 0 then
	playNextSong()
else
	if songLabel then
		songLabel.Text = "Now Playing: (no songs found)"
	end
end
