--[[
  Anxium Example Plugin
  Загрузка: Anxium → Scripts → вставь raw-ссылку на этот файл → Start
]]

local Anxium = nil
pcall(function()
    if getgenv then Anxium = rawget(getgenv(), "Anxium") end
end)
if not Anxium then
    pcall(function() Anxium = rawget(shared, "Anxium") end)
end
if not Anxium or type(Anxium.RegisterPlugin) ~= "function" then
    return warn("[ExamplePlugin] Запусти через Anxium → Scripts (нужен getgenv().Anxium)")
end

local PLUGIN_ID = "example_plugin"
local running = true
local state = {
    enabled = false,
    speed = 50,
    mode = "Normal",
}

local ok, err = Anxium.RegisterPlugin({
    id = PLUGIN_ID,
    name = "Example Plugin",
    icon = "rbxassetid://79541605299928",
    version = "1.0.0",
    author = "Anxium",

    buildUI = function(parent, UI, API)
        local main = UI.Section("Main")

        UI.Toggle(main, "Enabled", false, function(on)
            state.enabled = on
            API.Notify("Example", on and "Enabled" or "Disabled")
        end)

        UI.Slider(main, "Speed", 1, 100, 50, function(v)
            state.speed = v
        end)

        UI.Dropdown(main, "Mode", { "Normal", "Fast", "Slow" }, "Normal", function(v)
            state.mode = v
            API.Notify("Example", "Mode: " .. tostring(v))
        end)

        local extra = UI.Section("Actions")

        UI.Button(extra, "Test Notify", function()
            API.Notify("Example", "Speed=" .. tostring(state.speed) .. " Mode=" .. tostring(state.mode))
        end)

        UI.Label(extra, "Это тестовый плагин Anxium API")
        UI.Color(extra, "Accent Color", "Color_ExamplePlugin_Accent", Color3.fromRGB(180, 140, 255))
    end,

    onLoad = function(API)
        local cfg = API.GetConfig()
        state.enabled = cfg.tog_Enabled == true
        state.speed = tonumber(cfg.sld_Speed) or 50
        state.mode = cfg.dd_Mode or "Normal"

        API.Notify("Example Plugin", "Loaded v1.0.0")

        task.spawn(function()
            while running and Anxium.IsLoaded(PLUGIN_ID) do
                if state.enabled then
                end
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
