-- Renders a zone's building cluster for its level, plus the rubble state.
-- Everything is deterministic per (plot, zone) so cities look stable.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local BuildingVisuals = {}

local SUB_OFFSETS = {
	Vector3.new(-10, 0, -10),
	Vector3.new(10, 0, 10),
	Vector3.new(10, 0, -10),
	Vector3.new(-10, 0, 10),
}

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

local function lighten(color, amt)
	return Color3.new(
		math.min(color.R + amt, 1),
		math.min(color.G + amt, 1),
		math.min(color.B + amt, 1)
	)
end

local function renderTowers(model, def, level, center, rng)
	local count = math.clamp(1 + math.floor(level / 15), 1, 4)
	for i = 1, count do
		local off = SUB_OFFSETS[i]
		local h = 8 + math.min(level, Config.BuildingMaxLevel) * 0.45 * (0.8 + rng:NextNumber() * 0.4)
		local base = Vector3.new(center.X + off.X, Config.GroundY, center.Z + off.Z)
		part({
			Name = "Tower",
			Size = Vector3.new(16, h, 16),
			Position = base + Vector3.new(0, h / 2, 0),
			Color = def.color,
			Parent = model,
		})
		part({
			Name = "Trim",
			Size = Vector3.new(16.6, 1, 16.6),
			Position = base + Vector3.new(0, h + 0.5, 0),
			Color = lighten(def.color, 0.25),
			Material = level >= 30 and Enum.Material.Neon or Enum.Material.SmoothPlastic,
			Parent = model,
		})
		part({
			Name = "Door",
			Size = Vector3.new(4, 5, 0.5),
			Position = base + Vector3.new(0, 2.5, 8.1),
			Color = Color3.fromRGB(60, 50, 45),
			Parent = model,
		})
	end
end

local function renderPanels(model, def, level, center, rng)
	local rows = math.clamp(2 + math.floor(level / 10), 2, 6)
	for i = 1, rows do
		local rowIdx = math.ceil(i / 2)
		local side = (i % 2 == 0) and 1 or -1
		local pos = Vector3.new(center.X + side * 9, Config.GroundY + 2.2, center.Z - 14 + rowIdx * 8)
		part({
			Name = "Panel",
			Size = Vector3.new(14, 0.6, 7),
			CFrame = CFrame.new(pos) * CFrame.Angles(math.rad(-18), 0, 0),
			Color = def.color,
			Material = Enum.Material.Glass,
			Reflectance = 0.2,
			Parent = model,
		})
		part({
			Name = "PanelLeg",
			Size = Vector3.new(1, 2.4, 1),
			Position = Vector3.new(pos.X, Config.GroundY + 1.2, pos.Z),
			Color = Color3.fromRGB(120, 120, 128),
			Parent = model,
		})
	end
	local _ = rng
end

local function renderTurbines(model, def, level, center, rng)
	local count = math.clamp(1 + math.floor(level / 12), 1, 4)
	for i = 1, count do
		local off = SUB_OFFSETS[i]
		local h = 18 + math.min(level, 60) * 0.2 + rng:NextNumber() * 2
		local base = Vector3.new(center.X + off.X, Config.GroundY, center.Z + off.Z)
		part({
			Name = "TurbinePole",
			Size = Vector3.new(1.6, h, 1.6),
			Position = base + Vector3.new(0, h / 2, 0),
			Color = Color3.fromRGB(240, 240, 245),
			Parent = model,
		})
		local hub = base + Vector3.new(0, h, 1.2)
		part({
			Name = "TurbineHub",
			Size = Vector3.new(2.4, 2.4, 2.4),
			Position = hub,
			Color = def.color,
			Parent = model,
		})
		for b = 0, 2 do
			local ang = math.rad(b * 120)
			part({
				Name = "Blade",
				Size = Vector3.new(0.8, 9, 0.4),
				CFrame = CFrame.new(hub) * CFrame.Angles(0, 0, ang) * CFrame.new(0, 5.5, 0),
				Color = Color3.fromRGB(240, 240, 245),
				Parent = model,
			})
		end
	end
end

local function renderRubble(model, def, center, rng)
	for i = 1, 5 do
		local off = Vector3.new((rng:NextNumber() - 0.5) * 26, 0, (rng:NextNumber() - 0.5) * 26)
		local size = Vector3.new(6 + rng:NextNumber() * 8, 2 + rng:NextNumber() * 3, 6 + rng:NextNumber() * 8)
		part({
			Name = "Rubble",
			Size = size,
			CFrame = CFrame.new(center + off + Vector3.new(0, size.Y / 2, 0))
				* CFrame.Angles(0, rng:NextNumber() * math.pi, math.rad((rng:NextNumber() - 0.5) * 20)),
			Color = Color3.fromRGB(52, 50, 48),
			Material = Enum.Material.Slate,
			Parent = model,
		})
	end
	local smokePart = part({
		Name = "SmokeSource",
		Size = Vector3.new(4, 1, 4),
		Position = center + Vector3.new(0, 2, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = model,
	})
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(70, 70, 70), Color3.fromRGB(120, 120, 120))
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 3),
		NumberSequenceKeypoint.new(1, 8),
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	smoke.Lifetime = NumberRange.new(1.2, 2.2)
	smoke.Rate = 8
	smoke.Speed = NumberRange.new(3, 6)
	smoke.SpreadAngle = Vector2.new(18, 18)
	smoke.Parent = smokePart
	local fire = Instance.new("Fire")
	fire.Size = 8
	fire.Heat = 10
	fire.Parent = smokePart
	local _ = def
end

-- container: the Model for this zone. level 0 clears it.
function BuildingVisuals.render(container, def, level, plotIndex, zoneIndex, center, destroyed)
	container:ClearAllChildren()
	local rng = Random.new(plotIndex * 1000 + zoneIndex * 17)
	if destroyed then
		renderRubble(container, def, Vector3.new(center.X, Config.GroundY, center.Z), rng)
	elseif level > 0 then
		local ground = Vector3.new(center.X, Config.GroundY, center.Z)
		if def.style == "panels" then
			renderPanels(container, def, level, ground, rng)
		elseif def.style == "turbines" then
			renderTurbines(container, def, level, ground, rng)
		else
			renderTowers(container, def, level, ground, rng)
		end
	end
end

return BuildingVisuals
