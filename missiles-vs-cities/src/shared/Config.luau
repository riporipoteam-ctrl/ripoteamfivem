-- Central balance / tuning for Missiles vs Cities.
-- Every number a designer would want to touch lives here.

local Config = {}

Config.MaxPlayers = 5

-- Visual style switches. The default look is classic blocky "stud brick"
-- (like the reference game / old Roblox). Flip these to true to use inserted
-- Creator Store mesh models instead.
Config.UseStoreDecor = false -- Store trees/benches/fountains vs blocky ones
Config.UseStoreBuildings = false -- Store buildings vs stud-brick towers
Config.UseStoreSky = true -- community skybox (9.7k upvotes)

-- Classic stud overlay texture (transparent, tints with the brick color).
Config.StudTexture = "rbxassetid://8890102519"

-- Extra rocket silos: fire one rocket per silo, per launch.
Config.Silos = {
	Max = 3,
	Costs = { 0, 25e6, 25e9 }, -- silo 1 free, then 25M, then 25B
}

-- World layout
Config.PlotCount = 5
Config.PlotSize = 272 -- 4x4 zone grid + rocket silo strip
Config.PlotDistance = 700 -- big gaps between islands
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
	FlightTime = 8, -- includes the vertical lift-off phase
	BlastRadius = 34,
}

-- Nukes
Config.Nuke = {
	IslandCost = 995e12, -- $995 Trillion for nuke access
	Cooldown = 24 * 60 * 60, -- one nuke per day
	FlightTime = 13, -- includes the vertical lift-off phase
	ImmunityAfter = 180, -- seconds of protection after being nuked
}

Config.MissileRepairTime = 120 -- seconds for a missile-destroyed building to rebuild
Config.HpRegenDelay = 60 -- damaged (not destroyed) buildings heal after this long without hits
Config.JoinImmunity = 120 -- new joiners can't be attacked for this long

-- Rebirth: reset your buildings for a permanent income multiplier.
-- Cost scales forever, so the game never runs out of goals.
Config.Rebirth = {
	BaseCost = 25e9,
	CostGrowth = 120, -- each rebirth costs 120x the previous
	IncomePerRebirth = 1, -- +100% income per rebirth
}

-- Random world events.
Config.Events = {
	MinInterval = 200,
	MaxInterval = 340,
	FrenzyDuration = 60,
	FrenzyMult = 2,
	GemRainAmount = 15,
	MeteorCount = 8,
	MeteorDamage = 2500,
	SupplyCashMinutes = 10,
	SupplyGems = 20,
}

-- Gem shop
Config.Shop = {
	RepairAllGems = 25,
	SkipCooldownGems = 10,
	ShieldGems = 40,
	BarrageGems = 40,
}

-- Character shop (Tilly). Tiered items cost Costs[tier+1] gems.
Config.Character = {
	SpeedCosts = { 30, 60, 120 },
	SpeedPerTier = 4, -- +WalkSpeed per tier
	JumpCosts = { 25, 50, 100 },
	JumpPerTier = 12, -- +JumpPower per tier
	TrailCost = 150,
	Titles = {
		{ id = "tycoon", label = "\u{1F4B0} Tycoon", cost = 100 },
		{ id = "warlord", label = "\u{2622}\u{FE0F} WARLORD", cost = 250 },
		{ id = "legend", label = "\u{1F31F} LEGEND", cost = 500 },
	},
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
