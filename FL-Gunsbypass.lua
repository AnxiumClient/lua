
local okLib, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/sametexe001/sametlibs/refs/heads/main/Thugsense/Library.lua"))()
end)
if not okLib or not Library then
    okLib, Library = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/i77lhm/Libraries/main/Thugsense/Library.lua"))()
    end)
end
if not okLib or not Library then
    warn("[Anxium Fortline] Failed to load Thugsense UI library")
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local WEAPONS = {
    "AR",
    "SMG",
    "Shotgun",
    "Sniper",
    "Crossbow",
    "RocketLauncher",
    "GrenadeLauncher",
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

local function isValue(v)
    return typeof(v) == "Instance" and (v:IsA("NumberValue") or v:IsA("IntValue"))
end

local function forceValue(v, value)
    if not isValue(v) then return false end
    if v.Value ~= value then
        pcall(function()
            v.Value = value
        end)
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
        for _, x in ipairs(list) do if x == c then found = true break end end
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
            v:GetPropertyChangedSignal("Value"):Connect(function()
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
            end)
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

    if cfg.NoCooldown then
        forceNamed(tool, "ShotCooldown", 0)
    end

    if cfg.InfMag then
        forceNamed(tool, "AmmoCapacity", 999)
    end

    if cfg.InfAmmo then
        forceNamed(tool, "CurrentAmmo", 999)
    end

    if cfg.InfMag then
        local caps = collectNamed(tool, "AmmoCapacity")
        local ammos = collectNamed(tool, "CurrentAmmo")
        local capVal = 999
        if caps[1] then capVal = caps[1].Value end
        if cfg.InfAmmo then capVal = 999 end
        for _, a in ipairs(ammos) do
            if a.Value < capVal then
                forceValue(a, capVal)
            end
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

RunService.Heartbeat:Connect(function()
    scan(LP.Character)
    scan(LP:FindFirstChild("Backpack"))
    scan(game:GetService("StarterPack"))
end)

local function hookContainer(container)
    if not container then return end
    container.ChildAdded:Connect(function(ch)
        if ch:IsA("Tool") then
            task.defer(function()
                for _ = 1, 15 do
                    pcall(patchTool, ch)
                    task.wait(0.03)
                end
            end)
        end
    end)
end

hookContainer(LP:FindFirstChild("Backpack"))
hookContainer(game:GetService("StarterPack"))
if LP.Character then hookContainer(LP.Character) end
LP.CharacterAdded:Connect(function(char)
    hookContainer(char)
    task.defer(function()
        task.wait(0.2)
        scan(char)
    end)
end)

local Window = Library:Window({
    Name = "FL-Gunsbypass.lua",
    FadeSpeed = 0.25,
})

pcall(function()
    local wm = Library:Watermark("Anxium")
    wm:SetVisibility(false)
end)
pcall(function()
    local kb = Library:KeybindList()
    kb:SetVisibility(false)
end)

pcall(function()
    Library.MenuKeybind = tostring(Enum.KeyCode.Insert)
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode ~= Enum.KeyCode.Insert then return end
    pcall(function()
        if Window and Window.SetOpen then
            Window:SetOpen(not Window.IsOpen)
        end
    end)
end)

local GunsPage = Window:Page({ Name = "Guns bypass", Columns = 2, Subtabs = false })

local mid = math.ceil(#WEAPONS / 2)
for i, weaponName in ipairs(WEAPONS) do
    local side = (i <= mid) and 1 or 2
    local section = GunsPage:Section({ Name = weaponName, Side = side })

    section:Toggle({
        Name = "Enabled",
        Flag = weaponName .. "_Enabled",
        Default = false,
        Callback = function(v)
            GunCfg[weaponName].Enabled = v and true or false
            scan(LP.Character)
            scan(LP:FindFirstChild("Backpack"))
        end,
    })

    section:Toggle({
        Name = "No Recoil",
        Flag = weaponName .. "_NoRecoil",
        Default = false,
        Callback = function(v)
            GunCfg[weaponName].NoRecoil = v and true or false
        end,
    })

    section:Toggle({
        Name = "Infinite Ammo",
        Flag = weaponName .. "_InfAmmo",
        Default = false,
        Callback = function(v)
            GunCfg[weaponName].InfAmmo = v and true or false
        end,
    })

    section:Toggle({
        Name = "Infinite Mag",
        Flag = weaponName .. "_InfMag",
        Default = false,
        Callback = function(v)
            GunCfg[weaponName].InfMag = v and true or false
            scan(LP.Character)
            scan(LP:FindFirstChild("Backpack"))
        end,
    })

    section:Toggle({
        Name = "No Cooldown",
        Flag = weaponName .. "_NoCooldown",
        Default = false,
        Callback = function(v)
            GunCfg[weaponName].NoCooldown = v and true or false
        end,
    })
end

pcall(function()
    if Library.Init then Library:Init() end
end)
getgenv().AnxiumFortlineGuns = GunCfg
print("FL-Gunsbypass.lua loaded")
