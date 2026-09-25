local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local TOOL_NAME = "RocketLauncher"
local TARGET_CD = 0
local INF_AMMO = 999

local RECOIL_KEYS = {
    "RecoilMin",
    "RecoilMax",
    "TotalRecoilMax",
    "RecoilDecay",
    "Recoil",
    "RecoilSpeed",
    "CameraRecoil",
    "Kickback",
}

local function isRocketName(n)
    n = string.lower(tostring(n or ""))
    return n == "rocketlauncher" or string.find(n, "rocket", 1, true) ~= nil
end

local function findValue(parent, name)
    if not parent then return nil end
    local v = parent:FindFirstChild(name)
    if v and (v:IsA("NumberValue") or v:IsA("IntValue")) then return v end
    return nil
end

local function findAnyValue(tool, name)
    local cfg = tool:FindFirstChild("Configuration")
    local v = findValue(cfg, name) or findValue(tool, name)
    if v then return v end
    for _, d in ipairs(tool:GetDescendants()) do
        if d.Name == name and (d:IsA("NumberValue") or d:IsA("IntValue")) then
            return d
        end
    end
    return nil
end

local function setVal(tool, name, value)
    local v = findAnyValue(tool, name)
    if v and v.Value ~= value then
        v.Value = value
    end
end

local function patchCooldown(tool)
    setVal(tool, "ShotCooldown", TARGET_CD)
end

local function patchAmmo(tool)
    setVal(tool, "CurrentAmmo", INF_AMMO)
    setVal(tool, "AmmoCapacity", INF_AMMO)
end

local function patchRecoil(tool)
    for _, key in ipairs(RECOIL_KEYS) do
        setVal(tool, key, 0)
    end
    local cfg = tool:FindFirstChild("Configuration")
    if cfg then
        for _, d in ipairs(cfg:GetChildren()) do
            if (d:IsA("NumberValue") or d:IsA("IntValue")) then
                local n = string.lower(d.Name)
                if string.find(n, "recoil", 1, true) or string.find(n, "kick", 1, true) then
                    if d.Value ~= 0 then d.Value = 0 end
                end
            end
        end
    end
end

local function getRocketTools()
    local list = {}
    local function scan(container)
        if not container then return end
        for _, c in ipairs(container:GetChildren()) do
            if c:IsA("Tool") and isRocketName(c.Name) then
                list[#list + 1] = c
            end
        end
    end
    scan(LP.Character)
    scan(LP:FindFirstChild("Backpack"))
    return list
end

local function patchAll()
    for _, tool in ipairs(getRocketTools()) do
        pcall(patchCooldown, tool)
        pcall(patchAmmo, tool)
        pcall(patchRecoil, tool)
    end
end

RunService.Heartbeat:Connect(function()
    pcall(patchAll)
end)

local function onTool(ch)
    if ch:IsA("Tool") and isRocketName(ch.Name) then
        task.defer(function()
            pcall(patchCooldown, ch)
            pcall(patchAmmo, ch)
            pcall(patchRecoil, ch)
        end)
    end
end

local function hookChar(char)
    if not char then return end
    char.ChildAdded:Connect(onTool)
end

if LP.Character then hookChar(LP.Character) end
LP.CharacterAdded:Connect(hookChar)

local bp = LP:FindFirstChild("Backpack")
if bp then
    bp.ChildAdded:Connect(onTool)
end

print("lua loaded!")
