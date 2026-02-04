local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Disable automatic respawning - players must click play/respawn button
Players.CharacterAutoLoads = false

-- Create RemoteEvents
local respawnEvent = Instance.new("RemoteEvent")
respawnEvent.Name = "RespawnEvent"
respawnEvent.Parent = ReplicatedStorage

local continueEvent = Instance.new("RemoteEvent")
continueEvent.Name = "ContinueEvent"
continueEvent.Parent = ReplicatedStorage

local playEvent = Instance.new("RemoteEvent")
playEvent.Name = "PlayEvent"
playEvent.Parent = ReplicatedStorage

local spectateEvent = Instance.new("RemoteEvent")
spectateEvent.Name = "SpectateEvent"
spectateEvent.Parent = ReplicatedStorage

-- Track which players have started playing
local playersPlaying = {}

-- Handle respawn requests from clients (after death)
respawnEvent.OnServerEvent:Connect(function(player)
	if player.Character then
		player.Character:Destroy()
	end
	player:LoadCharacter()
end)

-- Handle continue-from-stage requests
continueEvent.OnServerEvent:Connect(function(player, stageNum)
	-- Validate stage number
	if type(stageNum) ~= "number" or stageNum < 1 then
		-- Invalid, just do normal respawn
		if player.Character then
			player.Character:Destroy()
		end
		player:LoadCharacter()
		return
	end
	
	-- Find stage part with matching Value attribute
	local stagesFolder = workspace:FindFirstChild("Stages")
	local targetPart = nil
	
	if stagesFolder then
		for _, obj in ipairs(stagesFolder:GetDescendants()) do
			if obj:IsA("BasePart") then
				local v = obj:GetAttribute("Value")
				if v == stageNum then
					targetPart = obj
					break
				end
			end
		end
	end
	
	-- If no stage found, normal respawn
	if not targetPart then
		if player.Character then
			player.Character:Destroy()
		end
		player:LoadCharacter()
		return
	end
	
	-- Mark as continuing so checkpoint handler skips
	player:SetAttribute("IsContinuing", true)
	
	-- Set up listener BEFORE spawning to avoid race condition
	local conn
	conn = player.CharacterAdded:Connect(function(char)
		conn:Disconnect()
		
		local hrp = char:WaitForChild("HumanoidRootPart", 5)
		local humanoid = char:WaitForChild("Humanoid", 5)
		
		-- Wait a frame for spawn location to finish, then override position
		task.wait()
		
		if hrp then
			-- Position at stage X/Z, Y=6
			local targetCFrame = CFrame.new(targetPart.Position.X, 6, targetPart.Position.Z)
			hrp.CFrame = targetCFrame
			hrp.Anchored = true
			-- Zero velocity to prevent any drift
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end
		
		if humanoid then
			humanoid.PlatformStand = true
		end
		
		-- 3 second pause
		task.wait(3)
		
		-- Release player and enable flappy
		if hrp and hrp.Parent then
			hrp.Anchored = false
		end
		if humanoid and humanoid.Parent then
			humanoid.PlatformStand = false
		end
		
		-- Tell client to enable FlappyMode
		local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
		if eventsFolder then
			local flappyEv = eventsFolder:FindFirstChild("FlappyModeChanged")
			if flappyEv then
				flappyEv:FireClient(player, true)
			end
		end
		
		player:SetAttribute("IsContinuing", false)
	end)
	
	-- Now spawn the character (listener is ready)
	if player.Character then
		player.Character:Destroy()
	end
	player:LoadCharacter()
end)

-- Handle play button from main menu
playEvent.OnServerEvent:Connect(function(player)
	playersPlaying[player] = true
	if player.Character then
		player.Character:Destroy()
	end
	player:LoadCharacter()
end)

-- Handle spectate button from main menu (spawn but in spectate mode)
spectateEvent.OnServerEvent:Connect(function(player)
	playersPlaying[player] = true
	if not player.Character then
		player:LoadCharacter()
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	playersPlaying[player] = nil
end)

-- DON'T auto-spawn on join - wait for Play button
-- Players.PlayerAdded is not needed anymore since we wait for PlayEvent
