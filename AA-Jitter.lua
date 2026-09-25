local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local SPIN_SPEED = 30
local JITTER_RANGE = 180
local JITTER_SPEED = 0.05

local jitterAngle = 0
local lastJitter = tick()

RunService.RenderStepped:Connect(function(dt)
    if not char or not char.Parent then return end
    jitterAngle = (jitterAngle + SPIN_SPEED * dt * 60) % 360
    local now = tick()
    if now - lastJitter > JITTER_SPEED then
        lastJitter = now
        local randomOffset = math.random(-JITTER_RANGE, JITTER_RANGE)
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(randomOffset), 0)
    end
    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(jitterAngle), 0)
end)
