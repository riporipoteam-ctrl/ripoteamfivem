-- Renders a zone's buildings for its level. Styles:
--   houses   - little homes with pitched wedge roofs
--   towers   - city blocks with glowing windows + rooftop details
--   panels   - solar/container fields
--   turbines - wind turbines
-- Plus the smoking rubble state. Deterministic per (plot, zone).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local DecorSets = require(Shared.DecorSets)
local StoreModels = require(script.Parent.StoreModels)

local BuildingVisuals = {}

local SUB_OFFSETS = {
	Vector3.new(-10, 0, -10),
	Vector3.new(10, 0, 10),
	Vector3.new(10, 0, -10),
	Vector3.new(-10, 0, 10),
}

local WINDOW_COLOR = Color3.fromRGB(255, 236, 160)

local SMOOTH_MATERIALS = {
	[Enum.Material.Neon] = true,
	[Enum.Material.Glass] = true,
	[Enum.Material.ForceField] = true,
	[Enum.Material.DiamondPlate] = true,
	[Enum.Material.Metal] = true,
}

local function applySurfaces(p, smooth)
	local s = smooth and Enum.SurfaceType.Smooth or Enum.SurfaceType.Studs
	p.TopSurface = s
	p.BottomSurface = s
	p.LeftSurface = s
	p.RightSurface = s
	p.FrontSurface = s
	p.BackSurface = s
end

-- Buildings are classic studded bricks (Plastic + Studs) unless the material
-- should stay smooth (glass windows, neon signs, metal) or props.Smooth is set.
local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	local mat = props.Material or Enum.Material.Plastic
	if mat == Enum.Material.SmoothPlastic then
		mat = Enum.Material.Plastic
	end
	local smooth = props.Smooth or SMOOTH_MATERIALS[mat]
	for k, v in pairs(props) do
		if k ~= "Parent" and k ~= "Smooth" and k ~= "Material" then
			p[k] = v
		end
	end
	p.Material = mat
	applySurfaces(p, smooth)
	p.Parent = props.Parent
	return p
end

local function wedge(props)
	local p = Instance.new("WedgePart")
	p.Anchored = true
	local mat = props.Material or Enum.Material.Plastic
	if mat == Enum.Material.SmoothPlastic then
		mat = Enum.Material.Plastic
	end
	local smooth = props.Smooth or SMOOTH_MATERIALS[mat]
	for k, v in pairs(props) do
		if k ~= "Parent" and k ~= "Smooth" and k ~= "Material" then
			p[k] = v
		end
	end
	p.Material = mat
	applySurfaces(p, smooth)
	p.Parent = props.Parent
	return p
end

local function lighten(color, amt)
	return Color3.new(math.min(color.R + amt, 1), math.min(color.G + amt, 1), math.min(color.B + amt, 1))
end

-- Parts are already studded on every face via part(); this is now a no-op
-- kept so existing call sites keep working.
local function studBrick(p)
	return p
end

local function darken(color, amt)
	return Color3.new(math.max(color.R - amt, 0), math.max(color.G - amt, 0), math.max(color.B - amt, 0))
end

-- Buildings use clean studded Plastic (like the reference) except glass and
-- metal towers, which keep their material for shine.
local KEEP_MATERIAL = { Glass = true, Metal = true }
local function materialOf(def)
	if def.material and KEEP_MATERIAL[def.material] then
		return Enum.Material[def.material]
	end
	return Enum.Material.Plastic
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

		studBrick(part({
			Name = "HouseBody",
			Size = Vector3.new(w, h, w),
			CFrame = cf * CFrame.new(0, h / 2, 0),
			Color = def.color,
			Material = materialOf(def),
			Parent = model,
		}))
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
		for _, wx in ipairs({ -w / 4 - 0.4, w / 4 + 0.6 }) do
			part({
				Name = "Window",
				Size = Vector3.new(2.2, 2, 0.3),
				CFrame = cf * CFrame.new(wx, h - 1.6, w / 2 + 0.12),
				Color = WINDOW_COLOR,
				Material = Enum.Material.Neon,
				Smooth = true,
				Transparency = 0.1,
				Parent = model,
			})
		end
		-- Brick chimney with a little smoke.
		local chim = part({
			Name = "Chimney",
			Size = Vector3.new(1.6, 3.5, 1.6),
			CFrame = cf * CFrame.new(w / 3, h + 2.5, -w / 4),
			Color = darken(def.color, 0.15),
			Parent = model,
		})
		local smoke = Instance.new("ParticleEmitter")
		smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
		smoke.Rate = 3
		smoke.Lifetime = NumberRange.new(1, 2)
		smoke.Size = NumberSequence.new(1.5)
		smoke.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 1),
		})
		smoke.Speed = NumberRange.new(2, 4)
		smoke.Color = ColorSequence.new(Color3.fromRGB(210, 210, 210))
		smoke.Parent = chim
	end
end

-- Adds a grid of glowing window squares up a tower face. Random lit/dark
-- windows give the "real city building" look from the reference.
local function windowGrid(model, base, h, faceCF, faceWidth, rng)
	local floorH = 3.2
	-- Cap floors so tall towers don't spawn thousands of window parts.
	local floors = math.clamp(math.floor((h - 2) / floorH), 1, 8)
	local cols = 2
	local winW = faceWidth / (cols + 1)
	for f = 0, floors - 1 do
		local y = 2 + f * floorH + floorH / 2 - h / 2
		for c = 1, cols do
			local x = -faceWidth / 2 + c * (faceWidth / (cols + 1))
			local lit = rng:NextNumber() > 0.35
			local win = part({
				Name = "Win",
				Size = Vector3.new(winW * 0.7, floorH * 0.6, 0.3),
				CFrame = CFrame.new(base + Vector3.new(0, h / 2, 0)) * faceCF * CFrame.new(x, y, 0),
				Color = lit and WINDOW_COLOR or Color3.fromRGB(70, 90, 120),
				Material = lit and Enum.Material.Neon or Enum.Material.Glass,
				Smooth = true,
				Parent = model,
			})
			win.Transparency = lit and 0.05 or 0.35
		end
	end
end

local function renderTowers(model, def, level, center, rng)
	local count = math.clamp(1 + math.floor(level / 15), 1, 4)
	for i = 1, count do
		local off = SUB_OFFSETS[i]
		local h = math.min(12 + math.min(level, Config.BuildingMaxLevel) * 0.7 * (0.85 + rng:NextNumber() * 0.3), 44)
		local base = Vector3.new(center.X + off.X, Config.GroundY, center.Z + off.Z)
		local w = 15

		studBrick(part({
			Name = "Tower",
			Size = Vector3.new(w, h, w),
			Position = base + Vector3.new(0, h / 2, 0),
			Color = def.color,
			Material = materialOf(def),
			Reflectance = def.material == "Glass" and 0.15 or 0,
			Parent = model,
		}), true)

		-- Window grid on all four faces.
		local faces = {
			CFrame.new(0, 0, w / 2 + 0.16),
			CFrame.new(0, 0, -w / 2 - 0.16) * CFrame.Angles(0, math.pi, 0),
			CFrame.new(w / 2 + 0.16, 0, 0) * CFrame.Angles(0, math.rad(90), 0),
			CFrame.new(-w / 2 - 0.16, 0, 0) * CFrame.Angles(0, math.rad(-90), 0),
		}
		for _, fcf in ipairs(faces) do
			windowGrid(model, base, h, fcf, w, rng)
		end

		-- Colored roof trim (parapet) around the top.
		part({
			Name = "Trim",
			Size = Vector3.new(w + 0.8, 1.2, w + 0.8),
			Position = base + Vector3.new(0, h + 0.6, 0),
			Color = lighten(def.color, 0.25),
			Material = level >= 30 and Enum.Material.Neon or Enum.Material.Plastic,
			Parent = model,
		})
		-- Rooftop details.
		part({
			Name = "RoofBox",
			Size = Vector3.new(4, 2.4, 4),
			Position = base + Vector3.new(3, h + 2.4, 3),
			Color = Color3.fromRGB(120, 120, 128),
			Material = Enum.Material.Metal,
			Parent = model,
		})
		part({
			Name = "WaterTank",
			Size = Vector3.new(3, 3, 3),
			Position = base + Vector3.new(-3.5, h + 2.7, -3),
			Color = Color3.fromRGB(150, 120, 90),
			Parent = model,
		})
		if i == 1 then
			part({
				Name = "Antenna",
				Size = Vector3.new(0.4, 8, 0.4),
				Position = base + Vector3.new(-4, h + 5.5, -4),
				Color = Color3.fromRGB(200, 60, 60),
				Material = Enum.Material.Neon,
				Smooth = true,
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

local function addSmoke(model, center)
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
end

-- Drop a Store-model clone so its feet touch the ground, facing the road.
local function groundSnap(clone, x, z)
	local bbCF, bbSize = clone:GetBoundingBox()
	local pivotY = clone:GetPivot().Position.Y
	local feet = pivotY - (bbCF.Position.Y - bbSize.Y / 2)
	local pos = Vector3.new(x, Config.GroundY + feet, z)
	clone:PivotTo(CFrame.lookAt(pos, Vector3.new(x, pos.Y, z + 60)))
end

-- Render with a real Creator Store model. Returns false to fall back to parts.
local function renderStore(container, def, level, center, rng)
	if not Config.UseStoreBuildings then
		return false
	end
	local set = DecorSets.Buildings[def.id]
	if not set then
		return false
	end
	local entry = StoreModels.get("bld_" .. def.id, set.ids, { size = set.size, byHeight = set.byHeight })
	if not entry then
		return false
	end
	-- Buildings physically grow as they level up.
	local growth = 0.82 + 0.38 * math.min(level, Config.BuildingMaxLevel) / Config.BuildingMaxLevel
	if set.mode == "single" then
		local clone = entry.model:Clone()
		local ok = pcall(function()
			clone:ScaleTo(entry.scale * growth)
		end)
		if not ok then
			clone:Destroy()
			return false
		end
		clone.Parent = container
		groundSnap(clone, center.X, center.Z)
	else
		local count = math.clamp(1 + math.floor(level / 12), 1, 4)
		for i = 1, count do
			local off = SUB_OFFSETS[i]
			local clone = entry.model:Clone()
			pcall(function()
				clone:ScaleTo(entry.scale * growth * (0.9 + rng:NextNumber() * 0.2))
			end)
			clone.Parent = container
			groundSnap(clone, center.X + off.X, center.Z + off.Z)
		end
	end
	return true
end

local function renderStoreRubble(container, center)
	if not Config.UseStoreBuildings then
		return false
	end
	local entry = StoreModels.get("rubble", DecorSets.Rubble, { size = 30 })
	if not entry then
		return false
	end
	local clone = entry.model:Clone()
	clone.Parent = container
	groundSnap(clone, center.X, center.Z)
	addSmoke(container, center)
	return true
end

-- Warm the template cache (called once at startup, off the main thread).
function BuildingVisuals.preload()
	if not Config.UseStoreBuildings then
		return
	end
	for defId, set in pairs(DecorSets.Buildings) do
		StoreModels.get("bld_" .. defId, set.ids, { size = set.size, byHeight = set.byHeight })
	end
	StoreModels.get("rubble", DecorSets.Rubble, { size = 30 })
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
	addSmoke(model, center)
	local _ = def
end

function BuildingVisuals.render(container, def, level, plotIndex, zoneIndex, center, destroyed)
	container:ClearAllChildren()
	local rng = Random.new(plotIndex * 1000 + zoneIndex * 17)
	local ground = Vector3.new(center.X, Config.GroundY, center.Z)
	if destroyed then
		if not renderStoreRubble(container, ground) then
			renderRubble(container, def, ground, rng)
		end
	elseif level > 0 then
		-- Real Creator Store buildings first; part-built visuals as fallback.
		if renderStore(container, def, level, ground, rng) then
			return
		end
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
