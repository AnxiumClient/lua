local Anxium = getgenv().Anxium or shared.Anxium
if not Anxium then
    return warn("Femboy Lua: start this plugin from Anxium Scripts")
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local PLUGIN_ID = "femboy_lua"
local PLUGIN_NAME = "Femboy Lua"
local ICON = "rbxassetid://113164012451432"

local state = {
    espEnabled = false,
    aimEnabled = false,
    maxDistance = 500,
    aimSmoothness = 0.18,
}

local highlights = {}
local billboards = {}
local renderConnection
local unloadRequested = false

local function getTestFolder()
    -- For safety, this demo only scans explicitly marked test dummies.
    -- Create Workspace.FemboyLuaTestTargets and place NPC/dummy Models inside.
    return Workspace:FindFirstChild("FemboyLuaTestTargets")
end

local function getModelPart(model)
    return model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
        or model:FindFirstChild("Head")
end

local function isTestTarget(model)
    if not model or not model:IsA("Model") then
        return false
    end
    if Players:GetPlayerFromCharacter(model) then
        return false
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    return humanoid ~= nil and getModelPart(model) ~= nil
end

local function clearTargetVisuals(model)
    if highlights[model] then
        highlights[model]:Destroy()
        highlights[model] = nil
    end
    if billboards[model] then
        billboards[model]:Destroy()
        billboards[model] = nil
    end
end

local function makeVisuals(model)
    if not isTestTarget(model) then
        return
    end

    if not highlights[model] or not highlights[model].Parent then
        local highlight = Instance.new("Highlight")
        highlight.Name = "FemboyLua_TestESP"
        highlight.FillColor = Color3.fromRGB(180, 90, 255)
        highlight.OutlineColor = Color3.fromRGB(245, 235, 255)
        highlight.FillTransparency = 0.72
        highlight.OutlineTransparency = 0.05
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = model
        highlight.Parent = model
        highlights[model] = highlight
    end

    local part = getModelPart(model)
    if part and (not billboards[model] or not billboards[model].Parent) then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "FemboyLua_TestESPLabel"
        billboard.Adornee = part
        billboard.Size = UDim2.fromOffset(160, 28)
        billboard.StudsOffset = Vector3.new(0, 2.8, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = state.maxDistance
        billboard.Parent = part

        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.BackgroundTransparency = 1
        label.Size = UDim2.fromScale(1, 1)
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 13
        label.TextColor3 = Color3.fromRGB(245, 235, 255)
        label.TextStrokeTransparency = 0.35
        label.Text = model.Name .. " [TEST]"
        label.Parent = billboard

        billboards[model] = billboard
    end
end

local function updateESP()
    local folder = getTestFolder()
    local active = {}

    if folder and state.espEnabled then
        for _, model in ipairs(folder:GetChildren()) do
            if isTestTarget(model) then
                active[model] = true
                makeVisuals(model)
                local part = getModelPart(model)
                local distance = part and (Camera.CFrame.Position - part.Position).Magnitude or math.huge
                if highlights[model] then
                    highlights[model].Enabled = distance <= state.maxDistance
                end
                if billboards[model] then
                    billboards[model].Enabled = distance <= state.maxDistance
                    billboards[model].MaxDistance = state.maxDistance
                end
            end
        end
    end

    for model in pairs(highlights) do
        if not active[model] or not state.espEnabled then
            clearTargetVisuals(model)
        end
    end
end

local function getClosestTestTarget()
    local folder = getTestFolder()
    if not folder then
        return nil
    end

    local closestPart
    local closestDistance = math.huge
    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

    for _, model in ipairs(folder:GetChildren()) do
        if isTestTarget(model) then
            local part = getModelPart(model)
            if part then
                local worldDistance = (Camera.CFrame.Position - part.Position).Magnitude
                local point, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen and worldDistance <= state.maxDistance then
                    local screenDistance = (Vector2.new(point.X, point.Y) - center).Magnitude
                    if screenDistance < closestDistance then
                        closestDistance = screenDistance
                        closestPart = part
                    end
                end
            end
        end
    end
    return closestPart
end

local function startLoop()
    if renderConnection then
        renderConnection:Disconnect()
    end

    renderConnection = RunService.RenderStepped:Connect(function()
        if unloadRequested then
            return
        end

        updateESP()

        -- Demonstration aim assist is limited to test dummies in the named folder.
        -- It never targets player characters.
        if state.aimEnabled then
            local targetPart = getClosestTestTarget()
            if targetPart then
                local cameraPosition = Camera.CFrame.Position
                local targetCFrame = CFrame.lookAt(cameraPosition, targetPart.Position)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, math.clamp(state.aimSmoothness, 0.01, 1))
            end
        end
    end)
end

local function cleanup()
    unloadRequested = true
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
    for model in pairs(highlights) do
        clearTargetVisuals(model)
    end
    table.clear(highlights)
    table.clear(billboards)
end

Anxium.RegisterPlugin({
    id = PLUGIN_ID,
    name = PLUGIN_NAME,
    icon = ICON,

    buildUI = function(parent, UI, API)
        local main = UI.Section("Test Dummy Tools")

        UI.Label(main, "Only scans NPCs inside Workspace.FemboyLuaTestTargets.")
        local _, getESP, setESP = UI.Toggle(main, "Test ESP", false, function(on)
            state.espEnabled = on
            if not on then
                for model in pairs(highlights) do
                    clearTargetVisuals(model)
                end
            end
        end)
        API.RegisterBind("Femboy Lua - Test ESP", getESP, setESP)

        local _, getAim, setAim = UI.Toggle(main, "Dummy Aim Assist", false, function(on)
            state.aimEnabled = on
        end)
        API.RegisterBind("Femboy Lua - Dummy Aim Assist", getAim, setAim)

        UI.Slider(main, "Max Distance", 50, 1000, state.maxDistance, function(value)
            state.maxDistance = value
        end)

        UI.Slider(main, "Aim Smoothness", 1, 100, math.floor(state.aimSmoothness * 100), function(value)
            state.aimSmoothness = math.clamp(value / 100, 0.01, 1)
        end)

        UI.Button(main, "Check Test Folder", function()
            if getTestFolder() then
                API.Notify(PLUGIN_NAME, "Test folder found. NPC models are ready to scan.")
            else
                API.Notify(PLUGIN_NAME, "Create Workspace.FemboyLuaTestTargets and add NPC dummies.")
            end
        end)

        UI.Button(main, "Reset Demo", function()
            state.espEnabled = false
            state.aimEnabled = false
            setESP(false)
            setAim(false)
            for model in pairs(highlights) do
                clearTargetVisuals(model)
            end
            API.Notify(PLUGIN_NAME, "Demo settings reset.")
        end)
    end,

    onLoad = function(API)
        unloadRequested = false
        startLoop()
        API.Notify(PLUGIN_NAME, "Loaded. Use test dummies only.")
    end,

    onUnload = function()
        cleanup()
    end,
})
