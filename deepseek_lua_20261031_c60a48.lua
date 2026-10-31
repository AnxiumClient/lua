local Anxium = getgenv().Anxium or shared.Anxium
if not Anxium then return warn("Start from Anxium Scripts") end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Настройки по умолчанию
local State = {
    Aim = { enabled = false, fov = 150, smooth = 0.3, part = "Head" },
    ESP = { 
        enabled = false, 
        text = true, 
        box = true, 
        chams = false, 
        part = "Head", 
        color = Color3.fromRGB(255, 105, 180), -- Розовый
        chamsColor = Color3.fromRGB(255, 105, 180)
    },
    aimConn = nil,
    renderConn = nil,
    connections = {},
    espDrawings = {},
    chamsInstances = {}
}

local function getChar(plr)
    local c = plr.Character
    if not c then return nil end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return nil end
    return c
end

local function getPart(plr, name)
    local c = getChar(plr)
    if not c then return nil end
    return c:FindFirstChild(name) or c:FindFirstChild("HumanoidRootPart")
end

-- ===== Aimlock =====
local function closestToMouse(maxDist)
    local best, bestD = nil, maxDist or math.huge
    local mp = UserInputService:GetMouseLocation()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local part = getPart(plr, State.Aim.part)
            if part then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d = (Vector2.new(sp.X, sp.Y) - mp).Magnitude
                    if d < bestD then best, bestD = part, d end
                end
            end
        end
    end
    return best
end

local function startAim()
    if State.aimConn then return end
    State.aimConn = RunService.RenderStepped:Connect(function()
        if not State.Aim.enabled then return end
        local target = closestToMouse(State.Aim.fov)
        if target then
            local desired = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(desired, State.Aim.smooth)
        end
    end)
end

local function stopAim()
    if State.aimConn then
        State.aimConn:Disconnect()
        State.aimConn = nil
    end
end

-- ===== Visuals (ESP & Chams) =====

-- Очистка Drawing объектов (Box ESP)
local function clearDrawings()
    for _, obj in pairs(State.espDrawings) do
        if obj.box then obj.box:Remove() end
    end
    State.espDrawings = {}
end

-- Очистка Chams
local function clearChams()
    for _, inst in pairs(State.chamsInstances) do
        if inst then inst:Destroy() end
    end
    State.chamsInstances = {}
end

-- Создание Chams для персонажа
local function updateChams(plr)
    if not State.ESP.enabled or not State.ESP.chams then
        if State.chamsInstances[plr] then
            State.chamsInstances[plr]:Destroy()
            State.chamsInstances[plr] = nil
        end
        return
    end

    local char = plr.Character
    if not char then return end
    
    if not State.chamsInstances[plr] or not State.chamsInstances[plr].Parent then
        local hl = Instance.new("Highlight")
        hl.Name = "FemboyLuaChams"
        hl.FillColor = State.ESP.chamsColor
        hl.OutlineColor = Color3.new(1, 1, 1)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char
        State.chamsInstances[plr] = hl
    else
        State.chamsInstances[plr].FillColor = State.ESP.chamsColor
    end
end

-- Основной рендер ESP
local function renderESP()
    clearDrawings()
    local mp = UserInputService:GetMouseLocation()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            updateChams(plr)

            local char = getChar(plr)
            if char and State.ESP.enabled then
                local root = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                
                if root and head then
                    -- Настройка Box ESP
                    if State.ESP.box then
                        local topPos = Camera:WorldToViewportPoint((root.CFrame * CFrame.new(0, 3, 0)).Position)
                        local bottomPos = Camera:WorldToViewportPoint((root.CFrame * CFrame.new(0, -3, 0)).Position)
                        
                        if topPos.Z > 0 and bottomPos.Z > 0 then
                            local height = math.abs(topPos.Y - bottomPos.Y)
                            local width = height / 2
                            local centerX = (topPos.X + bottomPos.X) / 2
                            
                            local box = State.espDrawings[plr] and State.espDrawings[plr].box
                            if not box then
                                box = Drawing.new("Square")
                                box.Thickness = 1
                                box.Filled = false
                                box.Transparency = 1
                                State.espDrawings[plr] = { box = box }
                            end
                            
                            box.Size = Vector2.new(width, height)
                            box.Position = Vector2.new(centerX - width/2, topPos.Y)
                            box.Color = State.ESP.color
                            box.Visible = true
                        else
                            if State.espDrawings[plr] and State.espDrawings[plr].box then
                                State.espDrawings[plr].box.Visible = false
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ===== Управление ESP =====
local function startESP()
    if State.renderConn then return end
    -- Принудительно обновляем чамсы при включении
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then updateChams(plr) end
    end
    
    State.renderConn = RunService.RenderStepped:Connect(function()
        if not State.ESP.enabled then 
            clearDrawings()
            return 
        end
        renderESP()
    end)
end

local function stopESP()
    if State.renderConn then
        State.renderConn:Disconnect()
        State.renderConn = nil
    end
    clearDrawings()
    clearChams()
end

-- Отслеживание респавна игроков для Chams
table.insert(State.connections, Players.PlayerAdded:Connect(function(plr)
    table.insert(State.connections, plr.CharacterAdded:Connect(function()
        task.wait(1)
        if State.ESP.enabled then updateChams(plr) end
    end))
end))

-- ===== Регистрация плагина =====
Anxium.RegisterPlugin({
    id = "femboy_lua",
    name = "Femboy Lua",
    icon = "rbxassetid://113164012451432",

    buildUI = function(parent, UI, API)
        -- === СЕКЦИЯ: Aimlock ===
        local aimCard = UI.Section("Aimlock Settings")
        
        local _, aimGet, aimSet = UI.Toggle(aimCard, "Enabled", false, function(on)
            State.Aim.enabled = on
            if on then startAim() else stopAim() end
        end)
        API.RegisterBind("Aimlock Toggle", aimGet, aimSet)

        UI.Slider(aimCard, "FOV (Pixels)", 10, 800, 150, function(v)
            State.Aim.fov = v
        end)
        UI.Slider(aimCard, "Smoothness", 0.05, 1, 0.3, function(v)
            State.Aim.smooth = v
        end)
        UI.Dropdown(aimCard, "Aim Target", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, "Head", function(v)
            State.Aim.part = v
        end)

        -- === СЕКЦИЯ: Visuals (ESP & Chams) ===
        local espCard = UI.Section("Visuals")
        
        local _, espGet, espSet = UI.Toggle(espCard, "Master ESP", false, function(on)
            State.ESP.enabled = on
            if on then startESP() else stopESP() end
        end)
        API.RegisterBind("ESP Toggle", espGet, espSet)

        UI.Toggle(espCard, "Box ESP", true, function(on)
            State.ESP.box = on
            if not on and State.espDrawings then 
                for _, obj in pairs(State.espDrawings) do
                    if obj.box then obj.box.Visible = false end
                end
            end
        end)

        UI.Toggle(espCard, "Chams (Glow)", false, function(on)
            State.ESP.chams = on
            if not on then clearChams() else 
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then updateChams(plr) end
                end
            end
        end)

        UI.Dropdown(espCard, "ESP Color", {"Pink", "Cyan", "White", "Red"}, "Pink", function(v)
            local colors = {
                Pink = Color3.fromRGB(255, 105, 180),
                Cyan = Color3.fromRGB(0, 255, 255),
                White = Color3.fromRGB(255, 255, 255),
                Red = Color3.fromRGB(255, 50, 50)
            }
            State.ESP.color = colors[v]
            State.ESP.chamsColor = colors[v]
        end)

        -- Кнопка для теста
        UI.Button(espCard, "Nya~", function() API.Notify("Femboy Lua", "Chams and Box loaded! ~") end)
    end,

    onLoad = function(API)
        API.Notify("Femboy Lua", "Loaded! Box ESP & Chams ready.")
        
        -- Восстанавливаем коннекты для новых игроков
        table.insert(State.connections, Players.PlayerAdded:Connect(function(plr)
            table.insert(State.connections, plr.CharacterAdded:Connect(function()
                task.wait(1)
                if State.ESP.enabled then updateChams(plr) end
            end))
        end))
    end,

    onUnload = function()
        State.Aim.enabled = false
        stopAim()
        
        State.ESP.enabled = false
        stopESP()
        
        for _, c in ipairs(State.connections) do
            pcall(function() c:Disconnect() end)
        end
        State.connections = {}
    end,
})