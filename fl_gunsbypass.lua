--[[
  FL Guns Bypass
  Author: co4vm
  Anxium Lua Script (RegisterScript) — toggles only, no external UI lib
]]

local env = (getgenv and getgenv()) or _G
local Anxium = rawget(env, "Anxium")
if type(Anxium) ~= "table" or type(Anxium.RegisterScript) ~= "function" then
    warn("[FL Guns] Run Anxium first")
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local WEAPONS = {
    "AR", "SMG", "Shotgun", "Sniper", "Crossbow", "RocketLauncher", "GrenadeLauncher",
}

local RECOIL_KEYS = {
    "RecoilMin", "RecoilMax", "TotalRecoilMax", "RecoilDecay",
    "Recoil", "RecoilSpeed", "CameraRecoil", "Kickback", "MaxSpread",
}

local GunCfg = {}
for _, name in ipairs(WEAPONS) do
    GunCfg[name] = {
        Enabled = false,
        NoRecoil = false,
        InfAmmo = false,
        InfMag = false,
        NoCooldown = false,
    }
end

local Connections = {}
local function track(c)
    if c then Connections[#Connections + 1] = c end
    return c
end

local function isValue(v)
    return typeof(v) == "Instance" and (v:IsA("NumberValue") or v:IsA("IntValue"))
end

local function forceValue(v, value)
    if not isValue(v) then return false end
    if v.Value ~= value then
        pcall(function() v.Value = value end)
        return true
    end
    return false
end

local function collectNamed(tool, name)
    local list = {}
    if not tool then return list end
    for _, d in ipairs(tool:GetDescendants()) do
        if isValue(d) and d.Name == name then
            list[#list + 1] = d
        end
    end
    local c = tool:FindFirstChild(name)
    if isValue(c) then
        local found = false
        for _, x in ipairs(list) do
            if x == c then found = true break end
        end
        if not found then list[#list + 1] = c end
    end
    return list
end

local function forceNamed(tool, name, value)
    local any = false
    for _, v in ipairs(collectNamed(tool, name)) do
        if forceValue(v, value) then any = true end
        if not v:GetAttribute("AnxiumLocked") then
            v:SetAttribute("AnxiumLocked", true)
            track(v:GetPropertyChangedSignal("Value"):Connect(function()
                local cfg = nil
                local tn = string.lower(tostring(tool.Name))
                for _, w in ipairs(WEAPONS) do
                    if tn == string.lower(w) then cfg = GunCfg[w] break end
                end
                if not cfg or not cfg.Enabled then return end
                if name == "AmmoCapacity" and cfg.InfMag and v.Value ~= 999 then
                    forceValue(v, 999)
                elseif name == "CurrentAmmo" and cfg.InfAmmo and v.Value ~= 999 then
                    forceValue(v, 999)
                elseif name == "ShotCooldown" and cfg.NoCooldown and v.Value ~= 0 then
                    forceValue(v, 0)
                end
            end))
        end
    end
    return any
end

local function getCfgForTool(tool)
    if not tool then return nil end
    local tn = string.lower(tostring(tool.Name)):gsub("%s+", "")
    for _, name in ipairs(WEAPONS) do
        if tn == string.lower(name):gsub("%s+", "") then
            return GunCfg[name]
        end
    end
    return nil
end

local function patchTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    local cfg = getCfgForTool(tool)
    if not cfg or not cfg.Enabled then return end
    if cfg.NoCooldown then forceNamed(tool, "ShotCooldown", 0) end
    if cfg.InfMag then forceNamed(tool, "AmmoCapacity", 999) end
    if cfg.InfAmmo then forceNamed(tool, "CurrentAmmo", 999) end
    if cfg.InfMag then
        local caps = collectNamed(tool, "AmmoCapacity")
        local ammos = collectNamed(tool, "CurrentAmmo")
        local capVal = 999
        if caps[1] then capVal = caps[1].Value end
        if cfg.InfAmmo then capVal = 999 end
        for _, a in ipairs(ammos) do
            if a.Value < capVal then forceValue(a, capVal) end
        end
    end
    if cfg.NoRecoil then
        for _, key in ipairs(RECOIL_KEYS) do
            forceNamed(tool, key, 0)
        end
        local folder = tool:FindFirstChild("Configuration")
        if folder then
            for _, d in ipairs(folder:GetChildren()) do
                if isValue(d) then
                    local n = string.lower(d.Name)
                    if n:find("recoil", 1, true) or n:find("kick", 1, true) or n:find("spread", 1, true) then
                        forceValue(d, 0)
                    end
                end
            end
        end
    end
end

local function scan(container)
    if not container then return end
    for _, ch in ipairs(container:GetChildren()) do
        if ch:IsA("Tool") then
            pcall(patchTool, ch)
        end
    end
end

local function rescanAll()
    scan(LP.Character)
    scan(LP:FindFirstChild("Backpack"))
    pcall(function() scan(game:GetService("StarterPack")) end)
end

local function hookContainer(container)
    if not container then return end
    track(container.ChildAdded:Connect(function(ch)
        if ch:IsA("Tool") then
            task.defer(function()
                for _ = 1, 15 do
                    pcall(patchTool, ch)
                    task.wait(0.03)
                end
            end)
        end
    end))
end

Anxium.RegisterScript({
    id = "fl_gunsbypass",
    name = "FL Guns Bypass",
    author = "co4vm",
    icon = "rbxassetid://119051552929078",

    -- UI only: Anxium toggles / sections
    buildUI = function(tabFrame, UI, API)
        UI.Label(tabFrame, "Fortline weapon bypass — enable options per gun")

        for _, weaponName in ipairs(WEAPONS) do
            local section = UI.Section(weaponName)

            UI.Toggle(section, weaponName .. " Enabled", false, function(v)
                GunCfg[weaponName].Enabled = v and true or false
                rescanAll()
            end)
            UI.Toggle(section, weaponName .. " No Recoil", false, function(v)
                GunCfg[weaponName].NoRecoil = v and true or false
                if v then rescanAll() end
            end)
            UI.Toggle(section, weaponName .. " Inf Ammo", false, function(v)
                GunCfg[weaponName].InfAmmo = v and true or false
                if v then rescanAll() end
            end)
            UI.Toggle(section, weaponName .. " Inf Mag", false, function(v)
                GunCfg[weaponName].InfMag = v and true or false
                rescanAll()
            end)
            UI.Toggle(section, weaponName .. " No Cooldown", false, function(v)
                GunCfg[weaponName].NoCooldown = v and true or false
                if v then rescanAll() end
            end)
        end
    end,

    onLoad = function(API)
        -- sync saved plugin toggles into GunCfg
        local cfg = API.GetConfig()
        if type(cfg) == "table" then
            for _, weaponName in ipairs(WEAPONS) do
                local function read(label)
                    local k = "tog_" .. tostring(label):gsub("%s+", "_")
                    return cfg[k] == true
                end
                local g = GunCfg[weaponName]
                g.Enabled = read(weaponName .. " Enabled")
                g.NoRecoil = read(weaponName .. " No Recoil")
                g.InfAmmo = read(weaponName .. " Inf Ammo")
                g.InfMag = read(weaponName .. " Inf Mag")
                g.NoCooldown = read(weaponName .. " No Cooldown")
            end
        end

        track(RunService.Heartbeat:Connect(function()
            rescanAll()
        end))

        hookContainer(LP:FindFirstChild("Backpack"))
        pcall(function() hookContainer(game:GetService("StarterPack")) end)
        if LP.Character then hookContainer(LP.Character) end
        track(LP.CharacterAdded:Connect(function(char)
            hookContainer(char)
            task.defer(function()
                task.wait(0.2)
                scan(char)
            end)
        end))

        env.AnxiumFortlineGuns = GunCfg
        if API.Notify then API.Notify("FL Guns", "Ready") end
    end,

    onUnload = function()
        for _, c in ipairs(Connections) do
            pcall(function() c:Disconnect() end)
        end
        table.clear(Connections)
        for _, name in ipairs(WEAPONS) do
            local g = GunCfg[name]
            if g then
                g.Enabled = false
                g.NoRecoil = false
                g.InfAmmo = false
                g.InfMag = false
                g.NoCooldown = false
            end
        end
        env.AnxiumFortlineGuns = nil
    end,
})
