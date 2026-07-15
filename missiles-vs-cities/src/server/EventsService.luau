-- Random world events on a timer: Cash Frenzy, Gem Rain, Meteor Shower,
-- Supply Drop. Keeps servers lively and unpredictable.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Layout = require(Shared.Layout)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)

local EventsService = {}

local ctx
local rng = Random.new()

local function announce(kind, msg, duration)
	Remotes.Events.GameEvent:FireAllClients({ kind = kind, msg = msg, duration = duration or 0 })
end

local function notify(player, msg, kindName)
	Remotes.Events.Notify:FireClient(player, { msg = msg, kind = kindName or "info" })
end

local function cashFrenzy()
	announce("frenzy", "\u{1F4B8} CASH FRENZY! All income x" .. Config.Events.FrenzyMult
		.. " for " .. Config.Events.FrenzyDuration .. " seconds!", Config.Events.FrenzyDuration)
	ctx.eventCashMult = Config.Events.FrenzyMult
	task.delay(Config.Events.FrenzyDuration, function()
		ctx.eventCashMult = 1
	end)
end

local function gemRain()
	announce("gems", "\u{1F48E} GEM RAIN! Everyone gets +" .. Config.Events.GemRainAmount .. " gems!", 6)
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = ctx.Data.get(player)
		if profile then
			profile.gems += Config.Events.GemRainAmount
			ctx.Economy.pushState(player)
		end
	end
end

local function meteorShower()
	local occupied = {}
	for _, slot in ipairs(ctx.Plot.slots()) do
		if slot.owner and not ctx.Plot.isImmune(slot) then
			occupied[#occupied + 1] = slot
		end
	end
	if #occupied == 0 then
		return
	end
	announce("meteor", "\u{2604}\u{FE0F} METEOR SHOWER! Small meteors are falling on cities!", 14)

	for i = 1, Config.Events.MeteorCount do
		task.delay(1 + i * 1.2, function()
			local slot = occupied[rng:NextInteger(1, #occupied)]
			if not slot.owner then
				return
			end
			local minX, minZ, maxX, maxZ = Layout.plotBounds(slot.index)
			local pos = Vector3.new(rng:NextNumber(minX, maxX), Layout.GroundY, rng:NextNumber(minZ, maxZ))
			local from = pos + Vector3.new(rng:NextNumber(-80, 80), 420, rng:NextNumber(-80, 80))
			local flight = 2.2
			Remotes.Events.MissileEvent:FireAllClients({
				kind = "meteor",
				from = from,
				to = pos,
				flight = flight,
			})
			task.delay(flight, function()
				if slot.owner then
					-- No payout and no shield use for weather damage.
					local _, count = ctx.Plot.applyBlast(slot, pos, Config.Events.MeteorDamage)
					if count > 0 then
						notify(slot.owner, "\u{2604}\u{FE0F} A meteor smashed " .. count .. " of your buildings!", "bad")
					end
				end
			end)
		end)
	end
end

local function supplyDrop()
	local occupied = {}
	for _, slot in ipairs(ctx.Plot.slots()) do
		if slot.owner then
			occupied[#occupied + 1] = slot
		end
	end
	if #occupied == 0 then
		return
	end
	local slot = occupied[rng:NextInteger(1, #occupied)]
	announce("supply", "\u{1F4E6} SUPPLY DROP on " .. slot.owner.DisplayName
		.. "'s island! First one to grab it wins!", 25)

	local c = Layout.plotCenter(slot.index)
	local pos = Vector3.new(
		c.X + rng:NextNumber(-80, 80),
		Config.GroundY + 2,
		c.Z + rng:NextNumber(-80, 80)
	)
	local crate = Instance.new("Part")
	crate.Name = "SupplyDrop"
	crate.Size = Vector3.new(4, 4, 4)
	crate.Position = pos + Vector3.new(0, 60, 0)
	crate.Anchored = true
	crate.Color = Color3.fromRGB(255, 215, 80)
	crate.Material = Enum.Material.Neon
	crate.Parent = workspace

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(16, 0, 5, 0)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 1000
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 230, 120)
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Text = "\u{1F4E6} SUPPLY DROP!"
	label.Parent = gui
	gui.Parent = crate

	-- Drop animation.
	task.spawn(function()
		for _ = 1, 30 do
			task.wait(0.05)
			if not crate.Parent then
				return
			end
			crate.Position -= Vector3.new(0, 2, 0)
		end
		crate.Position = pos
	end)

	local claimed = false
	crate.Touched:Connect(function(hit)
		if claimed then
			return
		end
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		claimed = true
		local profile = ctx.Data.get(player)
		if profile then
			local cashReward = math.max(5000, ctx.Economy.getIncomePerSec(player) * 60 * Config.Events.SupplyCashMinutes)
			profile.cash += cashReward
			profile.gems += Config.Events.SupplyGems
			announce("supply_claim", "\u{1F4E6} " .. player.DisplayName .. " grabbed the supply drop! (+\u{1F4B5} "
				.. NumberFormat.abbrev(cashReward) .. " +\u{1F48E} " .. Config.Events.SupplyGems .. ")", 5)
			ctx.Economy.pushState(player)
		end
		crate:Destroy()
	end)

	task.delay(60, function()
		if crate.Parent then
			crate:Destroy()
		end
	end)
end

-- Double-gems minute: gifts and gem rewards pay extra (flavour announce).
local function goldRush()
	announce("frenzy", "\u{2728} GOLD RUSH! Collect fast — income x3 for 45s!", 45)
	ctx.eventCashMult = 3
	task.delay(45, function()
		ctx.eventCashMult = 1
	end)
end

local EVENTS = { cashFrenzy, gemRain, meteorShower, supplyDrop, goldRush }

function EventsService.fireRandom()
	local event = EVENTS[rng:NextInteger(1, #EVENTS)]
	task.spawn(event)
end

function EventsService.init(context)
	ctx = context
	ctx.eventCashMult = 1
	task.spawn(function()
		while true do
			task.wait(rng:NextNumber(Config.Events.MinInterval, Config.Events.MaxInterval))
			if #Players:GetPlayers() > 0 then
				EventsService.fireRandom()
			end
		end
	end)
end

return EventsService
