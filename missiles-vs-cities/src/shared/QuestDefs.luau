-- Quest chains. Kinds:
--   counters (increment on events): upgrade, destroy, missile_launch, nuke
--   stats (evaluated against live values): cash, worth, rocket_level, buildings
-- The last quest of a chain can be repeatable = the game never runs out.
-- Rewards: cash, gems, shield, barrage, cashMinutes (income-scaled cash).

local QuestDefs = {}

QuestDefs.Chains = {
	mayor = {
		npc = "mayor",
		title = "\u{1F3DB}\u{FE0F} Mayor Penny",
		quests = {
			{ name = "First Bricks", desc = "Buy or upgrade buildings 3 times", kind = "upgrade", goal = 3, reward = { cash = 2500 } },
			{ name = "Growing Town", desc = "Own 5 different building types", kind = "buildings", goal = 5, reward = { cash = 20000, gems = 15 } },
			{ name = "Millionaire", desc = "Hold $1M cash at once", kind = "cash", goal = 1e6, reward = { gems = 40 } },
			{ name = "Skyline", desc = "Own 10 different building types", kind = "buildings", goal = 10, reward = { cashMinutes = 10, gems = 25 } },
			{ name = "Billion Dollar City", desc = "Reach $1B city worth", kind = "worth", goal = 1e9, reward = { gems = 75 } },
			{ name = "Full House", desc = "Own all 16 building types", kind = "buildings", goal = 16, reward = { gems = 120, shield = 1 } },
			{ name = "Trillion Club", desc = "Hold $1T cash at once", kind = "cash", goal = 1e12, reward = { gems = 250 } },
			{ name = "Quadrillionaire", desc = "Reach $1Qa city worth", kind = "worth", goal = 1e15, reward = { gems = 500 } },
			{ name = "Keep Building!", desc = "Buy or upgrade buildings 25 times", kind = "upgrade", goal = 25, reward = { cashMinutes = 20, gems = 30 }, repeatable = true },
		},
	},
	general = {
		npc = "general",
		title = "\u{1F4A5} General Boom",
		quests = {
			{ name = "First Strike", desc = "Launch a missile at another city", kind = "missile_launch", goal = 1, reward = { cash = 5000 } },
			{ name = "Demolition Job", desc = "Destroy 5 enemy buildings", kind = "destroy", goal = 5, reward = { gems = 30 } },
			{ name = "Rocket Scientist", desc = "Upgrade your rocket to Lv10", kind = "rocket_level", goal = 10, reward = { cashMinutes = 10, gems = 20 } },
			{ name = "Carpet Bomber", desc = "Launch 15 missiles", kind = "missile_launch", goal = 15, reward = { barrage = 1, gems = 25 } },
			{ name = "Warlord", desc = "Destroy 25 enemy buildings", kind = "destroy", goal = 25, reward = { gems = 100 } },
			{ name = "Big Red Button", desc = "Fire a NUKE", kind = "nuke", goal = 1, reward = { gems = 300 } },
			{ name = "Doomsday Engine", desc = "Upgrade your rocket to Lv40", kind = "rocket_level", goal = 40, reward = { gems = 400, shield = 1 } },
			{ name = "War Never Ends", desc = "Destroy 10 enemy buildings", kind = "destroy", goal = 10, reward = { gems = 35 }, repeatable = true },
		},
	},
}

return QuestDefs
