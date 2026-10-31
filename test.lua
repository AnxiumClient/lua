local function resolveAnxium()
    local a
    pcall(function()
        if getgenv then a = getgenv().Anxium end
    end)
    if type(a) == "table" and type(a.RegisterPlugin) == "function" then return a end
    pcall(function()
        if shared then a = shared.Anxium end
    end)
    if type(a) == "table" and type(a.RegisterPlugin) == "function" then return a end
    pcall(function()
        a = rawget(_G, "Anxium")
    end)
    if type(a) == "table" and type(a.RegisterPlugin) == "function" then return a end
    if type(Anxium) == "table" and type(Anxium.RegisterPlugin) == "function" then return Anxium end
    return nil
end

local Anxium = resolveAnxium()
if not Anxium then
    warn("[test] Anxium API missing - start from Scripts tab")
    return
end

local PLUGIN_ID = "test"
local state = {
    speedEnabled = false,
    speedValue = 32,
    espEnabled = false,
}
local setSpeedVisual
local setEspVisual
local conn

local function applySpeed()
    local char = game:GetService("Players").LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if state.speedEnabled then
        hum.WalkSpeed = state.speedValue
    else
        hum.WalkSpeed = 16
    end
end

local function clearEsp()
    local folder = workspace:FindFirstChild("TestPluginEsp")
    if folder then folder:Destroy() end
end

local function updateEsp()
    clearEsp()
    if not state.espEnabled then return end

    local folder = Instance.new("Folder")
    folder.Name = "TestPluginEsp"
    folder.Parent = workspace

    local lp = game:GetService("Players").LocalPlayer
    for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
        if plr == lp then continue end
        local char = plr.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end

        local hl = Instance.new("Highlight")
        hl.Name = "Esp_" .. plr.Name
        hl.Adornee = char
        hl.FillColor = Color3.fromRGB(180, 140, 255)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.55
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = folder
    end
end

local ok, err = Anxium.RegisterPlugin({
    id = PLUGIN_ID,
    name = "test",
    author = "co4vm",
    icon = "rbxassetid://113164012451432",
    version = "1.0.0",

    buildUI = function(parent, UI, API)
        local main = UI.Section("Main")

        local _, getSpeed, setSpeed = UI.Toggle(main, "Speed Hack", false, function(on)
            state.speedEnabled = on
            applySpeed()
            API.Notify("test", on and "Speed ON" or "Speed OFF")
        end)
        setSpeedVisual = setSpeed

        UI.Slider(main, "Walk Speed", 16, 100, 32, function(v)
            state.speedValue = v
            if state.speedEnabled then
                applySpeed()
            end
        end)

        local _, getEsp, setEsp = UI.Toggle(main, "Simple ESP", false, function(on)
            state.espEnabled = on
            updateEsp()
            API.Notify("test", on and "ESP ON" or "ESP OFF")
        end)
        setEspVisual = setEsp

        API.RegisterBind("test Speed", function()
            return state.speedEnabled == true
        end, function(v)
            state.speedEnabled = v and true or false
            if setSpeedVisual then setSpeedVisual(state.speedEnabled) end
            applySpeed()
        end)

        API.RegisterBind("test ESP", function()
            return state.espEnabled == true
        end, function(v)
            state.espEnabled = v and true or false
            if setEspVisual then setEspVisual(state.espEnabled) end
            updateEsp()
        end)

        local actions = UI.Section("Actions")
        UI.Button(actions, "Refresh ESP", function()
            updateEsp()
            API.Notify("test", "ESP refreshed")
        end)
        UI.Label(actions, "Binds: Settings -> Binds")
    end,

    onLoad = function(API)
        local cfg = API.GetConfig()
        state.speedEnabled = cfg.tog_Speed_Hack == true
        state.speedValue = tonumber(cfg.sld_Walk_Speed) or 32
        state.espEnabled = cfg.tog_Simple_ESP == true

        if setSpeedVisual then setSpeedVisual(state.speedEnabled) end
        if setEspVisual then setEspVisual(state.espEnabled) end

        applySpeed()
        updateEsp()

        if conn then pcall(function() conn:Disconnect() end) end
        conn = game:GetService("Players").PlayerAdded:Connect(function()
            task.wait(1)
            if state.espEnabled then updateEsp() end
        end)

        game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.3)
            applySpeed()
        end)

        API.Notify("test", "Loaded (author: co4vm)")
    end,

    onUnload = function()
        state.speedEnabled = false
        state.espEnabled = false
        applySpeed()
        clearEsp()
        if conn then
            pcall(function() conn:Disconnect() end)
            conn = nil
        end
    end,
})

if not ok then
    warn("[test] Register failed:", tostring(err))
end
