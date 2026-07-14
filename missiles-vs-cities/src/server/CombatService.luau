-- Rockets and nukes: validation, cooldowns, flights, impacts, payouts.
-- Clients only render FX; every gameplay decision happens here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Layout = require(Shared.Layout)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)

local CombatService = {}

local ctx

local function now()
	return os.clock()
end

local function notify(player, msg, kind)
	Remotes.Events.Notify:FireClient(player, { msg = msg, kind = kind or "info" })
end

local function notifyAll(msg, kind)
	Remotes.Events.Notify:FireAllClients({ msg = msg, kind = kind or "info" })
end

local function siloLaunchPos(plotIndex, siloIndex)
	return Layout.siloPos(plotIndex, siloIndex or 1) + Vector3.new(0, 16, 0)
end

-- Spread pattern for multi-rocket volleys.
local SALVO_OFFSETS = {
	Vector3.new(0, 0, 0), Vector3.new(18, 0, 10), Vector3.new(-16, 0, 14),
	Vector3.new(10, 0, -16), Vector3.new(-14, 0, -12), Vector3.new(24, 0, -4),
	Vector3.new(-24, 0, 2), Vector3.new(4, 0, 22), Vector3.new(-6, 0, -24),
}

local function rocketDamage(player)
	local profile = ctx.Data.get(player)
	local level = profile and profile.rocketLevel or 1
	return math.floor(Config.Rocket.BaseDamage * Config.Rocket.DamageGrowth ^ (level - 1))
		* ctx.Economy.damageMultiplier(player)
end

local function impactRocket(attackerUserId, targetUserId, pos, damage)
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target then
		return
	end
	local slot = ctx.Plot.getSlot(target)
	if not slot then
		return
	end
	local attacker = Players:GetPlayerByUserId(attackerUserId)

	local profile = ctx.Data.get(target)
	if profile and profile.shields > 0 then
		profile.shields -= 1
		Remotes.Events.ShieldFX:FireAllClients(slot.index, pos)
		notify(target, "\u{1F6E1}\u{FE0F} Your shield blocked a missile!", "good")
		if attacker then
			notify(attacker, "\u{1F6E1}\u{FE0F} " .. target.DisplayName .. "'s shield blocked your missile!", "bad")
		end
		ctx.Economy.pushState(target)
		return
	end

	local worth, count = ctx.Plot.applyBlast(slot, pos, damage)
	if count > 0 and attacker then
		ctx.Economy.addCash(attacker, worth)
		local aProfile = ctx.Data.get(attacker)
		if aProfile then
			aProfile.stats.stolen += worth
		end
		if ctx.Quests then
			ctx.Quests.onEvent(attacker, "destroy", count)
		end
		notify(attacker, "\u{1F4A5} Destroyed " .. count .. " buildings! +\u{1F4B5} "
			.. NumberFormat.abbrev(worth), "victory")
		notify(target, "\u{1F4A5} " .. attacker.DisplayName .. "'s missile destroyed "
			.. count .. " of your buildings!", "bad")
		ctx.Economy.pushState(attacker)
	elseif attacker then
		notify(attacker, "\u{1F4A8} Missile hit, but nothing was destroyed...", "info")
	end
	ctx.Economy.pushState(target)
end

local function impactNuke(attackerUserId, targetUserId)
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target then
		return
	end
	local slot = ctx.Plot.getSlot(target)
	if not slot then
		return
	end
	local attacker = Players:GetPlayerByUserId(attackerUserId)

	local worth = ctx.Plot.nukeSlot(slot)
	if attacker then
		ctx.Economy.addCash(attacker, worth)
		local aProfile = ctx.Data.get(attacker)
		if aProfile then
			aProfile.stats.stolen += worth
		end
		notify(attacker, "\u{2622}\u{FE0F} DIRECT HIT! You stole \u{1F4B5} "
			.. NumberFormat.abbrev(worth) .. "!", "victory")
		ctx.Economy.pushState(attacker)
	end
	notify(target, "\u{2622}\u{FE0F} Your city was NUKED! It will rebuild itself over the next few minutes.", "bad")
	notifyAll("\u{2622}\u{FE0F} " .. (attacker and attacker.DisplayName or "Someone")
		.. " NUKED " .. target.DisplayName .. "'s city for \u{1F4B5} " .. NumberFormat.abbrev(worth) .. "!")
	ctx.Economy.pushState(target)
end

local function onRequestLaunch(player, targetUserId, x, z, useNuke, useBarrage)
	if type(targetUserId) ~= "number" or type(x) ~= "number" or type(z) ~= "number" then
		return
	end
	local session = ctx.session[player]
	local profile = ctx.Data.get(player)
	local mySlot = ctx.Plot.getSlot(player)
	if not session or not profile or not mySlot then
		return
	end

	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == player then
		notify(player, "That player isn't here anymore!", "bad")
		return
	end
	local targetSlot = ctx.Plot.getSlot(target)
	if not targetSlot then
		notify(player, "That player has no city!", "bad")
		return
	end
	if ctx.Plot.isImmune(targetSlot) then
		notify(player, "\u{1F6E1}\u{FE0F} " .. target.DisplayName .. " is protected right now!", "bad")
		return
	end

	local pos = Layout.clampToPlot(targetSlot.index, Vector3.new(x, 0, z))
	local fromPos = siloLaunchPos(mySlot.index, 1)

	if useNuke then
		local canNuke = profile.nukeIsland or profile.nukeCharges > 0
		if not canNuke then
			notify(player, "\u{2622}\u{FE0F} You need Nuke Access (\u{1F4B5} "
				.. NumberFormat.abbrev(Config.Nuke.IslandCost) .. ") or a free nuke charge!", "bad")
			return
		end
		if os.time() - profile.lastNukeAt < Config.Nuke.Cooldown then
			local wait = Config.Nuke.Cooldown - (os.time() - profile.lastNukeAt)
			notify(player, "\u{2622}\u{FE0F} Nuke ready in " .. NumberFormat.clock(wait) .. " (one per day)!", "bad")
			return
		end
		if not profile.nukeIsland then
			profile.nukeCharges -= 1
		end
		profile.lastNukeAt = os.time()
		profile.stats.nukesFired += 1

		local flight = Config.Nuke.FlightTime
		Remotes.Events.MissileEvent:FireAllClients({
			kind = "nuke",
			from = fromPos,
			to = pos,
			flight = flight,
			attacker = player.DisplayName,
		})
		Remotes.Events.Alarm:FireClient(target, { kind = "nuke", pos = pos, eta = flight })
		notifyAll("\u{2622}\u{FE0F} " .. player.DisplayName .. " has launched a NUKE at "
			.. target.DisplayName .. "'s city!", "bad")
		task.delay(flight, impactNuke, player.UserId, target.UserId)
		ctx.Plot.setSiloRocket(mySlot, 1, false)
		task.delay(flight + 4, function()
			if ctx.Plot.getSlot(player) == mySlot then
				ctx.Plot.setSiloRocket(mySlot, 1, true)
			end
		end)
		if ctx.Quests then
			ctx.Quests.onEvent(player, "nuke", 1)
		end
	else
		if now() < (session.rocketReadyAt or 0) then
			notify(player, "\u{1F680} Rocket reloading! "
				.. NumberFormat.clock((session.rocketReadyAt or 0) - now()), "bad")
			return
		end
		session.rocketReadyAt = now() + Config.Rocket.Cooldown

		-- One rocket per owned silo; barrage triples the volley.
		local siloCount = math.clamp(profile.siloCount or 1, 1, Config.Silos.Max)
		local salvo = siloCount
		if useBarrage and profile.barrage > 0 then
			profile.barrage -= 1
			salvo = math.min(siloCount * 3, #SALVO_OFFSETS)
		end
		local damage = rocketDamage(player)
		for s = 1, salvo do
			local siloIndex = ((s - 1) % siloCount) + 1
			local hitPos = Layout.clampToPlot(targetSlot.index, pos + SALVO_OFFSETS[s])
			local flight = Config.Rocket.FlightTime + (s - 1) * 0.7
			Remotes.Events.MissileEvent:FireAllClients({
				kind = "rocket",
				from = siloLaunchPos(mySlot.index, siloIndex),
				to = hitPos,
				flight = flight,
				attacker = player.DisplayName,
			})
			task.delay(flight, impactRocket, player.UserId, target.UserId, hitPos, damage)
		end
		-- The decorative silo rockets "lift off": hide, then respawn later.
		for i = 1, siloCount do
			ctx.Plot.setSiloRocket(mySlot, i, false)
		end
		task.delay(Config.Rocket.FlightTime + 4, function()
			if ctx.Plot.getSlot(player) == mySlot then
				for i = 1, siloCount do
					ctx.Plot.setSiloRocket(mySlot, i, true)
				end
			end
		end)
		profile.stats.missilesFired += salvo
		if ctx.Quests then
			ctx.Quests.onEvent(player, "missile_launch", 1)
		end
		Remotes.Events.Alarm:FireClient(target, { kind = "rocket", pos = pos, eta = Config.Rocket.FlightTime })
		notify(target, "\u{1F6A8} " .. player.DisplayName .. " launched "
			.. (salvo > 1 and salvo .. " missiles" or "a missile") .. " at your city!", "bad")
	end
	ctx.Economy.pushState(player)
end

local function onUpgradeRocket(player)
	local profile = ctx.Data.get(player)
	if not profile then
		return
	end
	if profile.rocketLevel >= Config.Rocket.MaxLevel then
		notify(player, "\u{1F680} Rocket is max level!", "info")
		return
	end
	local cost = math.floor(Config.Rocket.BaseUpgradeCost * Config.Rocket.CostGrowth ^ (profile.rocketLevel - 1))
	if not ctx.Economy.trySpend(player, cost) then
		notify(player, "Need \u{1F4B5} " .. NumberFormat.abbrev(cost) .. " to upgrade!", "bad")
		return
	end
	profile.rocketLevel += 1
	notify(player, "\u{1F680} Rocket upgraded to Lv" .. profile.rocketLevel .. "!", "buy")
	ctx.Economy.pushState(player)
end

function CombatService.init(context)
	ctx = context

	Remotes.Events.RequestLaunch.OnServerEvent:Connect(onRequestLaunch)
	Remotes.Events.UpgradeRocket.OnServerEvent:Connect(onUpgradeRocket)

	Remotes.Functions.GetTargets.OnServerInvoke = function(player)
		local targets = {}
		for _, slot in ipairs(ctx.Plot.slots()) do
			local owner = slot.owner
			if owner and owner ~= player then
				targets[#targets + 1] = {
					userId = owner.UserId,
					name = owner.DisplayName,
					plotIndex = slot.index,
					immune = ctx.Plot.isImmune(slot),
				}
			end
		end
		return targets
	end
end

return CombatService
