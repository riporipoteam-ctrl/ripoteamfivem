-- Daily reward streak (7-day calendar, day 7 = free nuke charge).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)

local RewardsService = {}

local ctx

local function notify(player, msg, kind)
	Remotes.Events.Notify:FireClient(player, { msg = msg, kind = kind or "info" })
end

local function effectiveStreak(profile)
	local daily = profile.daily
	if daily.lastClaimAt > 0 and os.time() - daily.lastClaimAt > Config.DailyStreakBreak then
		return 0 -- streak expired
	end
	return daily.streak
end

function RewardsService.getData(player)
	local profile = ctx.Data.get(player)
	if not profile then
		return nil
	end
	local streak = effectiveStreak(profile)
	local sinceClaim = os.time() - profile.daily.lastClaimAt
	local canClaim = profile.daily.lastClaimAt == 0 or sinceClaim >= Config.DailyClaimWindow
	return {
		dayIndex = (streak % 7) + 1, -- the next day to claim
		canClaim = canClaim,
		nextIn = canClaim and 0 or (Config.DailyClaimWindow - sinceClaim),
	}
end

local function onClaimDaily(player)
	local profile = ctx.Data.get(player)
	if not profile then
		return
	end
	local data = RewardsService.getData(player)
	if not data.canClaim then
		notify(player, "\u{23F3} Next reward in " .. NumberFormat.clock(data.nextIn) .. "!", "bad")
		return
	end

	local reward = Config.DailyRewards[data.dayIndex]
	if reward.kind == "gems" then
		profile.gems += reward.amount
		notify(player, "\u{1F48E} Day " .. data.dayIndex .. " reward: +" .. reward.amount .. " gems!", "victory")
	elseif reward.kind == "cash_minutes" then
		local amount = math.max(2500, ctx.Economy.getIncomePerSec(player) * 60 * reward.amount)
		profile.cash += amount
		notify(player, "\u{1F4B5} Day " .. data.dayIndex .. " reward: +"
			.. NumberFormat.abbrev(amount) .. " cash!", "victory")
	elseif reward.kind == "shield" then
		profile.shields += reward.amount
		notify(player, "\u{1F6E1}\u{FE0F} Day " .. data.dayIndex .. " reward: Shield armed!", "victory")
	elseif reward.kind == "barrage" then
		profile.barrage += reward.amount
		notify(player, "\u{1F680} Day " .. data.dayIndex .. " reward: Barrage loaded!", "victory")
	elseif reward.kind == "nuke_charge" then
		profile.nukeCharges += reward.amount
		notify(player, "\u{2622}\u{FE0F} DAY 7 REWARD: FREE NUKE! Open the attack view to use it.", "victory")
	end

	profile.daily.streak = effectiveStreak(profile) + 1
	profile.daily.lastClaimAt = os.time()

	Remotes.Events.DailyData:FireClient(player, RewardsService.getData(player))
	ctx.Economy.pushState(player)
end

function RewardsService.init(context)
	ctx = context
	Remotes.Events.ClaimDaily.OnServerEvent:Connect(onClaimDaily)
end

return RewardsService
