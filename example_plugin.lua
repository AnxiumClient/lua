--[[
  Anxium Example Plugin
  Scripts → raw URL → Start
]]

local function resolveAnxium()
    local a
    pcall(function()
        if getgenv then a = getgenv().Anxium end
    end)
    if type(a) == "table" and type(a.RegisterPlugin) == "function" then return a end
    pcall(function()
        a = shared.Anxium
    end)
    if type(a) == "table" and type(a.RegisterPlugin) == "function" then return a end
    pcall(function()
        a = _G.Anxium
    end)
    if type(a) == "table" and type(a.RegisterPlugin) == "function" then return a end
    if type(Anxium) == "table" and type(Anxium.RegisterPlugin) == "function" then
        return Anxium
    end
    return nil
end

local Anxium = resolveAnxium()
if not Anxium then
    warn("[ExamplePlugin] Anxium API not found. Update Anxium hub and Start from Scripts.")
    return
end

local PLUGIN_ID = "example_plugin"
local running = true
local state = {
    enabled = false,
    speed = 50,
    mode = "Normal",
}

local setEnabledVisual = nil

local ok, err = Anxium.RegisterPlugin({
    id = PLUGIN_ID,
    name = "Example Plugin",
    icon = "rbxassetid://79541605299928",
    version = "1.1.1",
    author = "Anxium",

    buildUI = function(parent, UI, API)
        local main = UI.Section("Main")

        local row, getEn, setEn = UI.Toggle(main, "Enabled", false, function(on)
            state.enabled = on
            API.Notify("Example", on and "Enabled" or "Disabled")
        end)
        setEnabledVisual = setEn

        UI.Slider(main, "Speed", 1, 100, 50, function(v)
            state.speed = v
        end)

        UI.Dropdown(main, "Mode", { "Normal", "Fast", "Slow" }, "Normal", function(v)
            state.mode = v
            API.Notify("Example", "Mode: " .. tostring(v))
        end)

        if API.RegisterBind then
            API.RegisterBind("Example Plugin Enabled", function()
                return state.enabled == true
            end, function(v)
                state.enabled = v and true or false
                if setEnabledVisual then
                    setEnabledVisual(state.enabled)
                end
            end)
        end

        local extra = UI.Section("Actions")

        UI.Button(extra, "Test Notify", function()
            API.Notify("Example", "Speed=" .. tostring(state.speed) .. " Mode=" .. tostring(state.mode))
        end)

        UI.Label(extra, "Bind: Settings → Binds → Example Plugin Enabled")
        UI.Color(extra, "Accent Color", "Color_ExamplePlugin_Accent", Color3.fromRGB(180, 140, 255))
    end,

    onLoad = function(API)
        local cfg = API.GetConfig()
        state.enabled = cfg.tog_Enabled == true
        state.speed = tonumber(cfg.sld_Speed) or 50
        state.mode = cfg.dd_Mode or "Normal"
        if setEnabledVisual then
            setEnabledVisual(state.enabled)
        end
        API.Notify("Example Plugin", "Loaded v1.1.1")

        task.spawn(function()
            while running do
                local alive = false
                pcall(function()
                    alive = Anxium.IsLoaded(PLUGIN_ID) == true
                end)
                if not alive then break end
                task.wait(0.25)
            end
        end)
    end,

    onUnload = function()
        running = false
    end,
})

if not ok then
    warn("[ExamplePlugin] Register failed:", err)
end
