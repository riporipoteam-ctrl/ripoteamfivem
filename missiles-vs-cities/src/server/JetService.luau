-- Jets: needs an Airport built. Buy hangars (1 jet each), upgrade jets, then
-- strike an enemy city OR their rocket silos. Silo strikes knock the victim's
-- rockets offline for a while. Air defense can shoot jets down.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Layout = require(Shared.Layout)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)

local JetService = {}

local ctx

local function now()
	return os.clock()
end

local function notify(player, msg, kind)
	Remotes.Events.Notify:FireClient(player, { msg = msg, kind = kind or "info" })
end

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "Parent" then
			p[k] = v
		end
	end
	p.Parent = props.Parent
	return p
end

-- A small hangar with a parked jet, placed near the airport zone.
local function buildHangar(slot, index)
	local airportCenter = Layout.zoneCenter(slot.index, Layout.AirportZoneIndex)
	local pos = airportCenter + Vector3.new((index - 2) * 16, 0, 22)
	local model = Instance.new("Model")
	model.Name = "Hangar" .. index
	part({
		Name = "Pad",
		Size = Vector3.new(14, 0.3, 14),
		Position = pos + Vector3.new(0, 0.2, 0),
		Color = Color3.fromRGB(90, 90, 96),
		Material = Enum.Material.Concrete,
		Parent = model,
	})
	-- Parked jet: body + wings + tail.
	local jet = Instance.new("Model")
	jet.Name = "Jet"
	local body = part({
		Name = "Body",
		Size = Vector3.new(2.4, 2, 10),
		Position = pos + Vector3.new(0, 2, 0),
		Color = Color3.fromRGB(90, 100, 120),
		Material = Enum.Material.Metal,
		Parent = jet,
	})
	part({
		Name = "Nose",
		Size = Vector3.new(1.6, 1.4, 3),
		Position = pos + Vector3.new(0, 2, -6),
		Color = Color3.fromRGB(60, 70, 90),
		Parent = jet,
	})
	part({
		Name = "Wings",
		Size = Vector3.new(12, 0.5, 3),
		Position = pos + Vector3.new(0, 2, 0.5),
		Color = Color3.fromRGB(110, 120, 140),
		Parent = jet,
	})
	part({
		Name = "Tail",
		Size = Vector3.new(0.5, 2.4, 2),
		Position = pos + Vector3.new(0, 3.2, 4),
		Color = Color3.fromRGB(110, 120, 140),
		Parent = jet,
	})
	jet.PrimaryPart = body
	jet.Parent = model
	model.Parent = slot.folder
	return model
end

function JetService.updateHangars(slot, count)
	slot.hangars = slot.hangars or {}
	for i = #slot.hangars, count + 1, -1 do
		slot.hangars[i]:Destroy()
		slot.hangars[i] = nil
	end
	for i = #slot.hangars + 1, count do
		slot.hangars[i] = buildHangar(slot, i)
	end
end

local function jetDamage(profile)
	local level = profile.jetLevel or 1
	return math.floor(Config.Jets.BaseDamage * Config.Jets.DamageGrowth ^ (level - 1))
end

local function jetLaunchPos(slot)
	local c = Layout.zoneCenter(slot.index, Layout.AirportZoneIndex)
	return c + Vector3.new(0, 30, 0)
end

-- mode: "city" (bomb buildings) or "silos" (knock rockets offline)
local function impactJet(attackerUserId, targetUserId, mode, damage)
	local target = Players:GetPlayerByUserId(targetUserId)
	local attacker = Players:GetPlayerByUserId(attackerUserId)
	if not target then
		return
	end
	local slot = ctx.Plot.getSlot(target)
	if not slot then
		return
	end

	if ctx.Defense and ctx.Defense.tryIntercept(slot, "jet", Layout.plotCenter(slot.index)) then
		if attacker then
			notify(attacker, "\u{1F6E1}\u{FE0F} " .. target.DisplayName .. "'s air defense shot down your jet!", "bad")
		end
		notify(target, "\u{1F6E1}\u{FE0F} Your air defense downed an enemy jet!", "good")
		return
	end

	if mode == "silos" then
		local session = ctx.session[target]
		if session then
			session.siloDisabledUntil = now() + Config.Jets.SiloDisable
		end
		-- Visual: briefly hide the victim's silo rockets.
		for i = 1, Config.Silos.Max do
			ctx.Plot.setSiloRocket(slot, i, false)
		end
		task.delay(Config.Jets.SiloDisable, function()
			if ctx.Plot.getSlot(target) == slot then
				local p = ctx.Data.get(target)
				for i = 1, (p and p.siloCount or 1) do
					ctx.Plot.setSiloRocket(slot, i, true)
				end
			end
		end)
		notify(target, "\u{2708}\u{FE0F} Your ROCKET SILOS were bombed! Rockets offline for "
			.. NumberFormat.clock(Config.Jets.SiloDisable) .. "!", "bad")
		if attacker then
			notify(attacker, "\u{2708}\u{FE0F} Direct hit on " .. target.DisplayName
				.. "'s silos! Their rockets are down.", "victory")
			ctx.Economy.pushState(attacker)
		end
		ctx.Economy.pushState(target)
	else
		-- City strike: hit a random spot with a jet-sized blast.
		local minX, minZ, maxX, maxZ = Layout.plotBounds(slot.index)
		local pos = Vector3.new((minX + maxX) / 2, Layout.GroundY, (minZ + maxZ) / 2)
		local worth, count, popLost = ctx.Plot.applyBlast(slot, pos, damage, 46)
		if count > 0 and attacker then
			ctx.Economy.addCash(attacker, worth)
			notify(attacker, "\u{2708}\u{FE0F} Your jets destroyed " .. count .. " buildings! +\u{1F4B5} "
				.. NumberFormat.abbrev(worth), "victory")
			notify(target, "\u{2708}\u{FE0F} " .. attacker.DisplayName .. "'s jets bombed "
				.. count .. " buildings! \u{1F465} -" .. NumberFormat.abbrev(popLost), "bad")
			ctx.Economy.pushState(attacker)
		elseif attacker then
			notify(attacker, "\u{2708}\u{FE0F} Jets bombed the city but nothing was destroyed.", "info")
		end
		ctx.Economy.pushState(target)
	end
end

local function onRequestJet(player, targetUserId, mode)
	if type(targetUserId) ~= "number" then
		return
	end
	mode = (mode == "silos") and "silos" or "city"
	local session = ctx.session[player]
	local profile = ctx.Data.get(player)
	local mySlot = ctx.Plot.getSlot(player)
	if not session or not profile or not mySlot then
		return
	end
	if (profile.hangars or 0) <= 0 then
		notify(player, "\u{2708}\u{FE0F} Build an Airport and a hangar first!", "bad")
		return
	end
	if now() < (session.jetReadyAt or 0) then
		notify(player, "\u{2708}\u{FE0F} Jets rearming! " .. NumberFormat.clock((session.jetReadyAt or 0) - now()), "bad")
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == player then
		notify(player, "That player isn't here!", "bad")
		return
	end
	local targetSlot = ctx.Plot.getSlot(target)
	if not targetSlot then
		return
	end
	if ctx.Plot.isImmune(targetSlot) then
		notify(player, "\u{1F6E1}\u{FE0F} " .. target.DisplayName .. " is protected right now!", "bad")
		return
	end

	session.jetReadyAt = now() + Config.Jets.Cooldown
	local hangars = math.clamp(profile.hangars or 1, 1, Config.Jets.MaxHangars)
	local damage = jetDamage(profile)
	local from = jetLaunchPos(mySlot)
	local toCenter = Layout.plotCenter(targetSlot.index)

	for i = 1, hangars do
		local flight = Config.Jets.FlightTime + (i - 1) * 0.5
		Remotes.Events.JetEvent:FireAllClients({
			from = from + Vector3.new((i - 2) * 10, 0, 0),
			to = Vector3.new(toCenter.X, Layout.GroundY + 20, toCenter.Z),
			flight = flight,
			mode = mode,
		})
		task.delay(flight, impactJet, player.UserId, target.UserId, mode, damage)
	end

	Remotes.Events.Alarm:FireClient(target, {
		kind = "jet",
		pos = toCenter,
		eta = Config.Jets.FlightTime,
	})
	notify(target, "\u{2708}\u{FE0F} " .. player.DisplayName .. " is sending " .. hangars
		.. " JET" .. (hangars > 1 and "S" or "") .. " at your "
		.. (mode == "silos" and "rocket silos" or "city") .. "!", "bad")
	ctx.Economy.pushState(player)
end

function JetService.init(context)
	ctx = context
	Remotes.Events.RequestJet.OnServerEvent:Connect(onRequestJet)
end

return JetService
