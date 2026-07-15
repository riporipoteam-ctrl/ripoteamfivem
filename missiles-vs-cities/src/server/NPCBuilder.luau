-- Places the four NPCs on EVERY island's town square using real Roblox
-- avatar rigs (loaded once per NPC from actual Roblox accounts, then cloned),
-- with idle animations. Falls back to a blocky figure if avatar loading
-- fails (e.g. offline Studio).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NPCDefs = require(Shared.NPCDefs)
local RigUtil = require(script.Parent.RigUtil)

local NPCBuilder = {}

local IDLE_ANIM = "rbxassetid://507766388" -- Roblox default R15 idle

local SKIN = Color3.fromRGB(255, 204, 148)

-- Custom outfits per NPC role (built from a HumanoidDescription, so NOBODY is
-- "builderman"). Colors come from NPCDefs (shirt/pants/hat).
local ROLE_ACCESSORY = {
	shopkeeper = 121850938, -- classic cap
	tailor = 20573327, -- bow/hair-ish
	mayor = 12898202, -- top hat
	general = 1029025, -- military-ish helmet
}

local function blockyFallback(def)
	local model = Instance.new("Model")
	local function p(name, size, cfOff, color)
		local piece = Instance.new("Part")
		piece.Name = name
		piece.Anchored = true
		piece.CanCollide = false
		piece.TopSurface = Enum.SurfaceType.Smooth
		piece.BottomSurface = Enum.SurfaceType.Smooth
		piece.Size = size
		piece.CFrame = cfOff
		piece.Color = color
		piece.Parent = model
		return piece
	end
	local cf = CFrame.new()
	p("LegL", Vector3.new(0.9, 1.8, 0.9), cf * CFrame.new(-0.5, 0.9, 0), def.pants)
	p("LegR", Vector3.new(0.9, 1.8, 0.9), cf * CFrame.new(0.5, 0.9, 0), def.pants)
	local torso = p("Torso", Vector3.new(2.1, 2.1, 1.1), cf * CFrame.new(0, 2.85, 0), def.shirt)
	p("ArmL", Vector3.new(0.8, 1.9, 0.8), cf * CFrame.new(-1.5, 2.9, 0), def.shirt)
	p("ArmR", Vector3.new(0.8, 1.9, 0.8), cf * CFrame.new(1.5, 2.9, 0), def.shirt)
	p("Head", Vector3.new(1.3, 1.3, 1.3), cf * CFrame.new(0, 4.6, 0), SKIN)
	p("Hat", Vector3.new(1.5, 0.5, 1.5), cf * CFrame.new(0, 5.4, 0), def.hat)
	model.PrimaryPart = torso
	return model
end

local function loadAvatarBase(def)
	-- Build a custom-dressed rig from a HumanoidDescription (never a real
	-- account avatar), colored to match this NPC's role.
	local ok, model = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc.TorsoColor = def.shirt
		desc.LeftArmColor = SKIN
		desc.RightArmColor = SKIN
		desc.LeftLegColor = def.pants
		desc.RightLegColor = def.pants
		desc.HeadColor = SKIN
		local acc = ROLE_ACCESSORY[def.id]
		if acc then
			desc.HatAccessory = tostring(acc)
		end
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if ok and model then
		return model, true
	end
	return blockyFallback(def), false
end

local function decorate(model, def)
	local head = model:FindFirstChild("Head") or model.PrimaryPart
	if not head then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(14, 0, 3.2, 0)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = 140
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
	gui.Parent = head

	local promptHolder = model.PrimaryPart or head
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt_" .. def.id
	prompt.ActionText = "Talk"
	prompt.ObjectText = def.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptHolder
end

local function playIdle(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	pcall(function()
		local anim = Instance.new("Animation")
		anim.AnimationId = IDLE_ANIM
		local track = animator:LoadAnimation(anim)
		track.Looped = true
		track:Play()
	end)
end

function NPCBuilder.build(world)
	local folder = Instance.new("Folder")
	folder.Name = "NPCs"
	folder.Parent = world.root

	-- Load each avatar once, clone per island.
	local bases = {}
	for _, def in ipairs(NPCDefs.List) do
		bases[def.id] = loadAvatarBase(def)
	end

	for _, slot in ipairs(world.slots) do
		for _, def in ipairs(NPCDefs.List) do
			local anchor = slot.npcAnchors[def.id]
			if anchor then
				local model = bases[def.id]:Clone()
				model.Name = "NPC_" .. def.id .. "_" .. slot.index
				model.Parent = folder
				-- Weld everything to the root and anchor only the root so
				-- heads and hats never drift off.
				RigUtil.freeze(model)
				RigUtil.placeOnGround(model, anchor, anchor.Y, slot.npcLookAt)
				decorate(model, def)
				playIdle(model)
			end
		end
	end

	for _, base in pairs(bases) do
		base:Destroy()
	end
end

return NPCBuilder
