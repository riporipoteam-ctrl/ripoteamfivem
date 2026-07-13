-- "Rocket N · Lv X" panel (opened at your silo): Launch + Upgrade buttons.
-- Also routes the Nuke Island silo prompt into nuke attack mode.

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)
local UILib = require(script.Parent.UILib)

local RocketPanel = {}

local ctx
local gui
local titleLabel
local statsLabel
local upgradeButton
local launchButton

local function refresh()
	local state = ctx.State.get()
	if not state then
		return
	end
	titleLabel.Text = "\u{1F680} Rocket \u{00B7} Lv " .. state.rocketLevel
	statsLabel.Text = "\u{1F4A5} Damage: " .. NumberFormat.abbrev(state.rocketDamage)
		.. "   \u{1F4CD} Blast: " .. Config.Rocket.BlastRadius .. " studs"

	local remaining = ctx.State.remaining("rocketRemaining")
	if remaining > 0 then
		launchButton.Text = "\u{23F3} " .. NumberFormat.clock(remaining)
	else
		launchButton.Text = "Launch"
	end

	if state.rocketLevel >= Config.Rocket.MaxLevel then
		upgradeButton.Text = "MAX LEVEL"
	else
		upgradeButton.Text = "Upgrade  \u{1F4B5} " .. NumberFormat.abbrev(state.rocketCost)
	end
end

function RocketPanel.init(context)
	ctx = context

	local panelGui, content = UILib.panel("MVC_RocketPanel", "\u{1F680} Rocket Silo", UDim2.new(0, 340, 0, 250), 15)
	gui = panelGui

	titleLabel = UILib.text({
		Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.new(0, 0, 0, 8),
		Text = "",
	}, content)

	statsLabel = UILib.text({
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 44),
		Text = "",
		TextColor3 = Color3.fromRGB(200, 210, 230),
	}, content)

	launchButton = UILib.button({
		Size = UDim2.new(1, -20, 0, 56),
		Position = UDim2.new(0, 10, 0, 76),
		Text = "Launch",
		BackgroundColor3 = UILib.Colors.Green,
	}, content, function()
		if ctx.State.remaining("rocketRemaining") > 0 then
			ctx.Notifier.show("\u{1F680} Rocket is reloading!", "bad")
			return
		end
		gui.Enabled = false
		ctx.AttackView.open(false)
	end)

	upgradeButton = UILib.button({
		Size = UDim2.new(1, -20, 0, 52),
		Position = UDim2.new(0, 10, 0, 142),
		Text = "Upgrade",
		BackgroundColor3 = UILib.Colors.Green,
	}, content, function()
		Remotes.Events.UpgradeRocket:FireServer()
	end)

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name == "RocketPrompt" then
			refresh()
			gui.Enabled = true
		elseif prompt.Name == "NukePrompt" then
			local state = ctx.State.get()
			if state and (state.nukeOwned or (state.nukeCharges or 0) > 0) then
				ctx.AttackView.open(true)
			else
				ctx.Notifier.show("\u{2622}\u{FE0F} You need Nuke Access! Step on the purple pad ("
					.. "\u{1F4B5} " .. NumberFormat.abbrev(Config.Nuke.IslandCost) .. ") or claim the Day 7 daily reward.", "bad")
			end
		end
	end)

	ctx.State.changed.Event:Connect(function()
		if gui.Enabled then
			refresh()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			if gui.Enabled then
				refresh()
			end
		end
	end)
end

return RocketPanel
