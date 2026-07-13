-- Lobby NPCs: looks, positions, dialogue lines and what they do.
-- Positions are offsets from the lobby center.

local NPCDefs = {}

NPCDefs.List = {
	{
		id = "shopkeeper",
		name = "Benny the Shopkeeper",
		emoji = "\u{1F6D2}",
		shirt = Color3.fromRGB(60, 150, 240),
		pants = Color3.fromRGB(60, 60, 70),
		hat = Color3.fromRGB(240, 200, 40),
		pos = Vector3.new(32, 0, 14),
		facing = -90,
		action = "shop",
		actionLabel = "\u{1F6D2} Open Shop",
		lines = {
			"Welcome to Benny's Battle Bazaar! \u{1F6D2}",
			"Shields, barrages, instant repairs... everything a city at war could need!",
			"All prices in gems \u{1F48E} — grab your free gift every 15 minutes to stock up!",
		},
	},
	{
		id = "tailor",
		name = "Tilly the Tailor",
		emoji = "\u{1FA84}",
		shirt = Color3.fromRGB(220, 130, 240),
		pants = Color3.fromRGB(120, 80, 160),
		hat = Color3.fromRGB(255, 120, 180),
		pos = Vector3.new(-32, 0, 14),
		facing = 90,
		action = "charshop",
		actionLabel = "\u{2728} Character Shop",
		lines = {
			"Darling! You simply cannot conquer the world dressed like THAT. \u{1FA84}",
			"I've got speed boosts, mega jumps, glorious titles and a rainbow trail!",
			"A true warlord should LOOK the part, don't you think?",
		},
	},
	{
		id = "mayor",
		name = "Mayor Penny",
		emoji = "\u{1F3DB}\u{FE0F}",
		shirt = Color3.fromRGB(90, 200, 120),
		pants = Color3.fromRGB(50, 90, 60),
		hat = Color3.fromRGB(240, 240, 245),
		pos = Vector3.new(20, 0, -30),
		facing = 160,
		action = "quest",
		chain = "mayor",
		actionLabel = "\u{1F4DC} View Quests",
		lines = {
			"Ah, a new city builder! Welcome, welcome! \u{1F3DB}\u{FE0F}",
			"This town won't grow itself — I have building contracts with YOUR name on them.",
			"Complete my quests and the city treasury will reward you handsomely!",
		},
	},
	{
		id = "general",
		name = "General Boom",
		emoji = "\u{1F4A5}",
		shirt = Color3.fromRGB(110, 140, 90),
		pants = Color3.fromRGB(60, 75, 50),
		hat = Color3.fromRGB(60, 75, 50),
		pos = Vector3.new(-20, 0, -30),
		facing = -160,
		action = "quest",
		chain = "general",
		actionLabel = "\u{1F4DC} View Quests",
		lines = {
			"SOLDIER! You call that a rocket silo?! \u{1F4A5}",
			"Out there five cities compete for glory, and only firepower decides who eats!",
			"Complete my combat missions and I'll make it worth your while. DISMISSED!",
		},
	},
}

NPCDefs.ById = {}
for _, def in ipairs(NPCDefs.List) do
	NPCDefs.ById[def.id] = def
end

return NPCDefs
