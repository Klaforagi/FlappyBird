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

	pauseButton = Instance.new("TextButton")
	pauseButton.Name = "PauseButton"
	pauseButton.Size = UDim2.new(0.13, 0, 0.08, 0)       -- 13% width, 8% height
	pauseButton.Position = UDim2.new(0.02, 0, 0.70, 0)   -- 2% from left, 4% from top
	pauseButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
	pauseButton.TextColor3 = Color3.fromRGB(255,255,255)
	pauseButton.Text = isPaused and "Play" or "Pause"
	pauseButton.Font = Enum.Font.SourceSansBold
	pauseButton.TextScaled = true
	pauseButton.Parent = screenGui

	backButton = Instance.new("TextButton")
	backButton.Name = "BackButton"
	backButton.Size = UDim2.new(0.07, 0, 0.08, 0)        -- 7% width, 8% height
	backButton.Position = UDim2.new(0.17, 0, 0.70, 0)    -- after pause button
	backButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
	backButton.TextColor3 = Color3.fromRGB(255,255,255)
	backButton.Text = "<<"
	backButton.Font = Enum.Font.SourceSansBold
	backButton.TextScaled = true
	backButton.Parent = screenGui

	skipButton = Instance.new("TextButton")
	skipButton.Name = "SkipButton"
	skipButton.Size = UDim2.new(0.07, 0, 0.08, 0)        -- 7% width, 8% height
	skipButton.Position = UDim2.new(0.25, 0, 0.70, 0)    -- after back button
	skipButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
	skipButton.TextColor3 = Color3.fromRGB(255,255,255)
	skipButton.Text = ">>"
	skipButton.Font = Enum.Font.SourceSansBold
	skipButton.TextScaled = true
	skipButton.Parent = screenGui

	songLabel = Instance.new("TextLabel")
	songLabel.Name = "SongLabel"
	songLabel.Size = UDim2.new(0.36, 0, 0.07, 0)         
	songLabel.Position = UDim2.new(0.20, 0, 0.80, 0)      
	songLabel.AnchorPoint = Vector2.new(0.5, 0)
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
