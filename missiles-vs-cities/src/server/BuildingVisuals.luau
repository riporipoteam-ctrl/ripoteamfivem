-- Renders a zone's buildings for its level. Styles:
--   houses   - little homes with pitched wedge roofs
--   towers   - city blocks with glowing windows + rooftop details
--   panels   - solar/container fields
--   turbines - wind turbines
-- Plus the smoking rubble state. Deterministic per (plot, zone).

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

local WINDOW_COLOR = Color3.fromRGB(255, 236, 160)

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

local function wedge(props)
	local p = Instance.new("WedgePart")
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
	return Color3.new(math.min(color.R + amt, 1), math.min(color.G + amt, 1), math.min(color.B + amt, 1))
end

local function darken(color, amt)
	return Color3.new(math.max(color.R - amt, 0), math.max(color.G - amt, 0), math.max(color.B - amt, 0))
end

local function materialOf(def)
	return Enum.Material[def.material or "SmoothPlastic"] or Enum.Material.SmoothPlastic
end

-- Little homes with pitched roofs (houses / apartments).
local function renderHouses(model, def, level, center, rng)
	local count = math.clamp(1 + math.floor(level / 12), 1, 4)
	local roofColor = darken(def.color, 0.25)
	for i = 1, count do
		local off = SUB_OFFSETS[i]
		local w = 11 + rng:NextNumber() * 2
		local h = 5 + math.min(level, 60) * 0.12
		local base = Vector3.new(center.X + off.X, Config.GroundY, center.Z + off.Z)
		local yaw = (i % 2 == 0) and math.rad(90) or 0
		local cf = CFrame.new(base) * CFrame.Angles(0, yaw, 0)

		part({
			Name = "HouseBody",
			Size = Vector3.new(w, h, w),
			CFrame = cf * CFrame.new(0, h / 2, 0),
			Color = def.color,
			Material = materialOf(def),
			Parent = model,
		})
		-- Pitched roof from two wedges.
		wedge({
			Name = "RoofA",
			Size = Vector3.new(w + 1, 3, (w + 1) / 2),
			CFrame = cf * CFrame.new(0, h + 1.5, (w + 1) / 4),
			Color = roofColor,
			Material = Enum.Material.Slate,
			Parent = model,
		})
		wedge({
			Name = "RoofB",
			Size = Vector3.new(w + 1, 3, (w + 1) / 2),
			CFrame = cf * CFrame.new(0, h + 1.5, -(w + 1) / 4) * CFrame.Angles(0, math.pi, 0),
			Color = roofColor,
			Material = Enum.Material.Slate,
			Parent = model,
		})
		part({
			Name = "Door",
			Size = Vector3.new(2.4, 3.6, 0.4),
			CFrame = cf * CFrame.new(0, 1.8, w / 2 + 0.15),
			Color = Color3.fromRGB(92, 64, 40),
			Material = Enum.Material.Wood,
			Parent = model,
		})
		part({
			Name = "Window",
			Size = Vector3.new(2.2, 2, 0.3),
			CFrame = cf * CFrame.new(w / 4 + 0.6, h - 1.6, w / 2 + 0.12),
			Color = WINDOW_COLOR,
			Material = Enum.Material.Neon,
			Transparency = 0.15,
			Parent = model,
		})
	end
end

local function renderTowers(model, def, level, center, rng)
	local count = math.clamp(1 + math.floor(level / 15), 1, 4)
	for i = 1, count do
		local off = SUB_OFFSETS[i]
		local h = 9 + math.min(level, Config.BuildingMaxLevel) * 0.5 * (0.8 + rng:NextNumber() * 0.4)
		local base = Vector3.new(center.X + off.X, Config.GroundY, center.Z + off.Z)

		part({
			Name = "Tower",
			Size = Vector3.new(15, h, 15),
			Position = base + Vector3.new(0, h / 2, 0),
			Color = def.color,
			Material = materialOf(def),
			Reflectance = def.material == "Glass" and 0.15 or 0,
			Parent = model,
		})
		-- Glowing window strips on two faces.
		for _, face in ipairs({ CFrame.new(0, 0, 7.7), CFrame.new(7.7, 0, 0) * CFrame.Angles(0, math.rad(90), 0) }) do
			part({
				Name = "Windows",
				Size = Vector3.new(9, math.max(h - 4, 2), 0.3),
				CFrame = CFrame.new(base + Vector3.new(0, h / 2, 0)) * face,
				Color = WINDOW_COLOR,
				Material = Enum.Material.Neon,
				Transparency = 0.35,
				Parent = model,
			})
		end
		-- Roof trim + details.
		part({
			Name = "Trim",
			Size = Vector3.new(15.8, 1, 15.8),
			Position = base + Vector3.new(0, h + 0.5, 0),
			Color = lighten(def.color, 0.22),
			Material = level >= 30 and Enum.Material.Neon or Enum.Material.SmoothPlastic,
			Parent = model,
		})
		if i == 1 then
			part({
				Name = "RoofBox",
				Size = Vector3.new(4, 2.4, 4),
				Position = base + Vector3.new(3, h + 2.2, 3),
				Color = Color3.fromRGB(120, 120, 128),
				Material = Enum.Material.Metal,
				Parent = model,
			})
			part({
				Name = "Antenna",
				Size = Vector3.new(0.4, 7, 0.4),
				Position = base + Vector3.new(-4, h + 4.5, -4),
				Color = Color3.fromRGB(200, 60, 60),
				Material = Enum.Material.Neon,
				Parent = model,
			})
		end
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
			Material = materialOf(def),
			Reflectance = 0.25,
			Parent = model,
		})
		part({
			Name = "PanelLeg",
			Size = Vector3.new(1, 2.4, 1),
			Position = Vector3.new(pos.X, Config.GroundY + 1.2, pos.Z),
			Color = Color3.fromRGB(110, 110, 118),
			Material = Enum.Material.Metal,
			Parent = model,
		})
	end
	-- Control hut with a glowing window.
	part({
		Name = "Hut",
		Size = Vector3.new(7, 5, 7),
		Position = Vector3.new(center.X, Config.GroundY + 2.5, center.Z + 14),
		Color = darken(def.color, 0.15),
		Material = Enum.Material.Metal,
		Parent = model,
	})
	part({
		Name = "HutWindow",
		Size = Vector3.new(3, 1.6, 0.3),
		Position = Vector3.new(center.X, Config.GroundY + 3.4, center.Z + 17.6),
		Color = WINDOW_COLOR,
		Material = Enum.Material.Neon,
		Transparency = 0.2,
		Parent = model,
	})
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
			Material = Enum.Material.SmoothPlastic,
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
			local ang = math.rad(b * 120 + rng:NextNumber() * 40)
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
			Color = (i % 2 == 0) and Color3.fromRGB(52, 50, 48) or Color3.fromRGB(72, 66, 60),
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

function BuildingVisuals.render(container, def, level, plotIndex, zoneIndex, center, destroyed)
	container:ClearAllChildren()
	local rng = Random.new(plotIndex * 1000 + zoneIndex * 17)
	local ground = Vector3.new(center.X, Config.GroundY, center.Z)
	if destroyed then
		renderRubble(container, def, ground, rng)
	elseif level > 0 then
		if def.style == "houses" then
			renderHouses(container, def, level, ground, rng)
		elseif def.style == "panels" then
			renderPanels(container, def, level, ground, rng)
		elseif def.style == "turbines" then
			renderTurbines(container, def, level, ground, rng)
		else
			renderTowers(container, def, level, ground, rng)
		end
	end
end

return BuildingVisuals
