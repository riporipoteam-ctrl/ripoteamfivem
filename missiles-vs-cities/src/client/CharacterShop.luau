-- Tilly's Character Shop: speed/jump tiers, rainbow trail and titles.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local UILib = require(script.Parent.UILib)

local CharacterShop = {}

local ctx
local gui
local buttons = {}

local function makeItem(content, order, id, color)
	local button = UILib.button({
		Size = UDim2.new(1, -16, 0, 46),
		Position = UDim2.new(0, 8, 0, 8 + (order - 1) * 56),
		Text = "",
		BackgroundColor3 = color or UILib.Colors.Green,
	}, content, function()
		Remotes.Events.ShopBuy:FireServer(id)
	end)
	buttons[id] = button
	return button
end

local function refresh()
	local state = ctx.State.get()
	local cos = state and state.cosmetics or {}
	local speedTier = cos.speed or 0
	local jumpTier = cos.jump or 0

	local speedCost = Config.Character.SpeedCosts[speedTier + 1]
	buttons.cos_speed.Text = speedCost
		and ("\u{1F45F} Speed Boost " .. (speedTier + 1) .. "/3 — \u{1F48E} " .. speedCost)
		or "\u{1F45F} Speed Boost MAXED!"

	local jumpCost = Config.Character.JumpCosts[jumpTier + 1]
	buttons.cos_jump.Text = jumpCost
		and ("\u{1F998} Jump Boost " .. (jumpTier + 1) .. "/3 — \u{1F48E} " .. jumpCost)
		or "\u{1F998} Jump Boost MAXED!"

	buttons.cos_trail.Text = cos.trail
		and "\u{1F308} Rainbow Trail OWNED!"
		or ("\u{1F308} Rainbow Trail — \u{1F48E} " .. Config.Character.TrailCost)

	for _, titleDef in ipairs(Config.Character.Titles) do
		local button = buttons["cos_title_" .. titleDef.id]
		if button then
			button.Text = (cos.title == titleDef.id and "\u{2705} " or "")
				.. titleDef.label .. " — \u{1F48E} " .. titleDef.cost
		end
	end
end

function CharacterShop.toggle()
	gui.Enabled = not gui.Enabled
	if gui.Enabled then
		refresh()
	end
end

function CharacterShop.init(context)
	ctx = context
	local panelGui, content = UILib.panel("MVC_CharShop", "\u{2728} Character Shop", UDim2.new(0, 400, 0, 400), 12)
	gui = panelGui

	makeItem(content, 1, "cos_speed")
	makeItem(content, 2, "cos_jump")
	makeItem(content, 3, "cos_trail", UILib.Colors.Purple)
	local order = 4
	for _, titleDef in ipairs(Config.Character.Titles) do
		makeItem(content, order, "cos_title_" .. titleDef.id, UILib.Colors.Gold)
		order += 1
	end

	ctx.State.changed.Event:Connect(function()
		if gui.Enabled then
			refresh()
		end
	end)
end

return CharacterShop
