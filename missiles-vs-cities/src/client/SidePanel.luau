-- Left-side button column (Gift / Rewards / Shop / Attack + 2X passes),
-- and the gem shop panel.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)
local UILib = require(script.Parent.UILib)

local SidePanel = {}

local ctx
local giftButton
local shopGui

-- Exposed so NPC dialogue ("Open Shop") can toggle the same panel.
function SidePanel.toggleShop()
	shopGui.Enabled = not shopGui.Enabled
end

local function makeShop()
	local panelGui, content = UILib.panel("MVC_Shop", "\u{1F6D2} Shop", UDim2.new(0, 380, 0, 380), 12)
	shopGui = panelGui

	local items = {
		{ id = "shield", text = "\u{1F6E1}\u{FE0F} Shield (blocks 1 missile) — \u{1F48E} " .. Config.Shop.ShieldGems },
		{ id = "barrage", text = "\u{1F680}x3 Barrage — \u{1F48E} " .. Config.Shop.BarrageGems },
		{ id = "repair_all", text = "\u{1F527} Instant Repair All — \u{1F48E} " .. Config.Shop.RepairAllGems },
		{ id = "skip_cooldown", text = "\u{23E9} Skip Rocket Cooldown — \u{1F48E} " .. Config.Shop.SkipCooldownGems },
		{ id = "pass_cash", text = "\u{1F4B5} 2X CASH (Gamepass)", color = UILib.Colors.Purple },
		{ id = "pass_damage", text = "\u{1F4A5} 2X DAMAGE (Gamepass)", color = UILib.Colors.Purple },
	}

	for i, item in ipairs(items) do
		UILib.button({
			Size = UDim2.new(1, -16, 0, 48),
			Position = UDim2.new(0, 8, 0, 10 + (i - 1) * 58),
			Text = item.text,
			BackgroundColor3 = item.color or UILib.Colors.Green,
		}, content, function()
			Remotes.Events.ShopBuy:FireServer(item.id)
		end)
	end
end

local function sideButton(holder, order, iconKind, caption, color, onClick)
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(0, 76, 0, 88)
	frame.LayoutOrder = order
	frame.Parent = holder

	local button = UILib.button({
		Size = UDim2.new(0, 68, 0, 60),
		Position = UDim2.new(0, 4, 0, 0),
		Text = "",
		BackgroundColor3 = color,
	}, frame, onClick)

	local icon = UILib.icon(iconKind, button)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.new(0, 40, 0, 40)

	local captionLabel = UILib.text({
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 0, 62),
		Text = caption,
	}, frame)

	return button, captionLabel
end

function SidePanel.init(context)
	ctx = context
	makeShop()

	local gui = UILib.screen("MVC_Side", 6)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Position = UDim2.new(0, 10, 0, 120)
	holder.Size = UDim2.new(0, 90, 0, 460)
	holder.Parent = gui

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = holder

	local giftCaption
	giftButton, giftCaption = sideButton(holder, 1, "gift", "Gift", UILib.Colors.Gold, function()
		Remotes.Events.ClaimGift:FireServer()
	end)
	sideButton(holder, 2, "calendar", "Rewards", UILib.Colors.Red, function()
		ctx.DailyUI.toggle()
	end)
	sideButton(holder, 3, "cart", "Shop", UILib.Colors.Blue, function()
		shopGui.Enabled = not shopGui.Enabled
	end)
	sideButton(holder, 4, "bomb", "Attack", UILib.Colors.Purple, function()
		ctx.AttackView.open("rocket")
	end)
	sideButton(holder, 5, "jet", "Jets", UILib.Colors.LightBlue, function()
		ctx.AttackView.open("jet")
	end)
	sideButton(holder, 6, "bomb", "Battery", UILib.Colors.Red, function()
		ctx.AttackView.open("battery")
	end)
	sideButton(holder, 7, "scroll", "Quests", UILib.Colors.Gold, function()
		ctx.QuestUI.toggle()
	end)
	sideButton(holder, 8, "gem", "War", UILib.Colors.DarkGray, function()
		ctx.Military.toggle()
	end)

	-- Compact 2X gamepass buttons under the main column.
	local passCash = UILib.button({
		Size = UDim2.new(0, 84, 0, 30),
		Text = "2X CASH",
		BackgroundColor3 = UILib.Colors.Green,
	}, nil, function()
		Remotes.Events.ShopBuy:FireServer("pass_cash")
	end)
	passCash.LayoutOrder = 9
	passCash.Parent = holder

	local passDmg = UILib.button({
		Size = UDim2.new(0, 84, 0, 30),
		Text = "2X DAMAGE",
		BackgroundColor3 = UILib.Colors.Green,
	}, nil, function()
		Remotes.Events.ShopBuy:FireServer("pass_damage")
	end)
	passDmg.LayoutOrder = 10
	passDmg.Parent = holder

	-- Gift countdown shows in the caption under the icon.
	task.spawn(function()
		while true do
			task.wait(1)
			local remaining = ctx.State.remaining("giftRemaining")
			if remaining > 0 then
				giftCaption.Text = NumberFormat.clock(remaining)
			else
				giftCaption.Text = "GIFT!"
				giftCaption.TextColor3 = Color3.fromRGB(140, 245, 120)
			end
		end
	end)
end

return SidePanel
