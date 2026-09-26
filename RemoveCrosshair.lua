local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

local cached = nil

local function findCrosshair()
	if cached and cached.Parent then
		return cached
	end
	cached = nil

	local wsg = PlayerGui:FindFirstChild("WeaponsSystemGui")
	if wsg then
		local scaling = wsg:FindFirstChild("ScalingElements")
		if scaling then
			local ch = scaling:FindFirstChild("Crosshair")
			if ch then
				cached = ch
				return ch
			end
		end
		local ch = wsg:FindFirstChild("Crosshair", true)
		if ch then
			cached = ch
			return ch
		end
	end

	local container = PlayerGui:FindFirstChild("CrosshairContainer", true)
	if container then
		cached = container
		return container
	end

	return nil
end

local function hide(obj)
	if not obj then return end
	pcall(function()
		obj.Visible = false
		if obj:IsA("GuiObject") then
			obj.BackgroundTransparency = 1
		end
		if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			obj.ImageTransparency = 1
		end
		for _, d in ipairs(obj:GetDescendants()) do
			if d:IsA("GuiObject") then
				d.Visible = false
				d.BackgroundTransparency = 1
				if d:IsA("ImageLabel") or d:IsA("ImageButton") then
					d.ImageTransparency = 1
				end
				if d:IsA("TextLabel") or d:IsA("TextButton") then
					d.TextTransparency = 1
				end
			end
		end
	end)
end

local function wipe()
	local ch = findCrosshair()
	if ch then
		hide(ch)
	end

	local wsg = PlayerGui:FindFirstChild("WeaponsSystemGui")
	if wsg then
		for _, name in ipairs({ "Crosshair", "CrosshairContainer", "Reticle", "AimPoint" }) do
			local obj = wsg:FindFirstChild(name, true)
			if obj then hide(obj) end
		end
	end
end

wipe()

PlayerGui.DescendantAdded:Connect(function(obj)
	local n = string.lower(obj.Name)
	if n == "crosshair" or n == "crosshaircontainer" or n == "reticle" then
		task.defer(hide, obj)
	end
end)

RunService.Heartbeat:Connect(function()
	local ch = findCrosshair()
	if ch and ch.Visible then
		hide(ch)
	end
end)

print("[RemoveCrosshair] loaded")
