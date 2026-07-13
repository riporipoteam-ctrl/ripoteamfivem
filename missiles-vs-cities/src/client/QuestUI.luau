-- Quest tracker panel: one card per quest chain with progress bars.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NumberFormat = require(Shared.NumberFormat)
local UILib = require(script.Parent.UILib)

local QuestUI = {}

local ctx
local gui
local cards = {}

local function makeCard(parent, order)
	local card = UILib.frame({
		Size = UDim2.new(1, -8, 0, 118),
		Position = UDim2.new(0, 4, 0, 8 + (order - 1) * 128),
		BackgroundColor3 = UILib.Colors.LightBlue,
	}, parent)

	local title = UILib.text({
		Size = UDim2.new(1, -16, 0, 26),
		Position = UDim2.new(0, 8, 0, 4),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	local questName = UILib.text({
		Size = UDim2.new(1, -16, 0, 24),
		Position = UDim2.new(0, 8, 0, 32),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 235, 160),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	local desc = UILib.text({
		Size = UDim2.new(1, -16, 0, 20),
		Position = UDim2.new(0, 8, 0, 58),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	local barBack = UILib.frame({
		Size = UDim2.new(1, -16, 0, 22),
		Position = UDim2.new(0, 8, 0, 86),
		BackgroundColor3 = UILib.Colors.DarkGray,
	}, card)
	local barFill = UILib.frame({
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = UILib.Colors.Green,
	}, barBack)
	local barText = UILib.text({
		Size = UDim2.fromScale(1, 1),
		Text = "",
	}, barBack)

	return { card = card, title = title, questName = questName, desc = desc, barFill = barFill, barText = barText }
end

local function refresh(quests)
	if not quests then
		return
	end
	local order = 1
	for _, chainId in ipairs({ "mayor", "general" }) do
		local data = quests[chainId]
		local card = cards[order]
		if data and card then
			card.title.Text = data.title or ""
			if data.done then
				card.questName.Text = "\u{2705} All quests complete!"
				card.desc.Text = "You finished this whole quest line. Legend!"
				card.barFill.Size = UDim2.fromScale(1, 1)
				card.barText.Text = "DONE"
			else
				card.questName.Text = "\u{1F4DC} Quest " .. data.number .. "/" .. data.total .. ": " .. data.name
					.. (data.repeatable and " (\u{221E} repeatable)" or "")
				card.desc.Text = data.desc
				local frac = math.clamp(data.progress / math.max(data.goal, 1), 0, 1)
				card.barFill.Size = UDim2.fromScale(frac, 1)
				card.barText.Text = NumberFormat.abbrev(data.progress) .. " / " .. NumberFormat.abbrev(data.goal)
			end
		end
		order += 1
	end
end

function QuestUI.toggle()
	gui.Enabled = not gui.Enabled
	if gui.Enabled then
		local state = ctx.State.get()
		if state then
			refresh(state.quests)
		end
	end
end

function QuestUI.init(context)
	ctx = context
	local panelGui, content = UILib.panel("MVC_Quests", "\u{1F4DC} Quests", UDim2.new(0, 460, 0, 300), 12)
	gui = panelGui

	cards[1] = makeCard(content, 1)
	cards[2] = makeCard(content, 2)

	ctx.State.changed.Event:Connect(function(state)
		if gui.Enabled and state.quests then
			refresh(state.quests)
		end
	end)
end

return QuestUI
