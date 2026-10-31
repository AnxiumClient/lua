local Anxium = getgenv().Anxium or shared.Anxium
if not Anxium then return warn("Start from Anxium Scripts") end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local State = {
    Aim = { enabled = false, fov = 150, smooth = 0.3, part = "Head" },
    ESP = { enabled = false, part = "Head", color = Color3.fromRGB(255, 105, 180) },
    aimConn = nil,
    espConns = {},
    espObjects = {},
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
                local sp, onScreen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
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
            local cam = workspace.CurrentCamera
            local desired = CFrame.new(cam.CFrame.Position, target.Position)
            cam.CFrame = cam.CFrame:Lerp(desired, State.Aim.smooth)
        end
    end)
end

local function stopAim()
    if State.aimConn then
        State.aimConn:Disconnect()
        State.aimConn = nil
    end
end

-- ===== ESP =====
local function clearESP()
    for _, obj in pairs(State.espObjects) do
        if obj.bb then obj.bb:Destroy() end
    end
    State.espObjects = {}
    for _, c in ipairs(State.espConns) do
        pcall(function() c:Disconnect() end)
    end
    State.espConns = {}
end

local function addESP(plr)
    if State.espObjects[plr] then return end
    local part = getPart(plr, State.ESP.part)
    if not part then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "FemboyLuaESP"
    bb.Size = UDim2.new(0, 200, 0, 40)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = part
    bb.Parent = part

    local nameLbl = Instance.new("TextLabel")
    nameLbl.BackgroundTransparency = 1
    nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 14
    nameLbl.TextColor3 = State.ESP.color
    nameLbl.TextStrokeTransparency = 0
    nameLbl.Text = plr.Name
    nameLbl.Parent = bb

    local distLbl = Instance.new("TextLabel")
    distLbl.BackgroundTransparency = 1
    distLbl.Size = UDim2.new(1, 0, 0.5, 0)
    distLbl.Position = UDim2.new(0, 0, 0.5, 0)
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextSize = 12
    distLbl.TextColor3 = Color3.new(1, 1, 1)
    distLbl.TextStrokeTransparency = 0
    distLbl.Text = ""
    distLbl.Parent = bb

    State.espObjects[plr] = { bb = bb, dist = distLbl }

    local conn = RunService.RenderStepped:Connect(function()
        if not State.ESP.enabled then
            bb.Enabled = false
            return
        end
        local char = getChar(plr)
        if not char then
            bb.Enabled = false
            return
        end
        bb.Enabled = true
        local p = char:FindFirstChild(State.ESP.part) or char:FindFirstChild("HumanoidRootPart")
        if p then bb.Adornee = p end
        local lp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if lp and p then
            distLbl.Text = string.format("%d studs", math.floor((p.Position - lp.Position).Magnitude))
        end
    end)
    table.insert(State.espConns, conn)
end

local function startESP()
    clearESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then addESP(plr) end
    end
    table.insert(State.espConns, Players.PlayerAdded:Connect(function(p)
        if State.ESP.enabled then addESP(p) end
    end))
    table.insert(State.espConns, Players.PlayerRemoving:Connect(function(p)
        local o = State.espObjects[p]
        if o and o.bb then o.bb:Destroy() end
        State.espObjects[p] = nil
    end))
end

local function stopESP()
    clearESP()
end

-- ===== Plugin =====
Anxium.RegisterPlugin({
    id = "femboy_lua",
    name = "Femboy Lua",
    icon = "rbxassetid://113164012451432",

    buildUI = function(parent, UI, API)
        -- Aimlock section
        local aimCard = UI.Section("Aimlock")
        local _, aimGet, aimSet = UI.Toggle(aimCard, "Aimlock Enabled", false, function(on)
            State.Aim.enabled = on
            if on then startAim() else stopAim() end
        end)
        API.RegisterBind("Aimlock Toggle", aimGet, aimSet)

        UI.Slider(aimCard, "FOV (px)", 10, 800, 150, function(v)
            State.Aim.fov = v
        end)
        UI.Slider(aimCard, "Smoothness", 0.05, 1, 0.3, function(v)
            State.Aim.smooth = v
        end)
        UI.Dropdown(aimCard, "Aim Part", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, "Head", function(v)
            State.Aim.part = v
        end)

        -- ESP section
        local espCard = UI.Section("ESP")
        local _, espGet, espSet = UI.Toggle(espCard, "ESP Enabled", false, function(on)
            State.ESP.enabled = on
            if on then startESP() else stopESP() end
        end)
        API.RegisterBind("ESP Toggle", espGet, espSet)

        UI.Dropdown(espCard, "ESP Anchor", {"Head", "HumanoidRootPart", "UpperTorso"}, "Head", function(v)
            State.ESP.part = v
            if State.ESP.enabled then startESP() end
        end)
        UI.Button(espCard, "Ping", function() API.Notify("Femboy Lua", "nya~") end)
    end,

    onLoad = function(API)
        API.Notify("Femboy Lua", "Loaded! nya~")
    end,

    onUnload = function()
        State.Aim.enabled = false
        stopAim()
        State.ESP.enabled = false
        stopESP()
    end,
})