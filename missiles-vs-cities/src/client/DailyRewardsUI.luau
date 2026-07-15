-- Daily Rewards calendar: 6 blue day-cards in a grid plus the tall
-- rainbow Day 7 card (free nuke), just like the reference screenshots.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)
local UILib = require(script.Parent.UILib)

local DailyRewardsUI = {}

local ctx
local gui
local cards = {}
local dailyData = nil

local function makeCard(parent, dayNumber, big)
	local reward = Config.DailyRewards[dayNumber]
	local card = UILib.frame({
		Size = big and UDim2.new(0, 150, 0, 268) or UDim2.new(0, 118, 0, 128),
		BackgroundColor3 = UILib.Colors.LightBlue,
	}, parent)

	if big then
		local rainbow = Instance.new("UIGradient")
		rainbow.Rotation = 90
		rainbow.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 200, 60)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 220, 90)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 160, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 90, 240)),
		})
		rainbow.Parent = card
	end

	UILib.text({
		Size = UDim2.new(1, -8, 0, big and 34 or 24),
		Position = UDim2.new(0, 4, 0, 4),
		Text = "DAY " .. dayNumber,
	}, card)

	local emojiLabel = UILib.text({
		Size = UDim2.new(1, -8, 0, big and 80 or 38),
		Position = UDim2.new(0, 4, 0, big and 44 or 28),
		Text = reward and reward.emoji or "\u{2753}",
	}, card)

	local nameLabel = UILib.text({
		Size = UDim2.new(1, -8, 0, big and 30 or 20),
		Position = UDim2.new(0, 4, 0, big and 130 or 66),
		Text = reward and reward.label or "Mystery",
		TextColor3 = big and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(235, 250, 255),
	}, card)

	local statusButton = UILib.button({
		Size = UDim2.new(1, -16, 0, big and 44 or 32),
		Position = UDim2.new(0, 8, 1, big and -52 or -38),
		Text = "Locked!",
		BackgroundColor3 = UILib.Colors.Gray,
	}, card, function()
		if dailyData and dailyData.canClaim and dailyData.dayIndex == dayNumber then
			Remotes.Events.ClaimDaily:FireServer()
		end
	end)

	cards[dayNumber] = { button = statusButton, emoji = emojiLabel, name = nameLabel }
	return card
end

local function refresh()
	if not dailyData then
		return
	end
	-- Paint the randomized rewards the server sent this cycle.
	if dailyData.rewards then
		for dayNumber, card in pairs(cards) do
			local reward = dailyData.rewards[dayNumber]
			if reward then
				card.emoji.Text = reward.emoji
				card.name.Text = reward.label
			end
		end
	end
	for dayNumber, card in pairs(cards) do
		local button = card.button
		if dayNumber < dailyData.dayIndex then
			button.Text = "Claimed"
			button.BackgroundColor3 = UILib.Colors.Gray
		elseif dayNumber == dailyData.dayIndex then
			if dailyData.canClaim then
				button.Text = "CLAIM!"
				button.BackgroundColor3 = UILib.Colors.Green
			else
				button.Text = NumberFormat.clock(dailyData.nextIn)
				button.BackgroundColor3 = UILib.Colors.DarkGray
			end
		else
			button.Text = "Locked!"
			button.BackgroundColor3 = UILib.Colors.Gray
		end
	end
end

function DailyRewardsUI.toggle()
	gui.Enabled = not gui.Enabled
	if gui.Enabled then
		refresh()
	end
end

function DailyRewardsUI.init(context)
	ctx = context

	local panelGui, content = UILib.panel("MVC_Daily", "DAILY REWARDS", UDim2.new(0, 560, 0, 320), 12)
	gui = panelGui

	-- Calendar badge sticking out of the header's top-left (reference style).
	local frame = content.Parent
	local badge = UILib.frame({
		Size = UDim2.new(0, 60, 0, 64),
		Position = UDim2.new(0, -8, 0, -40),
		BackgroundColor3 = Color3.fromRGB(245, 245, 250),
	}, frame)
	UILib.frame({
		Size = UDim2.new(1, -8, 0, 20),
		Position = UDim2.new(0, 4, 0, 4),
		BackgroundColor3 = UILib.Colors.Red,
	}, badge)
	UILib.text({
		Size = UDim2.new(1, -8, 0, 32),
		Position = UDim2.new(0, 4, 0, 26),
		Text = "31",
		TextColor3 = Color3.fromRGB(40, 50, 80),
	}, badge)

	-- Days 1-6 in a 3x2 grid on the left.
	local grid = Instance.new("Frame")
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.new(0, 380, 1, -10)
	grid.Position = UDim2.new(0, 0, 0, 5)
	grid.Parent = content
	for day = 1, 6 do
		local card = makeCard(grid, day, false)
		local col = (day - 1) % 3
		local row = (day - 1) // 3
		card.Position = UDim2.new(0, col * 128, 0, row * 140)
	end

	-- Big Day 7 card on the right.
	local day7 = makeCard(content, 7, true)
	day7.Position = UDim2.new(1, -156, 0, 5)

	Remotes.Events.DailyData.OnClientEvent:Connect(function(data)
		dailyData = data
		refresh()
	end)
	ctx.State.changed.Event:Connect(function(state)
		if state.daily then
			dailyData = state.daily
			if gui.Enabled then
				refresh()
			end
		end
	end)

	-- Live countdown while the panel is open.
	task.spawn(function()
		while true do
			task.wait(1)
			if gui.Enabled and dailyData and not dailyData.canClaim and dailyData.nextIn > 0 then
				dailyData.nextIn = math.max(0, dailyData.nextIn - 1)
				if dailyData.nextIn == 0 then
					dailyData.canClaim = true
				end
				refresh()
			end
		end
	end)
end

return DailyRewardsUI
