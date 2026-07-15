-- Income ticks, cash/gems, state pushes to clients, leaderstats,
-- the free-gift timer, the gem shop and gamepass hooks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local BuildingDefs = require(Shared.BuildingDefs)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)
local Layout = require(Shared.Layout)

local EconomyService = {}

local ctx

local function now()
	return os.clock()
end

local function notify(player, msg, kind)
	Remotes.Events.Notify:FireClient(player, { msg = msg, kind = kind or "info" })
end

function EconomyService.addCash(player, amount)
	local profile = ctx.Data.get(player)
	if profile then
		profile.cash += amount
	end
end

function EconomyService.trySpend(player, amount)
	local profile = ctx.Data.get(player)
	if not profile or profile.cash < amount then
		return false
	end
	profile.cash -= amount
	return true
end

function EconomyService.addGems(player, amount)
	local profile = ctx.Data.get(player)
	if profile then
		profile.gems += amount
	end
end

function EconomyService.trySpendGems(player, amount)
	local profile = ctx.Data.get(player)
	if not profile or profile.gems < amount then
		return false
	end
	profile.gems -= amount
	return true
end

function EconomyService.cashMultiplier(player)
	local session = ctx.session[player]
	local profile = ctx.Data.get(player)
	local mult = (session and session.passCash) and 2 or 1
	-- Permanent rebirth bonus (+100% per rebirth) and temporary event boosts.
	if profile then
		mult *= 1 + (profile.rebirths or 0) * Config.Rebirth.IncomePerRebirth
	end
	mult *= ctx.eventCashMult or 1
	return mult
end

function EconomyService.rebirthCost(profile)
	return Config.Rebirth.BaseCost * Config.Rebirth.CostGrowth ^ (profile.rebirths or 0)
end

-- Number of distinct building types currently owned (for quest stats).
local function distinctBuildings(slot)
	local count = 0
	for _, zone in pairs(slot.zones) do
		if zone.level > 0 then
			count += 1
		end
	end
	return count
end

function EconomyService.damageMultiplier(player)
	local session = ctx.session[player]
	return (session and session.passDamage) and 2 or 1
end

function EconomyService.getIncomePerSec(player)
	local slot = ctx.Plot.getSlot(player)
	if not slot then
		return 0
	end
	local total = 0
	for zi, def in ipairs(BuildingDefs.List) do
		local zone = slot.zones[zi]
		if zone.level > 0 and not zone.destroyed then
			total += BuildingDefs.income(def, zone.level)
		end
	end
	return total * EconomyService.cashMultiplier(player)
end

function EconomyService.pushState(player)
	local profile = ctx.Data.get(player)
	local session = ctx.session[player]
	if not profile or not session then
		return
	end
	local slot = ctx.Plot.getSlot(player)
	local rocketLevel = profile.rocketLevel
	local stats = slot and {
		cash = profile.cash,
		worth = ctx.Plot.cityWorth(slot),
		rocket_level = rocketLevel,
		buildings = distinctBuildings(slot),
	} or nil
	local snapshot = {
		cash = profile.cash,
		gems = profile.gems,
		income = EconomyService.getIncomePerSec(player),
		worth = slot and ctx.Plot.cityWorth(slot) or 0,
		plotIndex = slot and slot.index or 0,
		rebirths = profile.rebirths or 0,
		rebirthCost = EconomyService.rebirthCost(profile),
		quests = ctx.Quests and ctx.Quests.getSummary(player, stats) or nil,
		cosmetics = profile.cosmetics,
		rocketLevel = rocketLevel,
		rocketCost = rocketLevel < Config.Rocket.MaxLevel
			and math.floor(Config.Rocket.BaseUpgradeCost * Config.Rocket.CostGrowth ^ (rocketLevel - 1))
			or 0,
		rocketDamage = math.floor(Config.Rocket.BaseDamage * Config.Rocket.DamageGrowth ^ (rocketLevel - 1))
			* EconomyService.damageMultiplier(player),
		rocketRemaining = math.max(0, (session.rocketReadyAt or 0) - now()),
		siloCount = profile.siloCount or 1,
		nextSiloCost = Config.Silos.Costs[(profile.siloCount or 1) + 1] or 0,
		autoCollect = profile.autoCollect or false,
		autoCollectCost = Config.AutoCollectCost,
		population = slot and ctx.Plot.population(slot) or 0,
		hangars = profile.hangars or 0,
		nextHangarCost = Config.Jets.HangarCosts[(profile.hangars or 0) + 1] or 0,
		jetLevel = profile.jetLevel or 1,
		jetCost = (profile.jetLevel or 1) < Config.Jets.MaxLevel
			and math.floor(Config.Jets.BaseUpgradeCost * Config.Jets.CostGrowth ^ ((profile.jetLevel or 1) - 1)) or 0,
		jetRemaining = math.max(0, (session.jetReadyAt or 0) - now()),
		hasAirport = slot and slot.zones[Layout.AirportZoneIndex]
			and slot.zones[Layout.AirportZoneIndex].level > 0 or false,
		defenseLevel = profile.defenseLevel or 0,
		defenseCost = (profile.defenseLevel or 0) < Config.Defense.MaxLevel
			and math.floor(Config.Defense.BaseCost * Config.Defense.CostGrowth ^ (profile.defenseLevel or 0)) or 0,
		batteryUnlocked = profile.batteryUnlocked or false,
		batteryCost = Config.Battery.UnlockCost,
		batteryLevel = profile.batteryLevel or 1,
		batteryUpgradeCost = (profile.batteryLevel or 1) < Config.Battery.MaxLevel
			and math.floor(Config.Battery.BaseUpgradeCost * Config.Battery.CostGrowth ^ ((profile.batteryLevel or 1) - 1)) or 0,
		batteryRemaining = math.max(0, (session.batteryReadyAt or 0) - now()),
		siloDisabledRemaining = math.max(0, (session.siloDisabledUntil or 0) - now()),
		isAdmin = ctx.isAdmin and ctx.isAdmin(player) or false,
		nukeOwned = profile.nukeIsland,
		nukeCharges = profile.nukeCharges,
		nukeRemaining = math.max(0, profile.lastNukeAt + Config.Nuke.Cooldown - os.time()),
		shields = profile.shields,
		barrage = profile.barrage,
		giftRemaining = math.max(0, (session.giftReadyAt or 0) - now()),
		daily = ctx.Rewards.getData(player),
		passes = { cash2x = session.passCash or false, dmg2x = session.passDamage or false },
	}
	Remotes.Events.State:FireClient(player, snapshot)
end

local function updateLeaderstats(player)
	local profile = ctx.Data.get(player)
	local stats = player:FindFirstChild("leaderstats")
	if not profile or not stats then
		return
	end
	local slot = ctx.Plot.getSlot(player)
	stats.Cash.Value = NumberFormat.abbrev(profile.cash)
	stats.Worth.Value = NumberFormat.abbrev(slot and ctx.Plot.cityWorth(slot) or 0)
end

local function makeLeaderstats(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Value = "0"
	cash.Parent = stats
	local worth = Instance.new("StringValue")
	worth.Name = "Worth"
	worth.Value = "0"
	worth.Parent = stats
	stats.Parent = player
end

local function incomeLoop()
	while true do
		task.wait(Config.IncomeInterval)
		for _, slot in ipairs(ctx.Plot.slots()) do
			local player = slot.owner
			if player then
				local profile = ctx.Data.get(player)
				if profile then
					local mult = EconomyService.cashMultiplier(player)
					local autoCollect = profile.autoCollect
					local autoTotal = 0
					local pops = {}
					for zi, def in ipairs(BuildingDefs.List) do
						local zone = slot.zones[zi]
						if zone.level > 0 and not zone.destroyed then
							local amt = BuildingDefs.income(def, zone.level) * Config.IncomeInterval * mult
							if autoCollect then
								autoTotal += amt
								pops[#pops + 1] = { zi, amt }
							else
								-- Cash piles up at the building until the player
								-- walks over to collect it (cap ~10 min income).
								local cap = BuildingDefs.income(def, zone.level) * mult * 600
								zone.pending = math.min((zone.pending or 0) + amt, cap)
								ctx.Plot.updateCollect(slot, zi)
							end
						end
					end
					if autoCollect and autoTotal > 0 then
						profile.cash += autoTotal
						Remotes.Events.IncomePops:FireAllClients(slot.index, pops)
					end
					slot.bannerLabel.Text = "\u{1F3D9}\u{FE0F} " .. player.DisplayName
						.. "\n\u{1F4B5} " .. NumberFormat.abbrev(ctx.Plot.cityWorth(slot))
						.. "  \u{1F465} " .. NumberFormat.abbrev(ctx.Plot.population(slot))
					updateLeaderstats(player)
					if ctx.Quests then
						ctx.Quests.evaluate(player, {
							cash = profile.cash,
							worth = ctx.Plot.cityWorth(slot),
							rocket_level = profile.rocketLevel,
							buildings = distinctBuildings(slot),
						})
					end
					EconomyService.pushState(player)
				end
			end
		end
	end
end

local function onShopBuy(player, itemId)
	local profile = ctx.Data.get(player)
	local session = ctx.session[player]
	if not profile or not session or type(itemId) ~= "string" then
		return
	end

	-- Character shop items are handled by CosmeticsService.
	if ctx.Cosmetics and ctx.Cosmetics.buy(player, itemId) then
		EconomyService.pushState(player)
		return
	end

	if itemId == "repair_all" then
		local slot = ctx.Plot.getSlot(player)
		if not slot then
			return
		end
		local anyDestroyed = false
		for _, zone in pairs(slot.zones) do
			if zone.destroyed then
				anyDestroyed = true
				break
			end
		end
		if not anyDestroyed then
			notify(player, "Nothing needs repairs!", "info")
			return
		end
		if not EconomyService.trySpendGems(player, Config.Shop.RepairAllGems) then
			notify(player, "Need \u{1F48E} " .. Config.Shop.RepairAllGems .. " gems!", "bad")
			return
		end
		local count = ctx.Plot.repairAll(slot)
		notify(player, "\u{1F527} Instantly rebuilt " .. count .. " buildings!", "good")
	elseif itemId == "skip_cooldown" then
		if (session.rocketReadyAt or 0) <= now() then
			notify(player, "Your rocket is already ready!", "info")
			return
		end
		if not EconomyService.trySpendGems(player, Config.Shop.SkipCooldownGems) then
			notify(player, "Need \u{1F48E} " .. Config.Shop.SkipCooldownGems .. " gems!", "bad")
			return
		end
		session.rocketReadyAt = 0
		notify(player, "\u{1F680} Rocket ready!", "good")
	elseif itemId == "shield" then
		if not EconomyService.trySpendGems(player, Config.Shop.ShieldGems) then
			notify(player, "Need \u{1F48E} " .. Config.Shop.ShieldGems .. " gems!", "bad")
			return
		end
		profile.shields += 1
		notify(player, "\u{1F6E1}\u{FE0F} Shield armed! Blocks the next missile strike.", "good")
	elseif itemId == "barrage" then
		if not EconomyService.trySpendGems(player, Config.Shop.BarrageGems) then
			notify(player, "Need \u{1F48E} " .. Config.Shop.BarrageGems .. " gems!", "bad")
			return
		end
		profile.barrage += 1
		notify(player, "\u{1F680}\u{1F680}\u{1F680} Barrage loaded! Your next launch fires 3 rockets.", "good")
	elseif itemId == "buy_silo" then
		local count = profile.siloCount or 1
		local cost = Config.Silos.Costs[count + 1]
		if not cost then
			notify(player, "\u{1F680} You already have the maximum " .. Config.Silos.Max .. " silos!", "info")
			return
		end
		if not EconomyService.trySpend(player, cost) then
			notify(player, "Silo " .. (count + 1) .. " costs \u{1F4B5} " .. NumberFormat.abbrev(cost) .. "!", "bad")
			return
		end
		profile.siloCount = count + 1
		local slot = ctx.Plot.getSlot(player)
		if slot then
			ctx.Plot.updateSilos(slot, profile.siloCount)
		end
		notify(player, "\u{1F680} SILO " .. profile.siloCount .. " BUILT! You now fire "
			.. profile.siloCount .. " rockets per launch!", "victory")
	elseif itemId == "auto_collect" then
		if profile.autoCollect then
			notify(player, "\u{1F4B0} You already have Auto-Collect!", "info")
			return
		end
		if not EconomyService.trySpend(player, Config.AutoCollectCost) then
			notify(player, "Auto-Collect costs \u{1F4B5} " .. NumberFormat.abbrev(Config.AutoCollectCost) .. "!", "bad")
			return
		end
		profile.autoCollect = true
		-- Sweep up whatever's pending right now.
		local slot = ctx.Plot.getSlot(player)
		if slot then
			ctx.Plot.collectAll(player, slot)
		end
		notify(player, "\u{1F4B0} AUTO-COLLECT unlocked! Income now goes straight to your wallet.", "victory")
	elseif itemId == "buy_defense" then
		local lvl = profile.defenseLevel or 0
		if lvl >= Config.Defense.MaxLevel then
			notify(player, "\u{1F6E1}\u{FE0F} Air defense is max level!", "info")
			return
		end
		local cost = math.floor(Config.Defense.BaseCost * Config.Defense.CostGrowth ^ lvl)
		if not EconomyService.trySpend(player, cost) then
			notify(player, "Air defense upgrade costs \u{1F4B5} " .. NumberFormat.abbrev(cost) .. "!", "bad")
			return
		end
		profile.defenseLevel = lvl + 1
		local slot = ctx.Plot.getSlot(player)
		if slot and ctx.Defense then
			ctx.Defense.updateTurrets(slot, profile.defenseLevel)
		end
		notify(player, "\u{1F6E1}\u{FE0F} AIR DEFENSE Lv" .. profile.defenseLevel
			.. "! Better chance to shoot down incoming missiles & jets.", "victory")
	elseif itemId == "buy_hangar" then
		local slot = ctx.Plot.getSlot(player)
		if not slot or not slot.zones[Layout.AirportZoneIndex] or slot.zones[Layout.AirportZoneIndex].level <= 0 then
			notify(player, "\u{2708}\u{FE0F} Build an Airport first to buy hangars!", "bad")
			return
		end
		local count = profile.hangars or 0
		local cost = Config.Jets.HangarCosts[count + 1]
		if not cost then
			notify(player, "\u{2708}\u{FE0F} You already have the max " .. Config.Jets.MaxHangars .. " hangars!", "info")
			return
		end
		if not EconomyService.trySpend(player, cost) then
			notify(player, "Hangar " .. (count + 1) .. " costs \u{1F4B5} " .. NumberFormat.abbrev(cost) .. "!", "bad")
			return
		end
		profile.hangars = count + 1
		if ctx.Jets then
			ctx.Jets.updateHangars(slot, profile.hangars)
		end
		notify(player, "\u{2708}\u{FE0F} HANGAR " .. profile.hangars .. " BUILT! Launch " .. profile.hangars .. " jets per strike!", "victory")
	elseif itemId == "upgrade_jet" then
		local lvl = profile.jetLevel or 1
		if lvl >= Config.Jets.MaxLevel then
			notify(player, "\u{2708}\u{FE0F} Jets are max level!", "info")
			return
		end
		local cost = math.floor(Config.Jets.BaseUpgradeCost * Config.Jets.CostGrowth ^ (lvl - 1))
		if not EconomyService.trySpend(player, cost) then
			notify(player, "Jet upgrade costs \u{1F4B5} " .. NumberFormat.abbrev(cost) .. "!", "bad")
			return
		end
		profile.jetLevel = lvl + 1
		notify(player, "\u{2708}\u{FE0F} JETS upgraded to Lv" .. profile.jetLevel .. "!", "buy")
	elseif itemId == "buy_battery" then
		if profile.batteryUnlocked then
			notify(player, "\u{1F680} You already own the Missile Battery!", "info")
			return
		end
		if not EconomyService.trySpend(player, Config.Battery.UnlockCost) then
			notify(player, "The Missile Battery costs \u{1F4B5} " .. NumberFormat.abbrev(Config.Battery.UnlockCost) .. "!", "bad")
			return
		end
		profile.batteryUnlocked = true
		local slot = ctx.Plot.getSlot(player)
		if slot and ctx.Battery then
			ctx.Battery.showIsland(slot, true)
		end
		notify(player, "\u{1F680} MISSILE BATTERY built on your side island! Fires " .. Config.Battery.Volley .. " missiles at once.", "victory")
	elseif itemId == "pass_cash" then
		if Config.GamePassCash2x > 0 then
			MarketplaceService:PromptGamePassPurchase(player, Config.GamePassCash2x)
		else
			notify(player, "2X CASH gamepass isn't configured yet (see Config.luau).", "info")
		end
	elseif itemId == "pass_damage" then
		if Config.GamePassDamage2x > 0 then
			MarketplaceService:PromptGamePassPurchase(player, Config.GamePassDamage2x)
		else
			notify(player, "2X DAMAGE gamepass isn't configured yet (see Config.luau).", "info")
		end
	end
	EconomyService.pushState(player)
end

local function onClaimGift(player)
	local session = ctx.session[player]
	local profile = ctx.Data.get(player)
	if not session or not profile then
		return
	end
	if now() < (session.giftReadyAt or 0) then
		notify(player, "\u{1F381} Gift isn't ready yet!", "bad")
		return
	end
	session.giftReadyAt = now() + Config.GiftInterval
	local cashGift = math.max(1000, EconomyService.getIncomePerSec(player) * 300)
	profile.gems += Config.GiftGems
	profile.cash += cashGift
	notify(player, "\u{1F381} Gift claimed! +\u{1F48E} " .. Config.GiftGems
		.. " and +\u{1F4B5} " .. NumberFormat.abbrev(cashGift) .. "!", "victory")
	EconomyService.pushState(player)
end

function EconomyService.onJoin(player)
	makeLeaderstats(player)
	local session = ctx.session[player]
	session.giftReadyAt = now() + Config.GiftInterval
	session.rocketReadyAt = 0

	if Config.GamePassCash2x > 0 then
		task.spawn(function()
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Config.GamePassCash2x)
			end)
			if ok and owns then
				session.passCash = true
				EconomyService.pushState(player)
			end
		end)
	end
	if Config.GamePassDamage2x > 0 then
		task.spawn(function()
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Config.GamePassDamage2x)
			end)
			if ok and owns then
				session.passDamage = true
				EconomyService.pushState(player)
			end
		end)
	end
end

function EconomyService.init(context)
	ctx = context

	Remotes.Events.ShopBuy.OnServerEvent:Connect(onShopBuy)
	Remotes.Events.ClaimGift.OnServerEvent:Connect(onClaimGift)

	Remotes.Events.RequestRebirth.OnServerEvent:Connect(function(player)
		local profile = ctx.Data.get(player)
		local slot = ctx.Plot.getSlot(player)
		if not profile or not slot then
			return
		end
		local cost = EconomyService.rebirthCost(profile)
		if profile.cash < cost then
			notify(player, "\u{1F31F} Rebirth needs \u{1F4B5} " .. NumberFormat.abbrev(cost) .. "!", "bad")
			return
		end
		profile.rebirths = (profile.rebirths or 0) + 1
		profile.cash = Config.StartingCash
		ctx.Plot.resetBuildings(player)
		local mult = 1 + profile.rebirths * Config.Rebirth.IncomePerRebirth
		notify(player, "\u{1F31F} REBIRTH " .. profile.rebirths .. "! Permanent income x" .. mult .. "!", "victory")
		Remotes.Events.Notify:FireAllClients({
			msg = "\u{1F31F} " .. player.DisplayName .. " was REBORN! Their income is now x" .. mult .. "!",
			kind = "info",
		})
		EconomyService.pushState(player)
	end)

	Remotes.Functions.GetSnapshot.OnServerInvoke = function(player)
		if ctx.Data.get(player) and ctx.session[player] then
			EconomyService.pushState(player)
			return true
		end
		return false
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local session = ctx.session[player]
		if not purchased or not session then
			return
		end
		if passId == Config.GamePassCash2x then
			session.passCash = true
			notify(player, "\u{1F4B5} 2X CASH activated!", "victory")
		elseif passId == Config.GamePassDamage2x then
			session.passDamage = true
			notify(player, "\u{1F4A5} 2X DAMAGE activated!", "victory")
		end
		EconomyService.pushState(player)
	end)

	task.spawn(incomeLoop)
end

return EconomyService
