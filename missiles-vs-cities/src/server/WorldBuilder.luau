-- Builds the whole map from parts at server start: lobby, 5 plot islands,
-- roads, buy pads, rocket silos, bridges and Nuke Island.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Layout = require(Shared.Layout)
local BuildingDefs = require(Shared.BuildingDefs)
local NumberFormat = require(Shared.NumberFormat)

local WorldBuilder = {}

local COLOR_GRASS = Color3.fromRGB(106, 200, 86)
local COLOR_SAND = Color3.fromRGB(233, 208, 148)
local COLOR_ROAD = Color3.fromRGB(58, 58, 64)
local COLOR_DASH = Color3.fromRGB(248, 214, 62)
local COLOR_ZONE = Color3.fromRGB(126, 212, 102)
local COLOR_FENCE = Color3.fromRGB(196, 164, 108)

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
		Size = Vector3.new(2, 7, 2),
		Position = pos + Vector3.new(0, 3.5, 0),
		Color = Color3.fromRGB(126, 90, 54),
		Parent = parent,
	})
	part({
		Name = "Leaves",
		Size = Vector3.new(6, 5, 6),
		Position = pos + Vector3.new(0, 9, 0),
		Color = Color3.fromRGB(70, 170, 70),
		Parent = parent,
	})
end

local function buildLobby(root)
	local folder = Instance.new("Folder")
	folder.Name = "Lobby"
	folder.Parent = root

	part({
		Name = "LobbyBase",
		Size = Vector3.new(110, 8, 110),
		Position = Vector3.new(0, 0, 0),
		Color = COLOR_GRASS,
		Material = Enum.Material.Grass,
		Parent = folder,
	})
	part({
		Name = "LobbyRim",
		Size = Vector3.new(122, 7, 122),
		Position = Vector3.new(0, -1, 0),
		Color = COLOR_SAND,
		Material = Enum.Material.Sand,
		Parent = folder,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.Position = Vector3.new(0, Config.GroundY + 0.5, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Color = Color3.fromRGB(90, 160, 240)
	spawn.Parent = folder

	buildTree(Vector3.new(-40, Config.GroundY, -40), folder)
	buildTree(Vector3.new(42, Config.GroundY, -38), folder)
	buildTree(Vector3.new(-38, Config.GroundY, 42), folder)
	buildTree(Vector3.new(40, Config.GroundY, 40), folder)

	local signPost = part({
		Name = "WelcomeSign",
		Size = Vector3.new(18, 6, 1),
		Position = Vector3.new(0, Config.GroundY + 6, -20),
		Color = Color3.fromRGB(235, 60, 60),
		Parent = folder,
	})
	local _, label = billboard(signPost, 22, 8, 4, 400)
	label.Text = "\u{1F680} MISSILES VS CITIES \u{1F680}\nCross a bridge to find your city!"
end

local function buildBridge(fromPos, toPos, width, parent)
	local flatFrom = Vector3.new(fromPos.X, 0, fromPos.Z)
	local flatTo = Vector3.new(toPos.X, 0, toPos.Z)
	local length = (flatTo - flatFrom).Magnitude
	local mid = (flatFrom + flatTo) / 2
	local cf = CFrame.lookAt(Vector3.new(mid.X, Config.GroundY - 0.5, mid.Z), Vector3.new(flatTo.X, Config.GroundY - 0.5, flatTo.Z))
	part({
		Name = "Bridge",
		Size = Vector3.new(width, 1, length),
		CFrame = cf,
		Color = Color3.fromRGB(150, 116, 78),
		Material = Enum.Material.WoodPlanks,
		Parent = parent,
	})
end

local function buildRoads(center, folder)
	-- Vertical roads (full depth) then horizontal roads; tiny Y offsets stop z-fighting.
	local vXs = { -104, -52, 0, 52, 104 }
	for _, x in ipairs(vXs) do
		part({
			Name = "RoadV",
			Size = Vector3.new(12, 0.2, Config.PlotSize),
			Position = Vector3.new(center.X + x, Config.GroundY + 0.1, center.Z),
			Color = COLOR_ROAD,
			Parent = folder,
		})
	end
	local hZs = { 130, 78, 26, -26, -78 }
	local dashLimit = Config.PlotSize / 2 - 16
	for _, z in ipairs(hZs) do
		part({
			Name = "RoadH",
			Size = Vector3.new(Config.PlotSize, 0.2, 12),
			Position = Vector3.new(center.X, Config.GroundY + 0.14, center.Z + z),
			Color = COLOR_ROAD,
			Parent = folder,
		})
		-- Yellow dashes along horizontal roads.
		local x = -dashLimit
		while x <= dashLimit do
			part({
				Name = "Dash",
				Size = Vector3.new(6, 0.05, 1.6),
				Position = Vector3.new(center.X + x, Config.GroundY + 0.26, center.Z + z),
				Color = COLOR_DASH,
				Parent = folder,
			})
			x += 24
		end
	end
end

local function buildFence(center, folder)
	local h = 3
	local half = Config.PlotSize / 2
	local gate = 20 -- half-width of the front gate opening
	local segLen = half - gate
	local segOff = gate + segLen / 2
	local segs = {
		-- back wall
		{ Vector3.new(center.X, Config.GroundY + h / 2, center.Z - half), Vector3.new(Config.PlotSize, h, 1) },
		-- side walls
		{ Vector3.new(center.X - half, Config.GroundY + h / 2, center.Z), Vector3.new(1, h, Config.PlotSize) },
		{ Vector3.new(center.X + half, Config.GroundY + h / 2, center.Z), Vector3.new(1, h, Config.PlotSize) },
		-- front wall, split to leave a gate for the bridge
		{ Vector3.new(center.X - segOff, Config.GroundY + h / 2, center.Z + half), Vector3.new(segLen, h, 1) },
		{ Vector3.new(center.X + segOff, Config.GroundY + h / 2, center.Z + half), Vector3.new(segLen, h, 1) },
	}
	for _, seg in ipairs(segs) do
		part({
			Name = "Fence",
			Size = seg[2],
			Position = seg[1],
			Color = COLOR_FENCE,
			Material = Enum.Material.Wood,
			Parent = folder,
		})
	end
end

local function buildSilo(plotIndex, folder)
	local pos = Layout.siloPos(plotIndex)

	-- Hazard-striped launch pad.
	part({
		Name = "SiloPad",
		Size = Vector3.new(36, 0.4, 36),
		Position = pos + Vector3.new(0, 0.2, 0),
		Color = Color3.fromRGB(240, 200, 40),
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

	-- Scaffold tower.
	for _, corner in ipairs({ Vector3.new(-8, 0, -8), Vector3.new(8, 0, -8), Vector3.new(-8, 0, 8), Vector3.new(8, 0, 8) }) do
		part({
			Name = "SiloColumn",
			Size = Vector3.new(2, 26, 2),
			Position = pos + corner + Vector3.new(0, 13, 0),
			Color = Color3.fromRGB(160, 160, 168),
			Material = Enum.Material.Metal,
			Parent = folder,
		})
	end
	part({
		Name = "SiloTop",
		Size = Vector3.new(20, 2, 20),
		Position = pos + Vector3.new(0, 27, 0),
		Color = Color3.fromRGB(120, 120, 128),
		Material = Enum.Material.Metal,
		Parent = folder,
	})

	-- The rocket itself (blocky, like everything else here).
	local body = part({
		Name = "SiloRocket",
		Size = Vector3.new(5, 16, 5),
		Position = pos + Vector3.new(0, 9, 0),
		Color = Color3.fromRGB(240, 240, 245),
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

	return body
end

local function buildPlot(plotIndex, root)
	local center = Layout.plotCenter(plotIndex)
	local folder = Instance.new("Folder")
	folder.Name = "Plot" .. plotIndex
	folder.Parent = root

	part({
		Name = "Island",
		Size = Vector3.new(Config.PlotSize, 10, Config.PlotSize),
		Position = Vector3.new(center.X, -1, center.Z),
		Color = COLOR_GRASS,
		Material = Enum.Material.Grass,
		Parent = folder,
	})
	part({
		Name = "IslandRim",
		Size = Vector3.new(Config.PlotSize + 18, 8, Config.PlotSize + 18),
		Position = Vector3.new(center.X, -1.5, center.Z),
		Color = COLOR_SAND,
		Material = Enum.Material.Sand,
		Parent = folder,
	})

	buildRoads(center, folder)
	buildFence(center, folder)

	-- Owner banner on a pole at the front gate.
	local pole = part({
		Name = "BannerPole",
		Size = Vector3.new(1, 12, 1),
		Position = Vector3.new(center.X - 12, Config.GroundY + 6, center.Z + Config.PlotSize / 2 - 4),
		Color = Color3.fromRGB(120, 120, 128),
		Parent = folder,
	})
	local bannerGui, bannerLabel = billboard(pole, 26, 8, 8, 800)
	bannerGui.AlwaysOnTop = true
	bannerLabel.Text = "\u{1F3DD}\u{FE0F} Empty Plot"
	bannerLabel.TextColor3 = Color3.fromRGB(255, 235, 235)

	local zoneData = {}
	for zi = 1, #BuildingDefs.List do
		local zCenter = Layout.zoneCenter(plotIndex, zi)
		local plate = part({
			Name = "ZonePlate",
			Size = Vector3.new(Config.ZoneSize, 0.3, Config.ZoneSize),
			Position = Vector3.new(zCenter.X, Config.GroundY + 0.15, zCenter.Z),
			Color = COLOR_ZONE,
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

	local siloBody = buildSilo(plotIndex, folder)
	buildBridge(Vector3.new(0, 0, 0), center, 10, folder)

	return {
		index = plotIndex,
		folder = folder,
		zoneData = zoneData,
		bannerLabel = bannerLabel,
		siloBody = siloBody,
	}
end

local function buildNukeIsland(root)
	local folder = Instance.new("Folder")
	folder.Name = "NukeIsland"
	folder.Parent = root

	local c = Layout.NukeIslandCenter
	local size = Layout.NukeIslandSize

	part({
		Name = "NukeBase",
		Size = Vector3.new(size, 10, size),
		Position = Vector3.new(c.X, -1, c.Z),
		Color = Color3.fromRGB(96, 96, 104),
		Material = Enum.Material.Concrete,
		Parent = folder,
	})
	part({
		Name = "NukeRim",
		Size = Vector3.new(size + 14, 8, size + 14),
		Position = Vector3.new(c.X, -1.5, c.Z),
		Color = Color3.fromRGB(240, 200, 40),
		Parent = folder,
	})

	-- Big scary silo.
	for _, corner in ipairs({ Vector3.new(-12, 0, -12), Vector3.new(12, 0, -12), Vector3.new(-12, 0, 12), Vector3.new(12, 0, 12) }) do
		part({
			Name = "NukeColumn",
			Size = Vector3.new(3, 40, 3),
			Position = Vector3.new(c.X, Config.GroundY + 20, c.Z) + corner,
			Color = Color3.fromRGB(70, 70, 78),
			Material = Enum.Material.DiamondPlate,
			Parent = folder,
		})
	end
	local nukeBody = part({
		Name = "NukeRocket",
		Size = Vector3.new(8, 26, 8),
		Position = Vector3.new(c.X, Config.GroundY + 13, c.Z),
		Color = Color3.fromRGB(60, 62, 68),
		Material = Enum.Material.Metal,
		Parent = folder,
	})
	part({
		Name = "NukeNose",
		Size = Vector3.new(5, 6, 5),
		Position = Vector3.new(c.X, Config.GroundY + 29, c.Z),
		Color = Color3.fromRGB(180, 235, 60),
		Material = Enum.Material.Neon,
		Parent = folder,
	})
	local _, siloLabel = billboard(nukeBody, 30, 10, 26, 1200)
	siloLabel.Text = "\u{2622}\u{FE0F} NUKE ISLAND \u{2622}\u{FE0F}"
	siloLabel.TextColor3 = Color3.fromRGB(190, 255, 90)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "NukePrompt"
	prompt.ActionText = "Nuke Controls"
	prompt.ObjectText = "Nuclear Silo"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 20
	prompt.RequiresLineOfSight = false
	prompt.Parent = nukeBody

	-- Purchase pad at the island entrance.
	local padPos = Vector3.new(c.X, Config.GroundY + 0.4, c.Z + size / 2 - 18)
	local pad = part({
		Name = "NukeBuyPad",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 14, 14),
		CFrame = CFrame.new(padPos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(190, 90, 240),
		Material = Enum.Material.Neon,
		Parent = folder,
	})
	local _, padLabel = billboard(pad, 24, 10, 8, 400)
	padLabel.Text = "\u{2622}\u{FE0F} BUY NUKE ACCESS\n\u{1F4B5} " .. NumberFormat.abbrev(Config.Nuke.IslandCost)
		.. "\nOne nuke every 24h!"

	buildBridge(Vector3.new(0, 0, 0), Vector3.new(c.X, 0, c.Z + size / 2), 12, folder)

	return { pad = pad, body = nukeBody }
end

function WorldBuilder.build()
	local root = Instance.new("Folder")
	root.Name = "GameWorld"
	root.Parent = workspace

	-- Ocean.
	workspace.Terrain:FillBlock(CFrame.new(0, -8, 0), Vector3.new(4096, 10, 4096), Enum.Material.Water)

	buildLobby(root)

	local slots = {}
	for i = 1, Config.PlotCount do
		slots[i] = buildPlot(i, root)
	end

	local nuke = buildNukeIsland(root)

	-- Bright cartoon lighting.
	Lighting.Brightness = 3
	Lighting.ClockTime = 12
	Lighting.Ambient = Color3.fromRGB(140, 140, 140)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 160, 170)
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.25
	atmosphere.Haze = 1
	atmosphere.Parent = Lighting

	-- Volumetric clouds.
	local clouds = Instance.new("Clouds")
	clouds.Cover = 0.48
	clouds.Density = 0.72
	clouds.Parent = workspace.Terrain

	return {
		root = root,
		slots = slots,
		nukePad = nuke.pad,
		nukeBody = nuke.body,
	}
end

return WorldBuilder
