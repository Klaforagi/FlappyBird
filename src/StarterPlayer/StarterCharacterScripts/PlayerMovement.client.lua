local FORWARD_SPEED = 18
local char = script.Parent
local hrp = char:WaitForChild("HumanoidRootPart")
local flappyMode = char:WaitForChild("FlappyMode")

local bv
local orientConn -- To store the orientation connection

local function enableFlappyMove()
	print("Enabling Flappy Movement!")
	if not bv then
		bv = Instance.new("BodyVelocity")
		bv.Velocity = Vector3.new(FORWARD_SPEED, 0, 0)
		bv.MaxForce = Vector3.new(1e5, 0, 0)
		bv.P = 1000
		bv.Parent = hrp
		print("BodyVelocity parented to HumanoidRootPart")
	end

	-- Start orientation lock (face right/X+)
	if not orientConn then
		orientConn = game:GetService("RunService").RenderStepped:Connect(function()
			hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(1, 0, 0))
		end)
	end
end

local function disableFlappyMove()
	print("Disabling Flappy Movement!")
	if bv then
		bv:Destroy()
		bv = nil
	end
	-- Stop orientation lock
	if orientConn then
		orientConn:Disconnect()
		orientConn = nil
	end
end

flappyMode.Changed:Connect(function(isFlappy)
	print("PlayerMovement: FlappyMode changed to:", isFlappy)
	if isFlappy then
		enableFlappyMove()
	else
		disableFlappyMove()
	end
end)

if flappyMode.Value then
	enableFlappyMove()
end
