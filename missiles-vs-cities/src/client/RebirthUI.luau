-- Rebirth confirmation panel, opened from the golden shrine in the lobby.

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)
local UILib = require(script.Parent.UILib)

local RebirthUI = {}

local ctx
local gui
local infoLabel
local confirmButton

local function refresh()
	local state = ctx.State.get()
	if not state then
		return
	end
	local nextMult = 1 + (state.rebirths + 1) * Config.Rebirth.IncomePerRebirth
	infoLabel.Text = "\u{1F31F} Rebirths so far: " .. state.rebirths
		.. "\n\nRebirthing RESETS your buildings and cash,\nbut your income becomes x" .. nextMult
		.. " FOREVER!\n(You keep gems, rocket level and nuke access.)"
	local afford = state.cash >= state.rebirthCost
	confirmButton.Text = "REBIRTH — \u{1F4B5} " .. NumberFormat.abbrev(state.rebirthCost)
	confirmButton.BackgroundColor3 = afford and UILib.Colors.Gold or UILib.Colors.Gray
end

function RebirthUI.init(context)
	ctx = context
	local panelGui, content = UILib.panel("MVC_Rebirth", "\u{1F31F} Rebirth Shrine", UDim2.new(0, 420, 0, 300), 14)
	gui = panelGui

	infoLabel = UILib.text({
		Size = UDim2.new(1, -20, 0, 160),
		Position = UDim2.new(0, 10, 0, 8),
		Text = "",
		TextWrapped = true,
	}, content)

	confirmButton = UILib.button({
		Size = UDim2.new(1, -20, 0, 56),
		Position = UDim2.new(0, 10, 1, -70),
		Text = "REBIRTH",
		BackgroundColor3 = UILib.Colors.Gold,
	}, content, function()
		Remotes.Events.RequestRebirth:FireServer()
		gui.Enabled = false
	end)

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name == "RebirthPrompt" then
			refresh()
			gui.Enabled = true
		end
	end)

	ctx.State.changed.Event:Connect(function()
		if gui.Enabled then
			refresh()
		end
	end)
end

return RebirthUI
