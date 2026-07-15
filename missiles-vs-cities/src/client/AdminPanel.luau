-- Admin Panel: only visible to admins (UserIds in Config.Admins). A gold
-- badge button opens a panel of moderation / testing tools.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local UILib = require(script.Parent.UILib)

local AdminPanel = {}

local ctx
local buttonGui
local panelGui

local ACTIONS = {
	{ id = "give_cash", label = "\u{1F4B5} +$1B Cash", arg = 1e9 },
	{ id = "give_gems", label = "\u{1F48E} +1000 Gems", arg = 1000 },
	{ id = "max_rockets", label = "\u{1F680} Max Rockets + Silos" },
	{ id = "give_nuke", label = "\u{2622}\u{FE0F} Nuke Access + Reset" },
	{ id = "unlock_all", label = "\u{1F513} Unlock All Areas" },
	{ id = "repair", label = "\u{1F527} Repair City" },
	{ id = "trigger_event", label = "\u{1F3B2} Trigger Random Event" },
	{ id = "trigger_pilot", label = "\u{1F468}\u{200D}\u{2708}\u{FE0F} Trigger Pilot Event" },
}

function AdminPanel.init(context)
	ctx = context

	local pg, content = UILib.panel("MVC_AdminPanel", "\u{1F6E0}\u{FE0F} ADMIN PANEL", UDim2.new(0, 400, 0, 470), 35)
	panelGui = pg

	for i, act in ipairs(ACTIONS) do
		UILib.button({
			Size = UDim2.new(1, -16, 0, 46),
			Position = UDim2.new(0, 8, 0, 8 + (i - 1) * 54),
			Text = act.label,
			BackgroundColor3 = UILib.Colors.Gold,
		}, content, function()
			Remotes.Events.AdminAction:FireServer(act.id, act.arg)
		end)
	end

	-- The launcher button (hidden unless the player is an admin).
	buttonGui = UILib.screen("MVC_AdminBtn", 34)
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.new(1, -14, 0, 130)
	frame.Size = UDim2.new(0, 76, 0, 88)
	frame.Visible = false
	frame.Parent = buttonGui

	local button = UILib.button({
		Size = UDim2.new(0, 68, 0, 60),
		Position = UDim2.new(0, 4, 0, 0),
		Text = "",
		BackgroundColor3 = UILib.Colors.Gold,
	}, frame, function()
		panelGui.Enabled = not panelGui.Enabled
	end)
	local icon = UILib.icon("admin", button)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.new(0, 40, 0, 40)
	UILib.text({
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 0, 62),
		Text = "Admin",
	}, frame)

	ctx.State.changed.Event:Connect(function(state)
		frame.Visible = state.isAdmin == true
	end)
end

return AdminPanel
