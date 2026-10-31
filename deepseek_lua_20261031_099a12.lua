-- test.lua — ESP + Tracers для AnxiumHub
local Anxium = getgenv().Anxium or shared.Anxium
if not Anxium then
    return warn("Запусти скрипт из вкладки Scripts в Anxium")
end

local Players   = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- Состояние (источник правды для логики)
local state = {
    espEnabled     = false,
    tracersEnabled = false,
    maxDistance    = 500,
    teamCheck      = false,
}

-- Данные
local espData     = {}   -- [Player] = { highlight = Highlight }
local tracerData  = {}   -- [Player] = Drawing.Line
local connections = {}
local renderConn

-- Сеттеры от UI.Toggle (нужны в onLoad для восстановления)
local setESP, setTracers
local getESP, getTracers

-- Проверка Drawing API (не все экзекуторы её имеют)
local hasDrawing = false
pcall(function()
    hasDrawing = Drawing ~= nil and Drawing.new ~= nil
end)

-- ===== Очистка =====
local function clearESP()
    for player, data in pairs(espData) do
        if data.highlight then
            pcall(function() data.highlight:Destroy() end)
        end
        espData[player] = nil
    end
end

local function clearTracers()
    for player, line in pairs(tracerData) do
        pcall(function() line:Remove() end)
        tracerData[player] = nil
    end
end

local function clearAll()
    clearESP()
    clearTracers()
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    connections = {}
end

-- ===== Highlight (ESP) =====
local function createHighlight(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end

    local data = espData[player]
    if not data then
        data = {}
        espData[player] = data
    end
    if data.highlight and data.highlight.Parent then
        return
    end

    local hl = Instance.new("Highlight")
    hl.Name               = "AnxiumTestESP"
    hl.Adornee            = char
    hl.FillColor          = Color3.fromRGB(255, 60, 60)
    hl.FillTransparency   = 0.55
    hl.OutlineColor       = Color3.fromRGB(255, 60, 60)
    hl.OutlineTransparency= 0
    hl.DepthMode          = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent             = char

    data.highlight = hl
end

local function destroyHighlight(player)
    local data = espData[player]
    if data and data.highlight then
        pcall(function() data.highlight:Destroy() end)
        data.highlight = nil
    end
end

-- ===== Tracer =====
local function createTracer(player)
    if not hasDrawing then return end
    if player == LocalPlayer then return end
    if tracerData[player] then return end

    local ok, line = pcall(function() return Drawing.new("Line") end)
    if not ok or not line then return end

    line.Thickness    = 1
    line.Color        = Color3.fromRGB(255, 255, 255)
    line.Transparency = 1
    line.Visible      = false

    tracerData[player] = line
end

-- ===== Фильтр видимости =====
local function isVisible(player)
    if player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return false end

    if state.teamCheck then
        local myTeam = LocalPlayer.Team
        if myTeam and player.Team == myTeam then return false end
    end

    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myHRP and (myHRP.Position - hrp.Position).Magnitude > state.maxDistance then
        return false
    end
    return true
end

-- ===== Кадровое обновление =====
local function updateAll()
    -- Tracers
    if hasDrawing and next(tracerData) then
        local vp     = Camera.ViewportSize
        local origin = Vector2.new(vp.X / 2, vp.Y)
        for player, line in pairs(tracerData) do
            local show = state.tracersEnabled and isVisible(player)
            if show then
                local char = player.Character
                local part = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
                if part then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        line.From    = origin
                        line.To      = Vector2.new(pos.X, pos.Y)
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    end

    -- Highlights
    if state.espEnabled then
        for player, data in pairs(espData) do
            if data.highlight then
                data.highlight.Enabled = isVisible(player)
            end
        end
    end
end

-- ===== Подписки на игроков =====
local function onCharacterAdded(player)
    return function(char)
        destroyHighlight(player)
        if state.espEnabled    then createHighlight(player) end
        if state.tracersEnabled then createTracer(player)   end
    end
end

local function setupPlayer(player)
    if player == LocalPlayer then return end
    if player.Character then
        onCharacterAdded(player)(player.Character)
    end
    table.insert(connections, player.CharacterAdded:Connect(onCharacterAdded(player)))
end

for _, p in ipairs(Players:GetPlayers()) do
    setupPlayer(p)
end
table.insert(connections, Players.PlayerAdded:Connect(setupPlayer))
table.insert(connections, Players.PlayerRemoving:Connect(function(p)
    destroyHighlight(p)
    espData[p] = nil
    local line = tracerData[p]
    if line then
        pcall(function() line:Remove() end)
        tracerData[p] = nil
    end
end))

-- ===== Регистрация скрипта =====
Anxium.RegisterScript({
    id      = "anxium_test_esp",
    name    = "Test ESP",
    author  = "YourName",
    icon    = "rbxassetid://113164012451432",
    version = "1.0.0",

    buildUI = function(parent, UI, API)
        local card = UI.Section("ESP")

        -- Toggle ESP + бинд
        local _, gE, sE = UI.Toggle(card, "ESP Enabled", false, function(on)
            state.espEnabled = on
            if on then
                for _, p in ipairs(Players:GetPlayers()) do
                    createHighlight(p)
                end
            else
                clearESP()
            end
        end)
        getESP, setESP = gE, sE
        API.RegisterBind("ESP Enabled", gE, sE)   -- бинд в Settings -> Binds

        -- Toggle Tracers + бинд
        local _, gT, sT = UI.Toggle(card, "Tracers", false, function(on)
            state.tracersEnabled = on
            if on then
                if not hasDrawing then
                    API.Notify("Test ESP", "Drawing API недоступен, трейсеры не работают")
                end
                for _, p in ipairs(Players:GetPlayers()) do
                    createTracer(p)
                end
            else
                clearTracers()
            end
        end)
        getTracers, setTracers = gT, sT
        API.RegisterBind("Tracers", gT, sT)

        -- Дальность
        UI.Slider(card, "Max Distance", 50, 5000, 500, function(v)
            state.maxDistance = v
        end)

        -- Team Check (dropdown)
        UI.Dropdown(card, "Team Check", { "Off", "On" }, "Off", function(v)
            state.teamCheck = (v == "On")
        end)

        -- Кнопка-пинг
        UI.Button(card, "Ping", function()
            API.Notify("Test ESP", "pong")
        end)
    end,

    onLoad = function(API)
        local cfg = API.GetConfig()

        -- Применяем сохранённые slider/dropdown к логике
        state.maxDistance = tonumber(cfg.sld_Max_Distance) or 500
        state.teamCheck   = (cfg.dd_Team_Check == "On")

        -- Toggle: set() синхронизирует UI, бинд, конфиг и логику
        if setESP     then setESP(cfg.tog_ESP_Enabled == true)       end
        if setTracers then setTracers(cfg.tog_Tracers == true)        end

        -- Рендер-цикл
        if not renderConn then
            renderConn = RunService.RenderStepped:Connect(updateAll)
        end

        API.Notify("Test ESP", "Loaded")
    end,

    onUnload = function()
        state.espEnabled     = false
        state.tracersEnabled = false
        clearAll()
    end,
})