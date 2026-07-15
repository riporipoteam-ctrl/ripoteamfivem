-- Air defense: turret models on the island that give a chance to intercept
-- incoming missiles and jets. More levels = more turrets + higher chance.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Layout = require(Shared.Layout)
local Remotes = require(Shared.Remotes)

local DefenseService = {}

local ctx
local rng = Random.new()

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

local function buildTurret(pos, parent)
	local model = Instance.new("Model")
	model.Name = "Turret"
	part({
		Name = "Base",
		Size = Vector3.new(5, 2, 5),
		Position = pos + Vector3.new(0, 1, 0),
		Color = Color3.fromRGB(70, 80, 70),
		Material = Enum.Material.Metal,
		Parent = model,
	})
	local dome = part({
		Name = "Dome",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(3.5, 3.5, 3.5),
		Position = pos + Vector3.new(0, 3, 0),
		Color = Color3.fromRGB(90, 110, 90),
		Material = Enum.Material.Metal,
		Parent = model,
	})
	-- Twin barrels angled up.
	for _, dx in ipairs({ -0.8, 0.8 }) do
		part({
			Name = "Barrel",
			Size = Vector3.new(0.6, 0.6, 6),
			CFrame = CFrame.new(pos + Vector3.new(dx, 4, 1.5)) * CFrame.Angles(math.rad(-35), 0, 0),
			Color = Color3.fromRGB(40, 45, 40),
			Material = Enum.Material.Metal,
			Parent = model,
		})
	end
	model.PrimaryPart = dome
	model.Parent = parent
	return model
end

-- Turret count grows with defense level (1 turret per 3 levels, up to 4).
local function turretCount(level)
	if level <= 0 then
		return 0
	end
	return math.clamp(1 + math.floor((level - 1) / 3), 1, 4)
end

function DefenseService.updateTurrets(slot, level)
	slot.turrets = slot.turrets or {}
	local want = turretCount(level)
	-- Remove extras.
	for i = #slot.turrets, want + 1, -1 do
		slot.turrets[i]:Destroy()
		slot.turrets[i] = nil
	end
	-- Add missing.
	for i = #slot.turrets + 1, want do
		slot.turrets[i] = buildTurret(Layout.defensePos(slot.index, i), slot.folder)
	end
end

function DefenseService.interceptChance(level, kind)
	if level <= 0 then
		return 0
	end
	local per = (kind == "jet") and Config.Defense.JetChancePerLevel or Config.Defense.MissileChancePerLevel
	return math.min(level * per, Config.Defense.MaxChance)
end

-- Rolls interception; on success plays flak FX above the city.
function DefenseService.tryIntercept(slot, kind, pos)
	if not slot.owner then
		return false
	end
	local profile = ctx.Data.get(slot.owner)
	local level = profile and profile.defenseLevel or 0
	if level <= 0 then
		return false
	end
	if rng:NextNumber() <= DefenseService.interceptChance(level, kind) then
		Remotes.Events.GameEvent:FireAllClients({
			kind = "intercept",
			pos = pos or Layout.plotCenter(slot.index),
		})
		return true
	end
	return false
end

function DefenseService.init(context)
	ctx = context
end

return DefenseService
