-- Admin Panel: gold badge button (admins only) opening a panel of tools.
-- Self actions, server/cross-server actions, an announce box, and targeted
-- actions (kick/ban/wipe/nuke) against a selected player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local UILib = require(script.Parent.UILib)

local AdminPanel = {}

local ctx
local buttonGui
local panelGui
local selectedUserId = nil
local selectedName = "(none)"
local targetLabel
local announceBox

local SELF_ACTIONS = {
	{ id = "give_cash", label = "\u{1F4B5} +$1B", arg = 1e9 },
	{ id = "give_gems", label = "\u{1F48E} +1000", arg = 1000 },
	{ id = "max_rockets", label = "\u{1F680} Max Rockets" },
	{ id = "give_nuke", label = "\u{2622}\u{FE0F} Nuke Access" },
	{ id = "unlock_all", label = "\u{1F513} Unlock All" },
	{ id = "repair", label = "\u{1F527} Repair" },
	{ id = "trigger_event", label = "\u{1F3B2} Event" },
	{ id = "trigger_pilot", label = "\u{1F468}\u{200D}\u{2708}\u{FE0F} Pilot" },
}

local SERVER_ACTIONS = {
	{ id = "nuke_server", label = "\u{2622}\u{FE0F} NUKE SERVER", color = "Red" },
	{ id = "nuke_all_servers", label = "\u{2622}\u{FE0F} NUKE ALL SERVERS", color = "Red" },
}

local TARGET_ACTIONS = {
	{ id = "kick", label = "\u{1F462} Kick" },
	{ id = "ban", label = "\u{1F6AB} Ban", color = "Red" },
	{ id = "nuke_player", label = "\u{2622}\u{FE0F} Nuke City" },
	{ id = "take_cash", label = "\u{1F4B8} Wipe Cash" },
	{ id = "take_gems", label = "\u{1F48E} Wipe Gems" },
}

local function refreshTarget()
	targetLabel.Text = "Target: " .. selectedName
end

local function buildPlayerList(parent)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 0, 90)
	scroll.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 5
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	UILib.corner(scroll, 6)
	scroll.Parent = parent
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 4)
	list.Parent = scroll
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.Parent = scroll

	local function rebuild()
		for _, c in ipairs(scroll:GetChildren()) do
			if c:IsA("TextButton") then
				c:Destroy()
			end
		end
		for _, plr in ipairs(Players:GetPlayers()) do
			UILib.button({
				Size = UDim2.new(1, -12, 0, 30),
				Text = plr.DisplayName,
				BackgroundColor3 = UILib.Colors.Blue,
			}, scroll, function()
				selectedUserId = plr.UserId
				selectedName = plr.DisplayName
				refreshTarget()
			end)
		end
	end
	rebuild()
	Players.PlayerAdded:Connect(rebuild)
	Players.PlayerRemoving:Connect(rebuild)
end

function AdminPanel.init(context)
	ctx = context

	local pg, content = UILib.panel("MVC_AdminPanel", "\u{1F6E0}\u{FE0F} ADMIN", UDim2.new(0, 460, 0, 560), 35)
	panelGui = pg

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = content
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = scroll

	local function heading(text)
		UILib.text({
			Size = UDim2.new(1, -8, 0, 22),
			Text = text,
			TextColor3 = Color3.fromRGB(255, 220, 120),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, scroll)
	end

	local function grid(actions)
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.new(1, 0, 0, math.ceil(#actions / 2) * 42)
		holder.Parent = scroll
		local g = Instance.new("UIGridLayout")
		g.CellSize = UDim2.new(0.5, -6, 0, 38)
		g.CellPadding = UDim2.new(0, 6, 0, 4)
		g.Parent = holder
		for _, act in ipairs(actions) do
			UILib.button({
				Size = UDim2.new(0.5, -6, 0, 38),
				Text = act.label,
				BackgroundColor3 = act.color and UILib.Colors[act.color] or UILib.Colors.Gold,
			}, holder, function()
				Remotes.Events.AdminAction:FireServer(act.id, act.arg or selectedUserId)
			end)
		end
	end

	heading("\u{1F464} Self")
	grid(SELF_ACTIONS)

	heading("\u{1F310} Server")
	grid(SERVER_ACTIONS)

	heading("\u{1F4E2} Announce")
	announceBox = Instance.new("TextBox")
	announceBox.Size = UDim2.new(1, 0, 0, 34)
	announceBox.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
	announceBox.TextColor3 = Color3.new(1, 1, 1)
	announceBox.Font = UILib.Font
	announceBox.TextSize = 18
	announceBox.PlaceholderText = "Type an announcement..."
	announceBox.Text = ""
	announceBox.ClearTextOnFocus = false
	announceBox.BorderSizePixel = 0
	UILib.corner(announceBox, 6)
	announceBox.Parent = scroll

	local announceHolder = Instance.new("Frame")
	announceHolder.BackgroundTransparency = 1
	announceHolder.Size = UDim2.new(1, 0, 0, 40)
	announceHolder.Parent = scroll
	local ag = Instance.new("UIGridLayout")
	ag.CellSize = UDim2.new(0.5, -6, 0, 38)
	ag.CellPadding = UDim2.new(0, 6, 0, 4)
	ag.Parent = announceHolder
	UILib.button({
		Size = UDim2.new(0.5, -6, 0, 38),
		Text = "\u{1F4E2} This Server",
		BackgroundColor3 = UILib.Colors.Gold,
	}, announceHolder, function()
		Remotes.Events.AdminAction:FireServer("announce_server", announceBox.Text)
	end)
	UILib.button({
		Size = UDim2.new(0.5, -6, 0, 38),
		Text = "\u{1F4E2} All Servers",
		BackgroundColor3 = UILib.Colors.Gold,
	}, announceHolder, function()
		Remotes.Events.AdminAction:FireServer("announce_all", announceBox.Text)
	end)

	heading("\u{1F3AF} Target Player")
	targetLabel = UILib.text({
		Size = UDim2.new(1, -8, 0, 20),
		Text = "Target: (none)",
		TextXAlignment = Enum.TextXAlignment.Left,
	}, scroll)
	buildPlayerList(scroll)
	grid(TARGET_ACTIONS)

	-- Launcher badge button.
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
