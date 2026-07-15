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

-- Redesigned gem shop: a 2-column grid of item CARDS, each with a big emoji,
-- a name, a price chip and a coloured BUY button — like the reference game.
local function makeShop()
	local panelGui, content = UILib.panel("MVC_Shop", "\u{1F6D2} SHOP", UDim2.new(0, 480, 0, 470), 12)
	shopGui = panelGui

	local items = {
		{ id = "shield", emoji = "\u{1F6E1}\u{FE0F}", name = "Shield", desc = "Blocks 1 missile", price = Config.Shop.ShieldGems, cur = "gem" },
		{ id = "barrage", emoji = "\u{1F680}", name = "Barrage x3", desc = "Triple your next launch", price = Config.Shop.BarrageGems, cur = "gem" },
		{ id = "repair_all", emoji = "\u{1F527}", name = "Repair All", desc = "Instantly rebuild", price = Config.Shop.RepairAllGems, cur = "gem" },
		{ id = "skip_cooldown", emoji = "\u{23E9}", name = "Skip Reload", desc = "Rocket ready now", price = Config.Shop.SkipCooldownGems, cur = "gem" },
		{ id = "pass_cash", emoji = "\u{1F4B5}", name = "2X CASH", desc = "Gamepass", price = "R$", cur = "pass" },
		{ id = "pass_damage", emoji = "\u{1F4A5}", name = "2X DAMAGE", desc = "Gamepass", price = "R$", cur = "pass" },
	}

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = content

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.5, -10, 0, 150)
	grid.CellPadding = UDim2.new(0, 8, 0, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroll
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 4)
	pad.PaddingTop = UDim.new(0, 4)
	pad.Parent = scroll

	for i, item in ipairs(items) do
		local card = UILib.card({
			BackgroundColor3 = Color3.fromRGB(130, 200, 235),
			LayoutOrder = i,
		}, scroll)

		UILib.text({
			Size = UDim2.new(1, -8, 0, 52),
			Position = UDim2.new(0, 4, 0, 6),
			Text = item.emoji,
		}, card)
		UILib.text({
			Size = UDim2.new(1, -8, 0, 24),
			Position = UDim2.new(0, 4, 0, 58),
			Text = item.name,
			TextColor3 = Color3.new(1, 1, 1),
		}, card)
		UILib.text({
			Size = UDim2.new(1, -8, 0, 18),
			Position = UDim2.new(0, 4, 0, 82),
			Text = item.desc,
			TextColor3 = Color3.fromRGB(225, 240, 255),
		}, card)

		local priceText = item.cur == "gem" and ("\u{1F48E} " .. item.price)
			or (item.cur == "pass" and "\u{1F311} Robux" or ("\u{1F4B5} " .. item.price))
		UILib.button({
			Size = UDim2.new(1, -16, 0, 40),
			Position = UDim2.new(0, 8, 1, -46),
			Text = priceText,
			BackgroundColor3 = item.cur == "pass" and UILib.Colors.Purple or UILib.Colors.Green,
		}, card, function()
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
