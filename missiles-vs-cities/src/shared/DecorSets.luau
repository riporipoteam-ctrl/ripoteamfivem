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

return DecorSets
