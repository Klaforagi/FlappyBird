--SETTINGS
--The button settings should be the name of a button. See the KeyCode enum for valid names.
--If you don't want a key for it, put nil instead of a string with the name.
--The default speed should be a number.

--The button that moves the player up.
local UpButton = "Space"
--The button that moves the player down.
local DownButton = "LeftControl"

--The button that speeds the player up.
local SpeedUpButton = "E"
--The button that slows the player down.
local SpeedDownButton = "Q"

--The speed by default.
local DefaultSpeed = 120



--SCRIPT (made by funwolf7)
--It is not recommended to modify anything past this point unless you know what you are doing.

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = game.Players.LocalPlayer
local PlayerScripts = Player:FindFirstChild("PlayerScripts") or Player:WaitForChild("PlayerScripts")
local PlayerModule = nil
-- require PlayerModule robustly (works when this LocalScript lives in StarterPack)
do
	local mod = PlayerScripts:FindFirstChild("PlayerModule") or PlayerScripts:WaitForChild("PlayerModule")
	PlayerModule = require(mod)
end
local ControlModule = PlayerModule:GetControls()

local Equipped = false

local Speed = type(DefaultSpeed) and DefaultSpeed or 50

local Connection

local _boundUp = false
local _boundDown = false
local _firstHeartbeat = false

-- Dev-only availability: destroy tool/script if player not listed in ReplicatedStorage.DevList
local function isDeveloper()
	local mod = ReplicatedStorage:FindFirstChild("DevList") or ReplicatedStorage:FindFirstChild("DevConfig")
	if mod and mod:IsA("ModuleScript") then
		local ok, list = pcall(require, mod)
		if ok and type(list) == "table" then
			for _, id in ipairs(list) do
				if id == Player.UserId then
					return true
				end
			end
		end
	end



    -- Only allow developers listed in the DevList ModuleScript
	return false
end

if not isDeveloper() then
	if script.Parent and script.Parent:IsA("Tool") then
		script.Parent:Destroy()
	else
		script:Destroy()
	end
	return
end

-- Find tool by name and set up handlers. The tool's name is expected to be "Noclip".
local TOOL_NAME = "Noclip"
local tool = nil

local function handleEquipped()
	Equipped = true
	_firstHeartbeat = true
	print("[Noclip] equipped for", Player.Name)
	Connection = RunService.Heartbeat:Connect(function(Step)
		local Character = Player.Character
		if Character then
			local Humanoid = Character:FindFirstChild("Humanoid")
			local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
			local Camera = workspace.CurrentCamera

			if Humanoid then
				Humanoid.PlatformStand = true
			end

			if HumanoidRootPart then
				HumanoidRootPart.Anchored = true
				HumanoidRootPart.Velocity = Vector3.new()

				if Camera then
					local MoveAmount = ControlModule:GetMoveVector() or Vector3.new()

					if not UserInputService:GetFocusedTextBox() then
						if UpButton and type(UpButton) == "string" and Enum.KeyCode[UpButton] then
							if UserInputService:IsKeyDown(Enum.KeyCode[UpButton]) then
								MoveAmount = Vector3.new(MoveAmount.X,1,MoveAmount.Z)
							end
						end
						if DownButton and type(DownButton) == "string" and Enum.KeyCode[DownButton] then
							if UserInputService:IsKeyDown(Enum.KeyCode[DownButton]) then
								MoveAmount = Vector3.new(MoveAmount.X,MoveAmount.Y - 1,MoveAmount.Z)
							end
						end
					end

					MoveAmount = MoveAmount.Magnitude > 1 and MoveAmount.Unit or MoveAmount
					MoveAmount = MoveAmount * Step * Speed

					if _firstHeartbeat then
						print("[Noclip] heartbeat for", Player.Name, "MoveAmount", MoveAmount, "Speed", Speed)
						_firstHeartbeat = false
					end

					HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position,HumanoidRootPart.Position + Camera.CFrame.LookVector) * CFrame.new(MoveAmount)
				end
			end
		end
	end)
end

local function handleUnequipped()
	Equipped = false
	local Character = Player.Character
	if Character then
		local Humanoid = Character:FindFirstChild("Humanoid")
		local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

		if Humanoid then
			Humanoid.PlatformStand = false
		end

		if HumanoidRootPart then
			HumanoidRootPart.Anchored = false
		end
	end
	if Connection then
		Connection:Disconnect()
		Connection = nil
	end
	-- Unbind speed actions if we bound them
	if _boundUp then
		pcall(function() ContextActionService:UnbindAction("NoclipSpeedUp") end)
		_boundUp = false
	end
	if _boundDown then
		pcall(function() ContextActionService:UnbindAction("NoclipSpeedDown") end)
		_boundDown = false
	end
	print("[Noclip] unequipped for", Player.Name)
end


local function OnPress(Name, State, Object)
	if not UserInputService:GetFocusedTextBox() and Equipped then
		if Name == "NoclipSpeedUp" then
			if State == Enum.UserInputState.Begin then
				Speed = Speed + 10
			end
		elseif Name == "NoclipSpeedDown" then
			if State == Enum.UserInputState.Begin then
				Speed = math.max(Speed - 10, 10)
			end
		end
	end
end

local function setupTool(t)
	tool = t
	tool.ToolTip = "Move around like you are playing normally."
	print("[Noclip] setupTool found", tool and tool.Name or "(nil)", "for", Player.Name)
	if UpButton and type(UpButton) == "string" and Enum.KeyCode[UpButton] then
		tool.ToolTip = tool.ToolTip .. " Press " .. UpButton .. " to move upwards."
	end
	if DownButton and type(DownButton) == "string" and Enum.KeyCode[DownButton] then
		tool.ToolTip = tool.ToolTip .. " Press " .. DownButton .. " to move downwards."
	end

	if SpeedUpButton and type(SpeedUpButton) == "string" and Enum.KeyCode[SpeedUpButton] and not _boundUp then
		print("[Noclip] binding speed up", SpeedUpButton)
		ContextActionService:BindAction("NoclipSpeedUp",OnPress,false,Enum.KeyCode[SpeedUpButton])
		_boundUp = true
		tool.ToolTip = tool.ToolTip .. " Press " .. SpeedUpButton .. " to speed up."
	end
	if SpeedDownButton and type(SpeedDownButton) == "string" and Enum.KeyCode[SpeedDownButton] and not _boundDown then
		print("[Noclip] binding speed down", SpeedDownButton)
		ContextActionService:BindAction("NoclipSpeedDown",OnPress,false,Enum.KeyCode[SpeedDownButton])
		_boundDown = true
		tool.ToolTip = tool.ToolTip .. " Press " .. SpeedDownButton .. " to slow down."
	end

	tool.Equipped:Connect(handleEquipped)
	tool.Unequipped:Connect(handleUnequipped)

	-- If the tool is already parented to the Character, ensure we enter equipped state
	if tool.Parent == Player.Character then
		task.defer(handleEquipped)
	end
end

-- Try to find tool immediately
local function findToolNow()
	local backpack = Player:FindFirstChild("Backpack")
	if backpack then
		local t = backpack:FindFirstChild(TOOL_NAME)
		if t and t:IsA("Tool") then return t end
	end
	if Player.Character then
		local t = Player.Character:FindFirstChild(TOOL_NAME)
		if t and t:IsA("Tool") then return t end
	end
	local starterPack = game:GetService("StarterPack")
	if starterPack then
		local t = starterPack:FindFirstChild(TOOL_NAME)
		if t and t:IsA("Tool") then return t end
	end
	return nil
end

local existing = findToolNow()
if existing then
	setupTool(existing)
else
	-- Wait for tool to appear in Backpack
	local backpack = Player:FindFirstChild("Backpack") or Player:WaitForChild("Backpack")
	local conn
	conn = backpack.ChildAdded:Connect(function(child)
		if child.Name == TOOL_NAME and child:IsA("Tool") then
			setupTool(child)
			conn:Disconnect()
		end
	end)
end
