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
	holder.Size = UDim2.new(0, 620, 0, 96)
	holder.Parent = gui

	local gemsLabel = UILib.text({
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 0, 0),
		Text = "\u{1F48E} 0",
		TextColor3 = Color3.fromRGB(220, 130, 250),
	}, holder)

	local cashLabel = UILib.text({
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 0, 26),
		Text = "\u{1F4B5} 0",
		TextColor3 = Color3.fromRGB(140, 245, 120),
	}, holder)

	local incomeLabel = UILib.text({
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 68),
		Text = "",
		TextColor3 = Color3.fromRGB(200, 235, 190),
	}, holder)

	local rebirthLabel = UILib.text({
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 0, 90),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 230, 120),
	}, holder)

	ctx.State.changed.Event:Connect(function(data)
		targetCash = data.cash
		gemsLabel.Text = "\u{1F48E} " .. NumberFormat.commas(data.gems)
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
			cashLabel.Text = "\u{1F4B5} " .. NumberFormat.commas(displayedCash)
		end
	end)
end

return HUD
