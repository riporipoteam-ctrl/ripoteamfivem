-- Random event for AIRPORT owners: an old pilot in a cropduster appears in the
-- distance on the radio, low on fuel, asking to land. Accept for a big payout
-- (landing + refuel + thank-you + takeoff). Decline and he keeps flying, runs
-- dry, and crashes into your city, costing you money and population.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Layout = require(Shared.Layout)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)

local PilotService = {}

local ctx
local rng = Random.new()
local pending = {} -- [player] = { answered = bool }

local function notify(player, msg, kind)
	Remotes.Events.Notify:FireClient(player, { msg = msg, kind = kind or "info" })
end

local function airportOwners()
	local list = {}
	for _, slot in ipairs(ctx.Plot.slots()) do
		if slot.owner then
			local z = slot.zones[Layout.AirportZoneIndex]
			if z and z.level > 0 then
				list[#list + 1] = slot
			end
		end
	end
	return list
end

-- Runs the whole pilot sequence for one player.
function PilotService.trigger(slot)
	local player = slot.owner
	if not player or pending[player] then
		return
	end
	pending[player] = { answered = false }

	local c = Layout.plotCenter(slot.index)
	local approach = c + Vector3.new(0, 90, 520) -- far out, high up
	local runway = Layout.zoneCenter(slot.index, Layout.AirportZoneIndex) + Vector3.new(0, 4, 0)

	-- Plane flies in from the distance (client FX).
	Remotes.Events.PlaneEvent:FireAllClients({
		phase = "approach",
		plotIndex = slot.index,
		from = approach,
		to = c + Vector3.new(0, 70, 120),
		flight = 8,
	})
	notify(player, "\u{1F4FB} *static* ...old pilot on the radio, approaching your airport...", "info")

	-- The offer with accept/decline.
	Remotes.Events.PilotOffer:FireClient(player, {
		seconds = Config.Pilot.DecideSeconds,
		reward = Config.Pilot.MinReward,
	})

	task.delay(Config.Pilot.DecideSeconds, function()
		local state = pending[player]
		if state and not state.answered then
			-- No answer counts as a decline.
			PilotService.resolve(player, false)
		end
	end)
end

function PilotService.resolve(player, accepted)
	local state = pending[player]
	if not state or state.answered then
		return
	end
	state.answered = true
	local slot = ctx.Plot.getSlot(player)
	if not slot then
		pending[player] = nil
		return
	end
	local c = Layout.plotCenter(slot.index)
	local runway = Layout.zoneCenter(slot.index, Layout.AirportZoneIndex) + Vector3.new(0, 4, 0)

	if accepted then
		Remotes.Events.PlaneEvent:FireAllClients({
			phase = "land",
			plotIndex = slot.index,
			from = c + Vector3.new(0, 70, 120),
			to = runway,
			flight = 6,
		})
		notify(player, "\u{1F468}\u{200D}\u{2708}\u{FE0F} Pilot: \"Much obliged, partner! Bringin' her down now...\"", "good")
		task.delay(6.5, function()
			local profile = ctx.Data.get(player)
			if profile then
				local bonus = math.max(0, ctx.Economy.getIncomePerSec(player) * 60 * Config.Pilot.RewardMinutes)
				local reward = Config.Pilot.MinReward + bonus
				profile.cash += reward
				notify(player, "\u{1F468}\u{200D}\u{2708}\u{FE0F} Pilot: \"Here's a lil' somethin' for the fuel and the kindness.\" +\u{1F4B5} "
					.. NumberFormat.abbrev(reward), "victory")
				ctx.Economy.pushState(player)
			end
			-- Refuel, thank-you, then take off.
			task.delay(8, function()
				notify(player, "\u{1F468}\u{200D}\u{2708}\u{FE0F} Pilot: \"All fueled up. Thank ya kindly — see ya in the skies!\"", "good")
				Remotes.Events.PlaneEvent:FireAllClients({
					phase = "takeoff",
					plotIndex = slot.index,
					from = runway,
					to = c + Vector3.new(rng:NextNumber(-200, 200), 120, -520),
					flight = 9,
				})
				pending[player] = nil
			end)
		end)
	else
		-- Declined: he keeps going, runs out of fuel, and crashes.
		notify(player, "\u{1F468}\u{200D}\u{2708}\u{FE0F} Pilot: \"Well shoot... I'll try to make it past ya then...\"", "bad")
		local minX, minZ, maxX, maxZ = Layout.plotBounds(slot.index)
		local crashPos = Vector3.new(rng:NextNumber(minX, maxX), Layout.GroundY, rng:NextNumber(minZ, maxZ))
		Remotes.Events.PlaneEvent:FireAllClients({
			phase = "crash",
			plotIndex = slot.index,
			from = c + Vector3.new(0, 70, 120),
			to = crashPos,
			flight = 7,
		})
		task.delay(7.2, function()
			if ctx.Plot.getSlot(player) ~= slot then
				pending[player] = nil
				return
			end
			local worth, count, popLost = ctx.Plot.applyBlast(slot, crashPos, 999999, 40)
			if count > 0 then
				notify(player, "\u{1F4A5} The pilot ran out of fuel and CRASHED into your city! "
					.. count .. " buildings lost, \u{1F465} -" .. NumberFormat.abbrev(popLost), "bad")
			else
				notify(player, "\u{1F4A5} The pilot crashed just outside your city. Lucky!", "info")
			end
			ctx.Economy.pushState(player)
			pending[player] = nil
		end)
	end
end

local function onPilotAnswer(player, accepted)
	PilotService.resolve(player, accepted == true)
end

function PilotService.init(context)
	ctx = context
	Remotes.Events.PilotAnswer.OnServerEvent:Connect(onPilotAnswer)

	-- Periodically offer the event to a random airport owner.
	task.spawn(function()
		while true do
			task.wait(rng:NextNumber(240, 420))
			local owners = airportOwners()
			if #owners > 0 then
				local slot = owners[rng:NextInteger(1, #owners)]
				if slot.owner and not pending[slot.owner] then
					PilotService.trigger(slot)
				end
			end
		end
	end)
end

return PilotService
