local Anxium = rawget(getgenv(), "Anxium") or rawget(shared, "Anxium")
if not Anxium or not Anxium.RegisterPlugin then
    return warn("[Speed Test] Запускай плагин через Anxium > Scripts")
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

if not player then
    return warn("[Speed Test] LocalPlayer не найден")
end

local active = false
local enabled = false
local speed = 32
local humanoid = nil
local originalSpeed = nil
local characterConnection = nil
local heartbeatConnection = nil
local elapsed = 0

local function restoreSpeed()
    if humanoid and humanoid.Parent and originalSpeed ~= nil then
        humanoid.WalkSpeed = originalSpeed
    end
    originalSpeed = nil
end

local function applySpeed()
    if not active or not humanoid or not humanoid.Parent then
        return
    end

    if enabled then
        if originalSpeed == nil then
            originalSpeed = humanoid.WalkSpeed
        end
        humanoid.WalkSpeed = speed
    else
        restoreSpeed()
    end
end

local function bindCharacter(character)
    task.spawn(function()
        local nextHumanoid = character:FindFirstChildOfClass("Humanoid")
            or character:WaitForChild("Humanoid", 10)

        if not active or not nextHumanoid or player.Character ~= character then
            return
        end

        restoreSpeed()
        humanoid = nextHumanoid
        applySpeed()
    end)
end

local success, result = Anxium.RegisterPlugin({
    id = "anxium_speed_test",
    name = "Speed Test",
    icon = "rbxassetid://79541605299928",
    version = "1.0.0",
    author = "Anxium",

    buildUI = function(parent, UI, API)
        local movement = UI.Section("Movement")

        UI.Toggle(movement, "Enabled", false, function(value)
            enabled = value
            applySpeed()
            API.Notify("Speed Test", value and "Speed enabled" or "Speed disabled")
        end)

        UI.Slider(movement, "Speed", 16, 100, 32, function(value)
            speed = math.clamp(tonumber(value) or 32, 16, 100)
            applySpeed()
        end)

        UI.Label(movement, "Default: 16 | Test range: 16-100")
    end,

    onLoad = function(API)
        local config = API.GetConfig() or {}
        enabled = config.tog_Enabled == true
        speed = math.clamp(tonumber(config.sld_Speed) or 32, 16, 100)
        active = true
        elapsed = 0

        characterConnection = player.CharacterAdded:Connect(bindCharacter)
        if player.Character then
            bindCharacter(player.Character)
        end

        heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
            elapsed = elapsed + dt
            if elapsed < 0.2 then
                return
            end
            elapsed = 0

            if active and enabled and humanoid and humanoid.Parent
                and humanoid.Health > 0 and humanoid.WalkSpeed ~= speed then
                humanoid.WalkSpeed = speed
            end
        end)

        API.Notify("Speed Test", "Plugin loaded")
    end,

    onUnload = function()
        active = false
        if characterConnection then
            characterConnection:Disconnect()
            characterConnection = nil
        end
        if heartbeatConnection then
            heartbeatConnection:Disconnect()
            heartbeatConnection = nil
        end
        restoreSpeed()
        humanoid = nil
    end,
})

if not success then
    warn("[Speed Test] Plugin registration failed: " .. tostring(result))
end
