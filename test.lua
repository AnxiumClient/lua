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
    warn("[ExamplePlugin] Anxium API missing - start from Scripts tab")
    return
end

local PLUGIN_ID = "example_plugin"
local state = {
    enabled = false,
    speed = 50,
    mode = "Normal",
}
local setEnabledVisual

local ok, err = Anxium.RegisterPlugin({
    id = PLUGIN_ID,
    name = "Example Plugin",
    icon = "rbxassetid://79541605299928",
    version = "1.0.0",
    author = "Anxium",

    buildUI = function(parent, UI, API)
        local main = UI.Section("Main")

        local _, getEn, setEn = UI.Toggle(main, "Enabled", false, function(on)
            state.enabled = on
            API.Notify("Example", on and "ON" or "OFF")
        end)
        setEnabledVisual = setEn

        UI.Slider(main, "Speed", 1, 100, 50, function(v)
            state.speed = v
        end)

        UI.Dropdown(main, "Mode", { "Normal", "Fast", "Slow" }, "Normal", function(v)
            state.mode = v
        end)

        API.RegisterBind("Example Plugin Enabled", function()
            return state.enabled == true
        end, function(v)
            state.enabled = v and true or false
            if setEnabledVisual then
                setEnabledVisual(state.enabled)
            end
        end)

        local actions = UI.Section("Actions")
        UI.Button(actions, "Test Notify", function()
            API.Notify("Example", "Speed=" .. tostring(state.speed) .. " Mode=" .. tostring(state.mode))
        end)
        UI.Label(actions, "Bind: Settings -> Binds")
    end,

    onLoad = function(API)
        local cfg = API.GetConfig()
        state.enabled = cfg.tog_Enabled == true
        state.speed = tonumber(cfg.sld_Speed) or 50
        state.mode = cfg.dd_Mode or "Normal"
        if setEnabledVisual then
            setEnabledVisual(state.enabled)
        end
        API.Notify("Example Plugin", "Loaded")
    end,

    onUnload = function()
    end,
})

if not ok then
    warn("[ExamplePlugin] Register failed:", tostring(err))
end
