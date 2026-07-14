-- Top-center HUD: gems, the big comma-formatted cash counter, income/s.
-- Cash smoothly counts up toward the real value for juice.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NumberFormat = require(Shared.NumberFormat)
local UILib = require(script.Parent.UILib)

local HUD = {}

local displayedCash = 0
local targetCash = 0

function HUD.init(ctx)
	local gui = UILib.screen("MVC_HUD", 5)

	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.Position = UDim2.new(0.5, 0, 0, 4)
	holder.Size = UDim2.new(0, 620, 0, 120)
	holder.Parent = gui

	-- Rounded dark "pill" backdrops keep the counters readable on any scene.
	local function pill(width, height, y)
		local frame = Instance.new("Frame")
		frame.AnchorPoint = Vector2.new(0.5, 0)
		frame.Position = UDim2.new(0.5, 0, 0, y)
		frame.Size = UDim2.new(0, width, 0, height)
		frame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
		frame.BackgroundTransparency = 0.35
		frame.BorderSizePixel = 0
		UILib.corner(frame, height / 2)
		frame.Parent = holder
		return frame
	end

	local gemsPill = pill(150, 26, 0)
	local gemIcon = UILib.icon("gem", gemsPill)
	gemIcon.Position = UDim2.new(0, 4, 0, 2)
	gemIcon.Size = UDim2.new(0, 22, 0, 22)
	local gemsLabel = UILib.text({
		Size = UDim2.new(1, -36, 1, -6),
		Position = UDim2.new(0, 30, 0, 3),
		Text = "0",
		TextColor3 = Color3.fromRGB(220, 130, 250),
	}, gemsPill)

	local cashPill = pill(430, 42, 30)
	local cashIcon = UILib.icon("cash", cashPill)
	cashIcon.Position = UDim2.new(0, 6, 0, 4)
	cashIcon.Size = UDim2.new(0, 34, 0, 34)
	local cashLabel = UILib.text({
		Size = UDim2.new(1, -56, 1, -8),
		Position = UDim2.new(0, 46, 0, 4),
		Text = "0",
		TextColor3 = Color3.fromRGB(140, 245, 120),
	}, cashPill)

	local incomePill = pill(170, 24, 76)
	local incomeLabel = UILib.text({
		Size = UDim2.new(1, -16, 1, -6),
		Position = UDim2.new(0, 8, 0, 3),
		Text = "",
		TextColor3 = Color3.fromRGB(200, 235, 190),
	}, incomePill)

	local rebirthLabel = UILib.text({
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 0, 102),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 230, 120),
	}, holder)

	ctx.State.changed.Event:Connect(function(data)
		targetCash = data.cash
		gemsLabel.Text = NumberFormat.commas(data.gems)
		incomeLabel.Text = "+" .. NumberFormat.abbrev(data.income) .. "/s"
		if (data.rebirths or 0) > 0 then
			rebirthLabel.Text = "\u{1F31F} Rebirth " .. data.rebirths .. " (x" .. (1 + data.rebirths) .. " income)"
		else
			rebirthLabel.Text = ""
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		if displayedCash ~= targetCash then
			local diff = targetCash - displayedCash
			if math.abs(diff) < math.max(1, math.abs(targetCash) * 1e-9) then
				displayedCash = targetCash
			else
				displayedCash += diff * math.min(dt * 6, 1)
			end
			cashLabel.Text = NumberFormat.commas(displayedCash)
		end
	end)
end

return HUD
