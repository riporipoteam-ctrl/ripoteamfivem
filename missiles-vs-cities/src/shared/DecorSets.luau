-- Curated free models from the Roblox Creator Store (create.roblox.com/store),
-- picked by community rating. The DecorService inserts these at runtime with
-- InsertService and falls back gracefully if any id fails to load.
-- Swap in your own favorites: any free model id works.

local DecorSets = {}

-- Multiple candidates per category; the first that loads gets used.
DecorSets.Models = {
	tree = { 4893246329, 3287226226, 12549617200 }, -- "Low Poly Tree" (828+ votes)
	bush = { 8647777369, 10302128725, 15022313886 }, -- "Bush" (1.8k+ votes)
	bench = { 741384218, 393609716, 8924251735 }, -- "The Generic Park Bench"
	lamp = { 15472204631, 11146095708, 15323049348 }, -- "Street Lamp Light"
	fountain = { 11423259371, 13782728612, 2332885124 }, -- "Fountain"
	rock = { 7299047040, 16098456067 }, -- "Low Poly Rock"
	car = { 11493825596, 113700576399250 }, -- "Low Poly Car"
}

-- Skybox models (contain a Sky object). "Sky-Realistic" has 9.7k upvotes.
DecorSets.Sky = { 10256505900, 4607457995, 7108851308 }

-- Target sizes (studs) used to auto-scale whatever loads.
DecorSets.TargetSize = {
	tree = 18, -- height
	bush = 4,
	bench = 7, -- width
	lamp = 12, -- height
	fountain = 14, -- width
	rock = 5,
	car = 13, -- length
}

-- Store models for the 16 tycoon buildings themselves, curated from
-- create.roblox.com/store. mode "cluster" = several copies that multiply
-- with level; "single" = one centerpiece that grows with level.
-- size = target footprint (or height when byHeight). If every id in a
-- category fails to load, the game falls back to its built-in part visuals.
DecorSets.Buildings = {
	house = { ids = { 18144266950, 105797187065697, 91447454268215 }, mode = "cluster", size = 15 },
	apartments = { ids = { 15075550418, 15082419807 }, mode = "cluster", size = 16 },
	shops = { ids = { 9642714623, 18828724532 }, mode = "cluster", size = 16 },
	bank = { ids = { 76831024602896 }, mode = "cluster", size = 16 },
	factory = { ids = { 11387823607, 78205505459731 }, mode = "single", size = 34 },
	solar = { ids = { 11100628682, 15174071780 }, mode = "cluster", size = 12 },
	downtown = { ids = { 12006622902, 85506482351178, 114750850222093 }, mode = "cluster", size = 16 },
	stadium = { ids = { 107182109387966 }, mode = "single", size = 36 },
	airport = { ids = { 137558548393747, 105826236392834 }, mode = "single", size = 34 },
	military = { ids = { 120453129382585, 96964466281091 }, mode = "cluster", size = 14 },
	wind = { ids = { 6221197459, 11464875249 }, mode = "cluster", size = 26, byHeight = true },
	space = { ids = { 126157921427052, 11714293744 }, mode = "single", size = 28, byHeight = true },
	techhub = { ids = { 13893512148, 5140904246 }, mode = "cluster", size = 16 },
	casino = { ids = { 8984780407 }, mode = "single", size = 34 },
	port = { ids = { 72746749225388, 92609497200026 }, mode = "single", size = 34 },
	goldtower = { ids = { 8533751203, 119160909 }, mode = "single", size = 30, byHeight = true },
}

-- Destroyed-building rubble (replaces the part rubble when it loads).
DecorSets.Rubble = { 8389261449, 95266753561513 }

return DecorSets
