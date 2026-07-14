-- Places the four NPCs on EVERY island's town square using real Roblox
-- avatar rigs (loaded once per NPC from actual Roblox accounts, then cloned),
-- with idle animations. Falls back to a blocky figure if avatar loading
-- fails (e.g. offline Studio).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NPCDefs = require(Shared.NPCDefs)

local NPCBuilder = {}

-- Classic Roblox accounts whose avatars dress our NPCs.
local NPC_AVATARS = {
	shopkeeper = 156, -- builderman
	tailor = 3, -- Jane Doe
	mayor = 261, -- Shedletsky
	general = 2, -- John Doe
}

local IDLE_ANIM = "rbxassetid://507766388" -- Roblox default R15 idle

local SKIN = Color3.fromRGB(255, 204, 148)

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
	local userId = NPC_AVATARS[def.id]
	if userId then
		local ok, model = pcall(function()
			return Players:CreateHumanoidModelFromUserId(userId)
		end)
		if ok and model then
			return model, true
		end
	end
	return blockyFallback(def), false
end

local function anchorRig(model)
	for _, piece in ipairs(model:GetDescendants()) do
		if piece:IsA("BasePart") then
			piece.Anchored = true
			piece.CanCollide = false
		end
	end
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
				anchorRig(model)

				-- Stand on the plaza facing the spawn area.
				local lookAt = Vector3.new(slot.npcLookAt.X, anchor.Y, slot.npcLookAt.Z)
				local pos = anchor + Vector3.new(0, 3.2, 0)
				model.Parent = folder
				model:PivotTo(CFrame.lookAt(pos, Vector3.new(lookAt.X, pos.Y, lookAt.Z)))

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
