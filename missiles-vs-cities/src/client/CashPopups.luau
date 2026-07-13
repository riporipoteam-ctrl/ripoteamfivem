-- Floating green "+$" popups above earning buildings, like the reference game.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Layout = require(Shared.Layout)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)

local CashPopups = {}

local active = 0
local MAX_ACTIVE = 45
local rng = Random.new()

local function popup(worldPos, amount)
	if active >= MAX_ACTIVE then
		return
	end
	active += 1

	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.5, 0.5, 0.5)
	holder.Position = worldPos + Vector3.new(rng:NextNumber(-8, 8), 10, rng:NextNumber(-8, 8))
	holder.Parent = workspace

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(12, 0, 4, 0)
	gui.StudsOffset = Vector3.new(0, 2, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 400
	gui.Parent = holder

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(110, 240, 90)
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Text = "+" .. NumberFormat.abbrev(amount)
	label.Parent = gui

	TweenService:Create(gui, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 9, 0),
	}):Play()
	TweenService:Create(label, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()

	task.delay(1.25, function()
		holder:Destroy()
		active -= 1
	end)
end

function CashPopups.init()
	Remotes.Events.IncomePops.OnClientEvent:Connect(function(plotIndex, pops)
		if type(plotIndex) ~= "number" or type(pops) ~= "table" then
			return
		end
		for _, entry in ipairs(pops) do
			local zi, amt = entry[1], entry[2]
			if type(zi) == "number" and type(amt) == "number" then
				popup(Layout.zoneCenter(plotIndex, zi), amt)
			end
		end
	end)
end

return CashPopups
