-- War & Economy panel: Auto-Collect, Air Defense, Airport hangars + jets,
-- and the Missile Battery. Purchases route through existing remotes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)
local UILib = require(script.Parent.UILib)

local MilitaryPanel = {}

local ctx
local gui
local rows = {}

local function makeRow(content, order, id, color, onClick)
	local button = UILib.button({
		Size = UDim2.new(1, -16, 0, 50),
		Position = UDim2.new(0, 8, 0, 8 + (order - 1) * 58),
		Text = "",
		BackgroundColor3 = color or UILib.Colors.Green,
	}, content, onClick)
	rows[id] = button
	return button
end

local function refresh()
	local s = ctx.State.get()
	if not s then
		return
	end
	rows.auto.Text = s.autoCollect and "\u{1F4B0} Auto-Collect: OWNED"
		or ("\u{1F4B0} Auto-Collect \u{2014} \u{1F4B5} " .. NumberFormat.abbrev(s.autoCollectCost))
	rows.defense.Text = (s.defenseLevel or 0) >= Config.Defense.MaxLevel
		and ("\u{1F6E1}\u{FE0F} Air Defense MAX (Lv" .. s.defenseLevel .. ")")
		or ("\u{1F6E1}\u{FE0F} Air Defense Lv" .. (s.defenseLevel or 0) .. " \u{2192} " .. ((s.defenseLevel or 0) + 1)
			.. " \u{2014} \u{1F4B5} " .. NumberFormat.abbrev(s.defenseCost))

	if s.hasAirport then
		rows.hangar.Visible = true
		rows.jet.Visible = true
		rows.hangar.Text = (s.nextHangarCost or 0) > 0
			and ("\u{2708}\u{FE0F} Buy Hangar " .. ((s.hangars or 0) + 1) .. " \u{2014} \u{1F4B5} " .. NumberFormat.abbrev(s.nextHangarCost))
			or ("\u{2708}\u{FE0F} Hangars MAX (" .. (s.hangars or 0) .. ")")
		rows.jet.Text = (s.jetCost or 0) > 0
			and ("\u{2708}\u{FE0F} Upgrade Jets Lv" .. (s.jetLevel or 1) .. " \u{2014} \u{1F4B5} " .. NumberFormat.abbrev(s.jetCost))
			or "\u{2708}\u{FE0F} Jets MAX LEVEL"
	else
		rows.hangar.Visible = false
		rows.jet.Visible = false
	end

	if s.batteryUnlocked then
		rows.battery.Text = "\u{1F680} Battery OWNED (side island)"
		rows.batteryUp.Visible = true
		rows.batteryUp.Text = (s.batteryUpgradeCost or 0) > 0
			and ("\u{1F680} Upgrade Battery Lv" .. (s.batteryLevel or 1) .. " \u{2014} \u{1F4B5} " .. NumberFormat.abbrev(s.batteryUpgradeCost))
			or "\u{1F680} Battery MAX LEVEL"
	else
		rows.battery.Text = "\u{1F680} Buy Missile Battery \u{2014} \u{1F4B5} " .. NumberFormat.abbrev(s.batteryCost)
		rows.batteryUp.Visible = false
	end
end

function MilitaryPanel.toggle()
	gui.Enabled = not gui.Enabled
	if gui.Enabled then
		refresh()
	end
end

function MilitaryPanel.init(context)
	ctx = context
	local pg, content = UILib.panel("MVC_Military", "\u{2699}\u{FE0F} WAR & ECONOMY", UDim2.new(0, 440, 0, 400), 13)
	gui = pg

	makeRow(content, 1, "auto", UILib.Colors.Green, function()
		Remotes.Events.ShopBuy:FireServer("auto_collect")
	end)
	makeRow(content, 2, "defense", UILib.Colors.Blue, function()
		Remotes.Events.ShopBuy:FireServer("buy_defense")
	end)
	makeRow(content, 3, "hangar", UILib.Colors.LightBlue, function()
		Remotes.Events.ShopBuy:FireServer("buy_hangar")
	end)
	makeRow(content, 4, "jet", UILib.Colors.LightBlue, function()
		Remotes.Events.ShopBuy:FireServer("upgrade_jet")
	end)
	makeRow(content, 5, "battery", UILib.Colors.Purple, function()
		Remotes.Events.ShopBuy:FireServer("buy_battery")
	end)
	makeRow(content, 6, "batteryUp", UILib.Colors.Purple, function()
		Remotes.Events.UpgradeBattery:FireServer()
	end)

	ctx.State.changed.Event:Connect(function()
		if gui.Enabled then
			refresh()
		end
	end)
end

return MilitaryPanel
