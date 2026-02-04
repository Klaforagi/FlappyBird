local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Wait for Events folder and PlaySound event
local eventsFolder = ReplicatedStorage:WaitForChild("Events")
local playEvent = eventsFolder:WaitForChild("PlaySound")

local function playSoundForLocal(soundName)
	local soundsFolder = ReplicatedStorage:FindFirstChild("Sounds")
	if not soundsFolder then return end
	local template = soundsFolder:FindFirstChild(soundName)
	if not template then return end
	-- Clone into PlayerGui so it plays only for this client
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local s = template:Clone()
	s.Parent = playerGui
	-- Ensure it's a Sound instance
	if s:IsA("Sound") then
		pcall(function()
			s:Play()
		end)
		-- Clean up after finished
		local con
		con = s.Ended:Connect(function()
			s:Destroy()
			con:Disconnect()
		end)
	else
		s:Destroy()
	end
end

playEvent.OnClientEvent:Connect(function(soundName)
	if type(soundName) ~= "string" then return end
	playSoundForLocal(soundName)
end)
