local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function hideCrosshairImages()
    local hud = PlayerGui:FindFirstChild("HUD")
    if hud then
        local crosshair = hud:FindFirstChild("Crosshair")
        if crosshair then
            for _, obj in ipairs(crosshair:GetDescendants()) do
                if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                    obj.Visible = false
                end
            end
        end
    end

    local independent = PlayerGui:FindFirstChild("Independent")
    if independent then
        local killfeed = independent:FindFirstChild("Killfeed")
        if killfeed and killfeed:FindFirstChild("Container") then
            for _, obj in ipairs(killfeed.Container:GetDescendants()) do
                if obj.Name == "Noscope" and (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then
                    obj.Visible = false
                end
            end
        end
    end
    
    print("RC-DS.lua loaded!")
end

hideCrosshairImages()
