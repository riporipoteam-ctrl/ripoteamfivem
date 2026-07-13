-- Builds the lobby NPCs (little blocky people with Talk prompts),
-- Benny's shop stand and the golden Rebirth shrine.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local NPCDefs = require(Shared.NPCDefs)
local NumberFormat = require(Shared.NumberFormat)

local NPCBuilder = {}

local SKIN = Color3.fromRGB(255, 204, 148)

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
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

-- Small blocky person, ~4 studs tall. Returns the model and its torso.
function NPCBuilder.buildPerson(cf, shirt, pants, hat, parent)
	local model = Instance.new("Model")
	model.Name = "Person"

	part({ Name = "LegL", Size = Vector3.new(0.7, 1.4, 0.7), CFrame = cf * CFrame.new(-0.4, 0.7, 0), Color = pants, Parent = model })
	part({ Name = "LegR", Size = Vector3.new(0.7, 1.4, 0.7), CFrame = cf * CFrame.new(0.4, 0.7, 0), Color = pants, Parent = model })
	local torso = part({ Name = "Torso", Size = Vector3.new(1.7, 1.7, 0.9), CFrame = cf * CFrame.new(0, 2.25, 0), Color = shirt, Parent = model })
	part({ Name = "ArmL", Size = Vector3.new(0.6, 1.5, 0.6), CFrame = cf * CFrame.new(-1.2, 2.3, 0), Color = shirt, Parent = model })
	part({ Name = "ArmR", Size = Vector3.new(0.6, 1.5, 0.6), CFrame = cf * CFrame.new(1.2, 2.3, 0), Color = shirt, Parent = model })
	part({ Name = "Head", Size = Vector3.new(1.1, 1.1, 1.1), CFrame = cf * CFrame.new(0, 3.7, 0), Color = SKIN, Parent = model })
	part({ Name = "Hat", Size = Vector3.new(1.3, 0.45, 1.3), CFrame = cf * CFrame.new(0, 4.4, 0), Color = hat, Parent = model })

	model.PrimaryPart = torso
	model.Parent = parent
	return model, torso
end

local function buildShopStand(root)
	local folder = Instance.new("Folder")
	folder.Name = "ShopStand"
	folder.Parent = root

	local base = Vector3.new(38, Config.GroundY, 14)
	part({ Name = "Counter", Size = Vector3.new(2, 3.4, 12), Position = base + Vector3.new(-3, 1.7, 0), CanCollide = true, Color = Color3.fromRGB(150, 116, 78), Material = Enum.Material.WoodPlanks, Parent = folder })
	part({ Name = "PostL", Size = Vector3.new(0.8, 8, 0.8), Position = base + Vector3.new(1.5, 4, -5.5), Color = Color3.fromRGB(120, 90, 60), Parent = folder })
	part({ Name = "PostR", Size = Vector3.new(0.8, 8, 0.8), Position = base + Vector3.new(1.5, 4, 5.5), Color = Color3.fromRGB(120, 90, 60), Parent = folder })
	-- Striped awning.
	for i = 0, 3 do
		part({
			Name = "Awning",
			Size = Vector3.new(7, 0.4, 3),
			CFrame = CFrame.new(base + Vector3.new(-1, 8.4, -4.5 + i * 3)) * CFrame.Angles(0, 0, math.rad(-12)),
			Color = (i % 2 == 0) and Color3.fromRGB(235, 60, 60) or Color3.fromRGB(240, 240, 245),
			Parent = folder,
		})
	end
end

local function buildRebirthShrine(root, prompts)
	local folder = Instance.new("Folder")
	folder.Name = "RebirthShrine"
	folder.Parent = root

	local base = Vector3.new(0, Config.GroundY, 38)
	local pedestal = part({
		Name = "Pedestal",
		Size = Vector3.new(8, 2, 8),
		Position = base + Vector3.new(0, 1, 0),
		CanCollide = true,
		Color = Color3.fromRGB(255, 215, 80),
		Material = Enum.Material.Metal,
		Parent = folder,
	})
	local orb = part({
		Name = "Orb",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(4.5, 4.5, 4.5),
		Position = base + Vector3.new(0, 5, 0),
		Color = Color3.fromRGB(255, 230, 120),
		Material = Enum.Material.Neon,
		Parent = folder,
	})
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120))
	sparkle.Rate = 6
	sparkle.Lifetime = NumberRange.new(0.8, 1.4)
	sparkle.Speed = NumberRange.new(2, 4)
	sparkle.Parent = orb

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(22, 0, 8, 0)
	gui.StudsOffset = Vector3.new(0, 6, 0)
	gui.MaxDistance = 300
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 230, 120)
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Text = "\u{1F31F} REBIRTH SHRINE \u{1F31F}\nReset your city for a\nPERMANENT income boost!\nFirst rebirth: \u{1F4B5} "
		.. NumberFormat.abbrev(Config.Rebirth.BaseCost)
	label.Parent = gui
	gui.Parent = orb

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RebirthPrompt"
	prompt.ActionText = "Rebirth"
	prompt.ObjectText = "Rebirth Shrine"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = pedestal
	prompts.rebirth = prompt
end

-- Builds everything; returns { prompts = { [npcId] = prompt, rebirth = prompt } }.
function NPCBuilder.build(root)
	local prompts = {}

	buildShopStand(root)
	buildRebirthShrine(root, prompts)

	local folder = Instance.new("Folder")
	folder.Name = "NPCs"
	folder.Parent = root

	for _, def in ipairs(NPCDefs.List) do
		local cf = CFrame.new(Vector3.new(def.pos.X, Config.GroundY, def.pos.Z))
			* CFrame.Angles(0, math.rad(def.facing or 0), 0)
		local model, torso = NPCBuilder.buildPerson(cf, def.shirt, def.pants, def.hat, folder)
		model.Name = "NPC_" .. def.id

		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.new(14, 0, 3.4, 0)
		gui.StudsOffset = Vector3.new(0, 3.6, 0)
		gui.MaxDistance = 120
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.TextStrokeTransparency = 0
		label.Text = def.emoji .. " " .. def.name
		label.Parent = gui
		gui.Parent = torso

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TalkPrompt_" .. def.id
		prompt.ActionText = "Talk"
		prompt.ObjectText = def.name
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = torso
		prompts[def.id] = prompt
	end

	return { prompts = prompts }
end

return NPCBuilder
