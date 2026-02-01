local FORWARD_SPEED = 18
local MOVE_SPEED = 18
local char = script.Parent
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")
local flappyMode = char:WaitForChild("FlappyMode")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local bv
local orientConn
local moveConn

local function enableFlappyMove()
	print("Enabling Auto-Forward Movement!")
	
	-- Disable manual movement
	if moveConn then
		moveConn:Disconnect()
		moveConn = nil
	end
	
	-- Enable auto-forward movement
	if not bv then
		bv = Instance.new("BodyVelocity")
		bv.Velocity = Vector3.new(FORWARD_SPEED, 0, 0)
		bv.MaxForce = Vector3.new(1e5, 0, 0)
		bv.P = 1000
		bv.Parent = hrp
	end

	-- Lock orientation to face right
	if not orientConn then
		orientConn = RunService.RenderStepped:Connect(function()
			hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(1, 0, 0))
		end)
	end
end

local function enableManualMove()
	print("Enabling Manual Left/Right Movement!")
	
	-- Disable auto-forward movement
	if bv then
		bv:Destroy()
		bv = nil
	end
	
	-- Remove flappy orientation lock
	if orientConn then
		orientConn:Disconnect()
		orientConn = nil
	end
	
	-- Manual A/D movement with jumping
	if not moveConn then
		moveConn = RunService.Heartbeat:Connect(function()
			local moveX = 0
			
			if UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.Left) then
				moveX = -1
			end
			if UIS:IsKeyDown(Enum.KeyCode.D) or UIS:IsKeyDown(Enum.KeyCode.Right) then
				moveX = moveX + 1
			end
			
			-- Move character along X-axis only
			humanoid:Move(Vector3.new(moveX, 0, 0))
			
			-- Face movement direction
			if moveX ~= 0 then
				hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(moveX, 0, 0))
			end
			
			-- Jump with spacebar
			if UIS:IsKeyDown(Enum.KeyCode.Space) then
				if humanoid.FloorMaterial ~= Enum.Material.Air then
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
		end)
	end
end

flappyMode.Changed:Connect(function(isFlappy)
	print("PlayerMovement: FlappyMode changed to:", isFlappy)
	if isFlappy then
		enableFlappyMove()
	else
		enableManualMove()
	end
end)

-- Start with appropriate movement mode
if flappyMode.Value then
	enableFlappyMove()
else
	enableManualMove()
end
