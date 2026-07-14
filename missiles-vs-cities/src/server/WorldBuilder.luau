-- Builds the map: 5 far-apart self-contained islands. Each island has the
-- 4x4 city grid, rocket silo, nuke-access pad, and a front town square
-- (spawn, shop stand, NPCs, leaderboard, rebirth shrine). No central island.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Layout = require(Shared.Layout)
local BuildingDefs = require(Shared.BuildingDefs)
local NumberFormat = require(Shared.NumberFormat)

local WorldBuilder = {}

local COLOR_GRASS = Color3.fromRGB(96, 186, 78)
local COLOR_SAND = Color3.fromRGB(226, 200, 140)
local COLOR_ROAD = Color3.fromRGB(48, 48, 54)
local COLOR_DASH = Color3.fromRGB(248, 214, 62)
local COLOR_ZONE = Color3.fromRGB(116, 202, 94)
local COLOR_SIDEWALK = Color3.fromRGB(168, 168, 172)
local COLOR_PLAZA = Color3.fromRGB(196, 190, 178)

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "Parent" then
			p[k] = v
		end
	end
	p.Parent = props.Parent
	return p
end

local function billboard(adornee, sizeX, sizeY, offsetY, maxDistance)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(sizeX, 0, sizeY, 0)
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = maxDistance or 250
	gui.AlwaysOnTop = false
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Text = ""
	label.Parent = gui
	gui.Parent = adornee
	return gui, label
end

local function buildTree(pos, parent)
	part({
		Name = "Trunk",
		Size = Vector3.new(1.8, 6, 1.8),
		Position = pos + Vector3.new(0, 3, 0),
		Color = Color3.fromRGB(118, 84, 50),
		Material = Enum.Material.Wood,
		Parent = parent,
	})
	part({
		Name = "Leaves",
		Size = Vector3.new(6.5, 4.5, 6.5),
		Position = pos + Vector3.new(0, 8, 0),
		Color = Color3.fromRGB(62, 158, 62),
		Material = Enum.Material.Grass,
		Parent = parent,
	})
	part({
		Name = "Leaves2",
		Size = Vector3.new(4.5, 3, 4.5),
		Position = pos + Vector3.new(0, 11, 0),
		Color = Color3.fromRGB(74, 176, 70),
		Material = Enum.Material.Grass,
		Parent = parent,
	})
end

local function buildLamp(pos, parent)
	part({
		Name = "LampPole",
		Size = Vector3.new(0.7, 9, 0.7),
		Position = pos + Vector3.new(0, 4.5, 0),
		Color = Color3.fromRGB(70, 70, 78),
		Material = Enum.Material.Metal,
		Parent = parent,
	})
	local bulb = part({
		Name = "LampBulb",
		Size = Vector3.new(1.4, 1, 1.4),
		Position = pos + Vector3.new(0, 9.4, 0),
		Color = Color3.fromRGB(255, 236, 160),
		Material = Enum.Material.Neon,
		Parent = parent,
	})
	local light = Instance.new("PointLight")
	light.Range = 22
	light.Brightness = 1.2
	light.Color = Color3.fromRGB(255, 230, 160)
	light.Parent = bulb
end

local function buildRoads(center, folder)
	for _, x in ipairs(Layout.RoadXs) do
		part({
			Name = "RoadV",
			Size = Vector3.new(12, 0.2, Config.PlotSize),
			Position = Vector3.new(center.X + x, Config.GroundY + 0.1, center.Z),
			Color = COLOR_ROAD,
			Material = Enum.Material.Asphalt,
			Parent = folder,
		})
	end
	local dashLimit = Config.PlotSize / 2 - 16
	for _, z in ipairs(Layout.RoadZs) do
		part({
			Name = "RoadH",
			Size = Vector3.new(Config.PlotSize, 0.2, 12),
			Position = Vector3.new(center.X, Config.GroundY + 0.14, center.Z + z),
			Color = COLOR_ROAD,
			Material = Enum.Material.Asphalt,
			Parent = folder,
		})
		local x = -dashLimit
		while x <= dashLimit do
			part({
				Name = "Dash",
				Size = Vector3.new(6, 0.05, 1.6),
				Position = Vector3.new(center.X + x, Config.GroundY + 0.26, center.Z + z),
				Color = COLOR_DASH,
				Material = Enum.Material.Neon,
				Parent = folder,
			})
			x += 24
		end
	end
end

local function buildFence(center, folder)
	local h = 3
	local halfX = Config.PlotSize / 2
	local backZ = -halfX
	local frontZ = halfX + Layout.TownDepth
	local depth = frontZ - backZ
	local midZ = (frontZ + backZ) / 2
	local segs = {
		{ Vector3.new(center.X, Config.GroundY + h / 2, center.Z + backZ), Vector3.new(Config.PlotSize, h, 1) },
		{ Vector3.new(center.X, Config.GroundY + h / 2, center.Z + frontZ), Vector3.new(Config.PlotSize, h, 1) },
		{ Vector3.new(center.X - halfX, Config.GroundY + h / 2, center.Z + midZ), Vector3.new(1, h, depth) },
		{ Vector3.new(center.X + halfX, Config.GroundY + h / 2, center.Z + midZ), Vector3.new(1, h, depth) },
	}
	for _, seg in ipairs(segs) do
		part({
			Name = "Fence",
			Size = seg[2],
			Position = seg[1],
			Color = Color3.fromRGB(196, 164, 108),
			Material = Enum.Material.WoodPlanks,
			Parent = folder,
		})
	end
end

local function buildSilo(plotIndex, folder)
	local pos = Layout.siloPos(plotIndex)

	part({
		Name = "SiloPad",
		Size = Vector3.new(36, 0.4, 36),
		Position = pos + Vector3.new(0, 0.2, 0),
		Color = Color3.fromRGB(240, 200, 40),
		Material = Enum.Material.DiamondPlate,
		Parent = folder,
	})
	for i = -1, 1 do
		part({
			Name = "SiloStripe",
			Size = Vector3.new(4, 0.1, 36),
			Position = pos + Vector3.new(i * 12, 0.5, 0),
			Color = Color3.fromRGB(30, 30, 30),
			Parent = folder,
		})
	end

	for _, corner in ipairs({ Vector3.new(-8, 0, -8), Vector3.new(8, 0, -8), Vector3.new(-8, 0, 8), Vector3.new(8, 0, 8) }) do
		part({
			Name = "SiloColumn",
			Size = Vector3.new(2, 26, 2),
			Position = pos + corner + Vector3.new(0, 13, 0),
			Color = Color3.fromRGB(150, 150, 158),
			Material = Enum.Material.Metal,
			Parent = folder,
		})
	end
	part({
		Name = "SiloTop",
		Size = Vector3.new(20, 2, 20),
		Position = pos + Vector3.new(0, 27, 0),
		Color = Color3.fromRGB(110, 110, 118),
		Material = Enum.Material.DiamondPlate,
		Parent = folder,
	})

	local body = part({
		Name = "SiloRocket",
		Size = Vector3.new(5, 16, 5),
		Position = pos + Vector3.new(0, 9, 0),
		Color = Color3.fromRGB(240, 240, 245),
		Material = Enum.Material.SmoothPlastic,
		Parent = folder,
	})
	part({
		Name = "SiloRocketNose",
		Size = Vector3.new(3.4, 4, 3.4),
		Position = pos + Vector3.new(0, 19, 0),
		Color = Color3.fromRGB(230, 60, 60),
		Parent = folder,
	})
	for _, off in ipairs({ Vector3.new(-3.2, 0, 0), Vector3.new(3.2, 0, 0), Vector3.new(0, 0, -3.2), Vector3.new(0, 0, 3.2) }) do
		part({
			Name = "SiloFin",
			Size = Vector3.new(1.4, 5, 1.4),
			Position = pos + off + Vector3.new(0, 2.5, 0),
			Color = Color3.fromRGB(230, 60, 60),
			Parent = folder,
		})
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RocketPrompt"
	prompt.ActionText = "Rocket Controls"
	prompt.ObjectText = "Rocket Silo"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	local _, label = billboard(body, 18, 6, 16, 300)
	label.Text = "\u{1F680} Rocket Silo"

	-- Nuke-access pad right next to the silo.
	local nukePadPos = pos + Vector3.new(42, 0.4, 0)
	local nukePad = part({
		Name = "NukeBuyPad",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 12, 12),
		CFrame = CFrame.new(nukePadPos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(190, 90, 240),
		Material = Enum.Material.Neon,
		Parent = folder,
	})
	local _, nukeLabel = billboard(nukePad, 20, 9, 7, 220)
	nukeLabel.Text = "\u{2622}\u{FE0F} NUKE ACCESS\n\u{1F4B5} " .. NumberFormat.abbrev(Config.Nuke.IslandCost)
		.. "\nOne nuke every 24h!"
	local nukePrompt = Instance.new("ProximityPrompt")
	nukePrompt.Name = "NukePrompt"
	nukePrompt.ActionText = "Nuke Controls"
	nukePrompt.ObjectText = "Nuclear Option"
	nukePrompt.HoldDuration = 0
	nukePrompt.MaxActivationDistance = 14
	nukePrompt.RequiresLineOfSight = false
	nukePrompt.Parent = nukePad

	return body, nukePad
end

local function buildTownSquare(plotIndex, folder)
	local c = Layout.plotCenter(plotIndex)
	local half = Config.PlotSize / 2

	-- Plaza pavement across the town strip.
	part({
		Name = "Plaza",
		Size = Vector3.new(Config.PlotSize, 0.3, Layout.TownDepth - 4),
		Position = Vector3.new(c.X, Config.GroundY + 0.15, c.Z + half + Layout.TownDepth / 2),
		Color = COLOR_PLAZA,
		Material = Enum.Material.Concrete,
		Parent = folder,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn" .. plotIndex
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(c.X, Config.GroundY + 0.6, c.Z + half + 16)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Color = Color3.fromRGB(90, 160, 240)
	spawn.Parent = folder

	-- Benny's shop stand.
	local standX = c.X + 80
	local standZ = c.Z + half + 34
	part({
		Name = "Counter",
		Size = Vector3.new(10, 3.2, 2),
		Position = Vector3.new(standX, Config.GroundY + 1.6, standZ - 4),
		CanCollide = true,
		Color = Color3.fromRGB(150, 116, 78),
		Material = Enum.Material.WoodPlanks,
		Parent = folder,
	})
	part({
		Name = "PostL",
		Size = Vector3.new(0.8, 8, 0.8),
		Position = Vector3.new(standX - 4.5, Config.GroundY + 4, standZ + 1.5),
		Color = Color3.fromRGB(120, 90, 60),
		Material = Enum.Material.Wood,
		Parent = folder,
	})
	part({
		Name = "PostR",
		Size = Vector3.new(0.8, 8, 0.8),
		Position = Vector3.new(standX + 4.5, Config.GroundY + 4, standZ + 1.5),
		Color = Color3.fromRGB(120, 90, 60),
		Material = Enum.Material.Wood,
		Parent = folder,
	})
	for i = 0, 3 do
		part({
			Name = "Awning",
			Size = Vector3.new(2.6, 0.4, 6.5),
			CFrame = CFrame.new(standX - 3.9 + i * 2.6, Config.GroundY + 8.4, standZ - 1)
				* CFrame.Angles(math.rad(-12), 0, 0),
			Color = (i % 2 == 0) and Color3.fromRGB(235, 60, 60) or Color3.fromRGB(240, 240, 245),
			Parent = folder,
		})
	end

	-- Rebirth shrine.
	local shrineX = c.X + 118
	local shrineZ = c.Z + half + 44
	local pedestal = part({
		Name = "Pedestal",
		Size = Vector3.new(7, 2, 7),
		Position = Vector3.new(shrineX, Config.GroundY + 1, shrineZ),
		CanCollide = true,
		Color = Color3.fromRGB(255, 215, 80),
		Material = Enum.Material.Metal,
		Parent = folder,
	})
	local orb = part({
		Name = "Orb",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(4, 4, 4),
		Position = Vector3.new(shrineX, Config.GroundY + 4.5, shrineZ),
		Color = Color3.fromRGB(255, 230, 120),
		Material = Enum.Material.Neon,
		Parent = folder,
	})
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120))
	sparkle.Rate = 5
	sparkle.Lifetime = NumberRange.new(0.8, 1.4)
	sparkle.Speed = NumberRange.new(2, 4)
	sparkle.Parent = orb
	local _, shrineLabel = billboard(orb, 18, 7, 5, 240)
	shrineLabel.Text = "\u{1F31F} REBIRTH SHRINE\nReset city \u{2192} PERMANENT\nincome multiplier!"
	shrineLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
	local shrinePrompt = Instance.new("ProximityPrompt")
	shrinePrompt.Name = "RebirthPrompt"
	shrinePrompt.ActionText = "Rebirth"
	shrinePrompt.ObjectText = "Rebirth Shrine"
	shrinePrompt.HoldDuration = 0.5
	shrinePrompt.MaxActivationDistance = 12
	shrinePrompt.RequiresLineOfSight = false
	shrinePrompt.Parent = pedestal

	-- Decorations.
	buildTree(Vector3.new(c.X - 122, Config.GroundY, c.Z + half + 14), folder)
	buildTree(Vector3.new(c.X + 122, Config.GroundY, c.Z + half + 12), folder)
	buildLamp(Vector3.new(c.X - 30, Config.GroundY, c.Z + half + 12), folder)
	buildLamp(Vector3.new(c.X + 30, Config.GroundY, c.Z + half + 12), folder)

	-- Owner banner pole.
	local pole = part({
		Name = "BannerPole",
		Size = Vector3.new(1, 12, 1),
		Position = Vector3.new(c.X - 118, Config.GroundY + 6, c.Z + half + 40),
		Color = Color3.fromRGB(120, 120, 128),
		Material = Enum.Material.Metal,
		Parent = folder,
	})
	local bannerGui, bannerLabel = billboard(pole, 26, 8, 8, 1400)
	bannerGui.AlwaysOnTop = true
	bannerLabel.Text = "\u{1F3DD}\u{FE0F} Empty Plot"

	-- Leaderboard placement info for LeaderboardService.
	local boardPos = Vector3.new(c.X, Config.GroundY, c.Z + half + Layout.TownDepth - 6)

	return {
		bannerLabel = bannerLabel,
		boardPos = boardPos,
		npcAnchors = {
			shopkeeper = Vector3.new(standX, Config.GroundY, standZ + 2.5),
			tailor = Vector3.new(c.X - 80, Config.GroundY, c.Z + half + 34),
			mayor = Vector3.new(c.X + 32, Config.GroundY, c.Z + half + 46),
			general = Vector3.new(c.X - 32, Config.GroundY, c.Z + half + 46),
		},
		npcLookAt = Vector3.new(c.X, Config.GroundY, c.Z + half + 16),
	}
end

local function buildPlot(plotIndex, root)
	local center = Layout.plotCenter(plotIndex)
	local folder = Instance.new("Folder")
	folder.Name = "Plot" .. plotIndex
	folder.Parent = root

	local half = Config.PlotSize / 2
	local depthZ = Config.PlotSize + Layout.TownDepth
	local islandCenterZ = center.Z + Layout.TownDepth / 2

	part({
		Name = "Island",
		Size = Vector3.new(Config.PlotSize, 10, depthZ),
		Position = Vector3.new(center.X, -1, islandCenterZ),
		Color = COLOR_GRASS,
		Material = Enum.Material.Grass,
		Parent = folder,
	})
	part({
		Name = "IslandRim",
		Size = Vector3.new(Config.PlotSize + 18, 8, depthZ + 18),
		Position = Vector3.new(center.X, -1.5, islandCenterZ),
		Color = COLOR_SAND,
		Material = Enum.Material.Sand,
		Parent = folder,
	})

	buildRoads(center, folder)
	buildFence(center, folder)

	local town = buildTownSquare(plotIndex, folder)

	local zoneData = {}
	for zi = 1, #BuildingDefs.List do
		local zCenter = Layout.zoneCenter(plotIndex, zi)
		part({
			Name = "Sidewalk",
			Size = Vector3.new(Config.ZoneSize + 4, 0.24, Config.ZoneSize + 4),
			Position = Vector3.new(zCenter.X, Config.GroundY + 0.12, zCenter.Z),
			Color = COLOR_SIDEWALK,
			Material = Enum.Material.Concrete,
			Parent = folder,
		})
		local plate = part({
			Name = "ZonePlate",
			Size = Vector3.new(Config.ZoneSize, 0.3, Config.ZoneSize),
			Position = Vector3.new(zCenter.X, Config.GroundY + 0.18, zCenter.Z),
			Color = COLOR_ZONE,
			Material = Enum.Material.Grass,
			Parent = folder,
		})

		local buildings = Instance.new("Model")
		buildings.Name = "Buildings" .. zi
		buildings.Parent = folder

		local padPos = Layout.padPos(plotIndex, zi)
		local pad = part({
			Name = "Pad" .. zi,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, 9, 9),
			CFrame = CFrame.new(padPos.X, Config.GroundY + 0.4, padPos.Z) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(80, 235, 90),
			Material = Enum.Material.Neon,
			Parent = folder,
		})
		local padGui, padLabel = billboard(pad, 16, 8, 7, 180)
		padGui.AlwaysOnTop = false

		zoneData[zi] = {
			plate = plate,
			pad = pad,
			padLabel = padLabel,
			buildings = buildings,
		}
	end

	local siloBody, nukePad = buildSilo(plotIndex, folder)

	return {
		index = plotIndex,
		folder = folder,
		zoneData = zoneData,
		bannerLabel = town.bannerLabel,
		siloBody = siloBody,
		nukePad = nukePad,
		boardPos = town.boardPos,
		npcAnchors = town.npcAnchors,
		npcLookAt = town.npcLookAt,
	}
end

function WorldBuilder.build()
	local root = Instance.new("Folder")
	root.Name = "GameWorld"
	root.Parent = workspace

	-- Ocean.
	workspace.Terrain:FillBlock(CFrame.new(0, -8, 0), Vector3.new(6000, 10, 6000), Enum.Material.Water)

	local slots = {}
	for i = 1, Config.PlotCount do
		slots[i] = buildPlot(i, root)
	end

	-- Bright cartoon lighting with modern rendering.
	Lighting.Brightness = 3
	Lighting.ClockTime = 13.5
	Lighting.Ambient = Color3.fromRGB(130, 130, 135)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 150, 165)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.ShadowSoftness = 0.15
	Lighting.ExposureCompensation = 0.05
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.28
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting

	-- Volumetric clouds.
	local clouds = Instance.new("Clouds")
	clouds.Cover = 0.52
	clouds.Density = 0.68
	clouds.Parent = workspace.Terrain

	return {
		root = root,
		slots = slots,
	}
end

return WorldBuilder
