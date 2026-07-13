-- The 12 buildable city zones, in plot order (4 columns x 3 rows).

local Config = require(script.Parent.Config)

local BuildingDefs = {}

BuildingDefs.List = {
	{ id = "house", name = "Houses", emoji = "\u{1F3E0}", color = Color3.fromRGB(240, 120, 120), baseCost = 100, baseIncome = 4, hp = 600, style = "towers" },
	{ id = "apartments", name = "Apartments", emoji = "\u{1F3D8}\u{FE0F}", color = Color3.fromRGB(245, 170, 90), baseCost = 750, baseIncome = 12, hp = 900, style = "towers" },
	{ id = "shops", name = "Shops", emoji = "\u{1F3EA}", color = Color3.fromRGB(255, 220, 90), baseCost = 6500, baseIncome = 45, hp = 1200, style = "towers" },
	{ id = "bank", name = "Bank", emoji = "\u{1F3E6}", color = Color3.fromRGB(140, 220, 120), baseCost = 60e3, baseIncome = 210, hp = 1800, style = "towers" },
	{ id = "factory", name = "Factory", emoji = "\u{1F3ED}", color = Color3.fromRGB(170, 170, 180), baseCost = 550e3, baseIncome = 950, hp = 2600, style = "towers" },
	{ id = "solar", name = "Solar Field", emoji = "\u{2600}\u{FE0F}", color = Color3.fromRGB(80, 140, 235), baseCost = 5e6, baseIncome = 4200, hp = 1500, style = "panels" },
	{ id = "downtown", name = "Downtown", emoji = "\u{1F3D9}\u{FE0F}", color = Color3.fromRGB(120, 200, 255), baseCost = 48e6, baseIncome = 19e3, hp = 5200, style = "towers" },
	{ id = "stadium", name = "Stadium", emoji = "\u{1F3DF}\u{FE0F}", color = Color3.fromRGB(220, 130, 240), baseCost = 450e6, baseIncome = 88e3, hp = 6500, style = "towers" },
	{ id = "airport", name = "Airport", emoji = "\u{2708}\u{FE0F}", color = Color3.fromRGB(235, 235, 240), baseCost = 4.2e9, baseIncome = 400e3, hp = 8000, style = "panels" },
	{ id = "military", name = "Military Base", emoji = "\u{1FA96}", color = Color3.fromRGB(110, 140, 90), baseCost = 40e9, baseIncome = 1.9e6, hp = 16000, style = "towers" },
	{ id = "wind", name = "Wind Farm", emoji = "\u{1F300}", color = Color3.fromRGB(200, 240, 250), baseCost = 380e9, baseIncome = 8.8e6, hp = 9000, style = "turbines" },
	{ id = "space", name = "Space Center", emoji = "\u{1F6F0}\u{FE0F}", color = Color3.fromRGB(255, 255, 255), baseCost = 3.6e12, baseIncome = 42e6, hp = 30000, style = "towers" },
}

BuildingDefs.ById = {}
for i, def in ipairs(BuildingDefs.List) do
	def.zoneIndex = i
	BuildingDefs.ById[def.id] = def
end

-- Cost to go from (targetLevel - 1) to targetLevel. Level 1 = the initial purchase.
function BuildingDefs.upgradeCost(def, targetLevel)
	return math.floor(def.baseCost * Config.CostGrowth ^ (targetLevel - 1))
end

function BuildingDefs.income(def, level)
	if level <= 0 then
		return 0
	end
	return def.baseIncome * level * Config.IncomeGrowth ^ (level - 1)
end

function BuildingDefs.maxHp(def, level)
	return math.floor(def.hp * (1 + 0.35 * (level - 1)))
end

-- Total cash ever invested into this building at the given level (geometric sum).
function BuildingDefs.totalWorth(def, level)
	if level <= 0 then
		return 0
	end
	local g = Config.CostGrowth
	return def.baseCost * (g ^ level - 1) / (g - 1)
end

return BuildingDefs
