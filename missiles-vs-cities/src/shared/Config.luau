-- Central balance / tuning for Missiles vs Cities.
-- Every number a designer would want to touch lives here.

local Config = {}

Config.MaxPlayers = 5

-- World layout
Config.PlotCount = 5
Config.PlotSize = 220
Config.PlotDistance = 420
Config.ZoneSize = 40
Config.GroundY = 4

-- Economy
Config.StartingCash = 1000
Config.StartingGems = 25
Config.IncomeInterval = 2
Config.AutosaveInterval = 120
Config.BuildingMaxLevel = 60
Config.CostGrowth = 1.32
Config.IncomeGrowth = 1.13

-- Rockets
Config.Rocket = {
	MaxLevel = 100,
	BaseDamage = 400,
	DamageGrowth = 1.16,
	BaseUpgradeCost = 2500,
	CostGrowth = 1.42,
	Cooldown = 45,
	FlightTime = 6,
	BlastRadius = 34,
}

-- Nukes
Config.Nuke = {
	IslandCost = 995e12, -- $995 Trillion for nuke access
	Cooldown = 24 * 60 * 60, -- one nuke per day
	FlightTime = 12,
	ImmunityAfter = 180, -- seconds of protection after being nuked
}

Config.MissileRepairTime = 120 -- seconds for a missile-destroyed building to rebuild
Config.HpRegenDelay = 60 -- damaged (not destroyed) buildings heal after this long without hits
Config.JoinImmunity = 120 -- new joiners can't be attacked for this long

-- Gem shop
Config.Shop = {
	RepairAllGems = 25,
	SkipCooldownGems = 10,
	ShieldGems = 40,
	BarrageGems = 40,
}
Config.GiftInterval = 15 * 60 -- free gift every 15 minutes of playtime
Config.GiftGems = 15

-- Monetization placeholders. Create gamepasses for your experience and put
-- their IDs here; 0 leaves the buttons in "not configured" mode.
Config.GamePassCash2x = 0
Config.GamePassDamage2x = 0

-- Daily rewards (index = streak day). Client renders this table directly.
Config.DailyRewards = {
	{ label = "50 Gems", emoji = "\u{1F48E}", kind = "gems", amount = 50 },
	{ label = "Cash Boost", emoji = "\u{1F4B5}", kind = "cash_minutes", amount = 10 },
	{ label = "Shield", emoji = "\u{1F6E1}\u{FE0F}", kind = "shield", amount = 1 },
	{ label = "Barrage", emoji = "\u{1F680}", kind = "barrage", amount = 1 },
	{ label = "150 Gems", emoji = "\u{1F48E}", kind = "gems", amount = 150 },
	{ label = "400 Gems", emoji = "\u{1F48E}", kind = "gems", amount = 400 },
	{ label = "FREE NUKE", emoji = "\u{2622}\u{FE0F}", kind = "nuke_charge", amount = 1 },
}
Config.DailyClaimWindow = 20 * 60 * 60 -- can claim again 20h after last claim
Config.DailyStreakBreak = 48 * 60 * 60 -- miss 48h and the streak resets

return Config
