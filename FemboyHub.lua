local Anxium = getgenv().Anxium or shared.Anxium
if not Anxium then
    return warn("Запусти скрипт из вкладки Scripts в Anxium")
end

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Workspace   = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ─── Палитра (розовые оттенки) ───────────────────────────────
local PINK        = Color3.fromRGB(255, 105, 180)
local PINK_LIGHT  = Color3.fromRGB(255, 182, 193)
local PINK_DARK   = Color3.fromRGB(199,  21, 133)
local BG_DARK     = Color3.fromRGB( 35,  25,  30)

-- ─── Настройки ───────────────────────────────────────────────
local settings = {
    enabled  = false,
    box      = true,
    name     = true,
    health   = true,
    distance = true,
}

local drawings   = {}   -- [Player] = { box=..., name=..., ... }
local connections = {}
local renderConn

-- ─── Утилиты Drawing ─────────────────────────────────────────
local function makeDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    d.Visible = false
    return d
end

local function removeDrawings(plr)
    if drawings[plr] then
        for _, d in pairs(drawings[plr]) do
            pcall(function() d:Remove() end)
        end
        drawings[plr] = nil
    end
end

local function clearAll()
    for plr in pairs(drawings) do removeDrawings(plr) end
end

-- ─── Расчёт рамки персонажа ──────────────────────────────────
local function getBoxData(char)
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hrp or not head then return nil end

    local cam = Workspace.CurrentCamera
    local top    = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    local bottom = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
    if top.Z <= 0 or bottom.Z <= 0 then return nil end

    local h = bottom.Y - top.Y
    if h <= 0 then return nil end
    local w = h / 2
    return Vector2.new(top.X - w / 2, top.Y), Vector2.new(w, h)
end

-- ─── Ленивое создание Drawing'ов для игрока ──────────────────
local function ensureDrawings(plr)
    if drawings[plr] then return drawings[plr] end
    drawings[plr] = {
        box = makeDrawing("Square", {
            Thickness = 1, Filled = false, Color = PINK,
        }),
        name = makeDrawing("Text", {
            Size = 14, Center = true, Outline = true,
            Color = PINK_LIGHT, OutlineColor = Color3.new(0, 0, 0),
        }),
        healthBg = makeDrawing("Square", {
            Thickness = 1, Filled = true, Color = BG_DARK,
        }),
        health = makeDrawing("Square", {
            Thickness = 1, Filled = true, Color = PINK_DARK,
        }),
        distance = makeDrawing("Text", {
            Size = 12, Center = true, Outline = true,
            Color = PINK_LIGHT, OutlineColor = Color3.new(0, 0, 0),
        }),
    }
    return drawings[plr]
end

-- ─── Главный цикл ────────────────────────────────────────────
local function update()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then
            removeDrawings(plr)
            continue
        end

        local char = plr.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")

        if not settings.enabled or not hrp or not hum or hum.Health <= 0 then
            removeDrawings(plr)
            continue
        end

        local pos, size = getBoxData(char)
        if not pos then
            removeDrawings(plr)
            continue
        end

        local d = ensureDrawings(plr)

        -- ESP Box
        d.box.Visible  = settings.box
        d.box.Position = pos
        d.box.Size     = size

        -- Ник
        d.name.Visible  = settings.name
        d.name.Text     = plr.Name
        d.name.Position = Vector2.new(pos.X + size.X / 2, pos.Y - 16)

        -- Полоска здоровья (слева от бокса)
        local frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        local barX = pos.X - 6
        d.healthBg.Visible  = settings.health
        d.health.Visible    = settings.health
        d.healthBg.Position = Vector2.new(barX, pos.Y)
        d.healthBg.Size     = Vector2.new(3, size.Y)
        d.health.Position   = Vector2.new(barX, pos.Y + size.Y * (1 - frac))
        d.health.Size       = Vector2.new(3, size.Y * frac)

        -- Дистанция
        d.distance.Visible = settings.distance
        local lpChar = LocalPlayer.Character
        local lpHRP  = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
        d.distance.Text = lpHRP
            and (tostring(math.floor((hrp.Position - lpHRP.Position).Magnitude)) .. " m")
            or  "?"
        d.distance.Position = Vector2.new(pos.X + size.X / 2, pos.Y + size.Y + 2)
    end
end

-- ─── Регистрация скрипта ─────────────────────────────────────
Anxium.RegisterScript({
    id      = "femboy_esp",
    name    = "femboy",
    author  = "co4vm",
    icon    = "rbxassetid://113164012451432",
    version = "1.0.0",

    buildUI = function(parent, UI, API)
        local card = UI.Section("ESP · femboy")

        local _, getEnabled, setEnabled = UI.Toggle(card, "Enabled", false, function(on)
            settings.enabled = on
        end)
        API.RegisterBind("Femboy ESP", getEnabled, setEnabled)

        local _, getBox, setBox = UI.Toggle(card, "Box", true, function(v)
            settings.box = v
        end)
        API.RegisterBind("Femboy ESP Box", getBox, setBox)

        local _, getName, setName = UI.Toggle(card, "Name", true, function(v)
            settings.name = v
        end)
        API.RegisterBind("Femboy ESP Name", getName, setName)

        UI.Toggle(card, "Health Bar", true, function(v) settings.health = v end)
        UI.Toggle(card, "Distance",   true, function(v) settings.distance = v end)

        UI.Label(card, "Pink ESP для всех игроков 💗")
    end,

    onLoad = function(API)
        renderConn = RunService.RenderStepped:Connect(function()
            pcall(update)
        end)

        table.insert(connections, Players.PlayerRemoving:Connect(function(plr)
            removeDrawings(plr)
        end))

        if API and API.Notify then
            API.Notify("femboy", "Pink ESP загружен 💗")
        end
    end,

    onUnload = function()
        if renderConn then
            renderConn:Disconnect()
            renderConn = nil
        end
        for _, c in ipairs(connections) do
            pcall(function() c:Disconnect() end)
        end
        connections = {}
        clearAll()
    end,
})
