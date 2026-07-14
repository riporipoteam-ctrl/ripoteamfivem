-- All combat visuals: rocket/nuke flights along an arc, explosions,
-- the full nuke sequence (flash, fireball, mushroom cloud, shockwave),
-- shield domes and camera shake. Purely cosmetic — damage is server-side.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Layout = require(Shared.Layout)
local Remotes = require(Shared.Remotes)
local SoundBook = require(Shared.SoundBook)

local FX = {}

local player = Players.LocalPlayer
local rng = Random.new()

local function anchoredPart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "Parent" then
			p[k] = v
		end
	end
	p.Parent = props.Parent or workspace
	return p
end

local function shake(magnitude, duration)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	task.spawn(function()
		local elapsed = 0
		while elapsed < duration do
			local dt = task.wait()
			elapsed += dt
			local decay = 1 - elapsed / duration
			humanoid.CameraOffset = Vector3.new(
				rng:NextNumber(-1, 1),
				rng:NextNumber(-1, 1),
				rng:NextNumber(-1, 1)
			) * magnitude * decay
		end
		humanoid.CameraOffset = Vector3.new(0, 0, 0)
	end)
end

local function shakeFromDistance(pos, basePower, maxRange, duration)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local dist = (hrp.Position - pos).Magnitude
	if dist > maxRange then
		return
	end
	shake(basePower * (1 - dist / maxRange), duration)
end

local function debris(pos, count, power, color)
	for _ = 1, count do
		local piece = Instance.new("Part")
		piece.Size = Vector3.new(rng:NextNumber(1, 2.5), rng:NextNumber(1, 2.5), rng:NextNumber(1, 2.5))
		piece.Position = pos + Vector3.new(rng:NextNumber(-3, 3), 3, rng:NextNumber(-3, 3))
		piece.Color = color
		piece.CanCollide = false
		piece.CanQuery = false
		piece.AssemblyLinearVelocity = Vector3.new(
			rng:NextNumber(-power, power),
			rng:NextNumber(power * 0.6, power * 1.4),
			rng:NextNumber(-power, power)
		)
		piece.Parent = workspace
		task.delay(2.5, function()
			piece:Destroy()
		end)
	end
end

local function fadeOut(part, duration)
	local tween = TweenService:Create(part, TweenInfo.new(duration), { Transparency = 1 })
	tween:Play()
	tween.Completed:Once(function()
		part:Destroy()
	end)
end

local function explosionFX(pos)
	-- Layered boom: crunch + deep thump reads much bigger than one sample.
	SoundBook.playAt("Explosion", pos, { PlaybackSpeed = rng:NextNumber(0.55, 0.75), RollOffMaxDistance = 600 })
	SoundBook.playAt("BigRumble", pos, { PlaybackSpeed = 0.45, Volume = 0.7, RollOffMaxDistance = 600 })
	SoundBook.playAt("Glass", pos, { PlaybackSpeed = rng:NextNumber(0.8, 1), Volume = 0.35, RollOffMaxDistance = 400 })

	local boom = Instance.new("Explosion")
	boom.Position = pos
	boom.BlastPressure = 0
	boom.BlastRadius = 0
	boom.DestroyJointRadiusPercent = 0
	boom.Parent = workspace

	local flash = anchoredPart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(6, 6, 6),
		Position = pos + Vector3.new(0, 4, 0),
		Color = Color3.fromRGB(255, 190, 60),
		Material = Enum.Material.Neon,
		Transparency = 0.1,
	})
	TweenService:Create(flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(60, 60, 60),
	}):Play()
	fadeOut(flash, 0.5)

	debris(pos, 8, 40, Color3.fromRGB(80, 75, 70))
	shakeFromDistance(pos, 1.6, 300, 0.6)
end

local function nukeFX(pos)
	-- Blinding flash overlay.
	local gui = Instance.new("ScreenGui")
	gui.Name = "MVC_NukeFlash"
	gui.DisplayOrder = 100
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")
	local white = Instance.new("Frame")
	white.Size = UDim2.fromScale(1, 1)
	white.BackgroundColor3 = Color3.new(1, 1, 1)
	white.BorderSizePixel = 0
	white.Parent = gui
	local flashTween = TweenService:Create(white, TweenInfo.new(2.2, Enum.EasingStyle.Quad), {
		BackgroundTransparency = 1,
	})
	flashTween:Play()
	flashTween.Completed:Once(function()
		gui:Destroy()
	end)

	SoundBook.playAt("Nuke", pos, { RollOffMaxDistance = 3000 })
	SoundBook.playAt("BigRumble", pos, { PlaybackSpeed = 0.35, Volume = 0.8, RollOffMaxDistance = 3000 })
	SoundBook.playAt("Flash", pos, { RollOffMaxDistance = 3000 })

	-- Fireball.
	local fireball = anchoredPart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(10, 10, 10),
		Position = pos + Vector3.new(0, 10, 0),
		Color = Color3.fromRGB(255, 160, 40),
		Material = Enum.Material.Neon,
	})
	TweenService:Create(fireball, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(130, 130, 130),
		Position = pos + Vector3.new(0, 45, 0),
	}):Play()
	fadeOut(fireball, 2.4)

	-- Shockwave ring (flattened, expanding cylinder).
	local ring = anchoredPart({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 8, 8),
		CFrame = CFrame.new(pos + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 240, 200),
		Material = Enum.Material.Neon,
		Transparency = 0.2,
	})
	TweenService:Create(ring, TweenInfo.new(2.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.6, 560, 560),
	}):Play()
	fadeOut(ring, 2.2)

	-- Mushroom cloud: stem grows, cap rises.
	local stem = anchoredPart({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6, 22, 22),
		CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(140, 120, 110),
		Material = Enum.Material.Smoke,
		Transparency = 0.15,
	})
	TweenService:Create(stem, TweenInfo.new(3.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(110, 30, 30),
		CFrame = CFrame.new(pos + Vector3.new(0, 55, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	}):Play()

	local cap = anchoredPart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(26, 20, 26),
		Position = pos + Vector3.new(0, 30, 0),
		Color = Color3.fromRGB(160, 140, 125),
		Material = Enum.Material.Smoke,
		Transparency = 0.1,
	})
	TweenService:Create(cap, TweenInfo.new(3.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(120, 70, 120),
		Position = pos + Vector3.new(0, 118, 0),
	}):Play()

	task.delay(5.5, function()
		fadeOut(stem, 3)
		fadeOut(cap, 3)
	end)

	debris(pos, 16, 90, Color3.fromRGB(70, 65, 60))
	shakeFromDistance(pos, 3.2, 2000, 2.2)
end

local function quadBezier(p0, p1, p2, t)
	local a = p0:Lerp(p1, t)
	local b = p1:Lerp(p2, t)
	return a:Lerp(b, t)
end

local function buildRocketModel(isNuke)
	local model = Instance.new("Model")
	local body = anchoredPart({
		Name = "Body",
		Size = isNuke and Vector3.new(6, 6, 18) or Vector3.new(3, 3, 9),
		Color = isNuke and Color3.fromRGB(60, 62, 68) or Color3.fromRGB(240, 240, 245),
		Parent = model,
	})
	local nose = anchoredPart({
		Name = "Nose",
		Size = isNuke and Vector3.new(4, 4, 5) or Vector3.new(2, 2, 3),
		Color = isNuke and Color3.fromRGB(180, 235, 60) or Color3.fromRGB(230, 60, 60),
		Material = isNuke and Enum.Material.Neon or Enum.Material.SmoothPlastic,
		Parent = model,
	})
	local att = Instance.new("Attachment")
	att.Parent = body
	local fire = Instance.new("ParticleEmitter")
	fire.Texture = "rbxasset://textures/particles/smoke_main.dds"
	fire.Color = ColorSequence.new(Color3.fromRGB(255, 170, 60), Color3.fromRGB(120, 120, 120))
	fire.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, isNuke and 6 or 3),
		NumberSequenceKeypoint.new(1, isNuke and 12 or 6),
	})
	fire.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	fire.Lifetime = NumberRange.new(0.6, 1.1)
	fire.Rate = 40
	fire.Speed = NumberRange.new(4, 8)
	fire.Parent = att
	model.PrimaryPart = body
	return model, body, nose
end

local function launchPadSmoke(pos)
	local holder = anchoredPart({
		Size = Vector3.new(2, 1, 2),
		Position = pos + Vector3.new(0, 1, 0),
		Transparency = 1,
	})
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(230, 230, 230), Color3.fromRGB(150, 150, 150))
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 4),
		NumberSequenceKeypoint.new(1, 10),
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	smoke.Lifetime = NumberRange.new(0.8, 1.6)
	smoke.Rate = 60
	smoke.Speed = NumberRange.new(8, 16)
	smoke.SpreadAngle = Vector2.new(80, 80)
	smoke.Parent = holder
	task.delay(2, function()
		smoke.Enabled = false
	end)
	task.delay(4, function()
		holder:Destroy()
	end)
end

local function flyMissile(payload)
	local isNuke = payload.kind == "nuke"
	local isMeteor = payload.kind == "meteor"
	local from = payload.from
	local to = payload.to
	local flight = payload.flight

	local model, body, nose = buildRocketModel(isNuke)
	model.Name = "MVC_Missile"
	model.Parent = workspace

	-- LIFT OFF: vertical rise off the pad, then arc over to the target city.
	local riseTime = isMeteor and 0 or (isNuke and 2.4 or 1.6)
	local riseHeight = isNuke and 110 or 70
	local liftTop = from + Vector3.new(0, riseHeight, 0)
	local apex = (liftTop + to) / 2 + Vector3.new(0, isNuke and 340 or 190, 0)

	if not isMeteor then
		SoundBook.playAt("Launch", from, { PlaybackSpeed = isNuke and 0.75 or 1, RollOffMaxDistance = 1500 })
		launchPadSmoke(from)
		shakeFromDistance(from, 1.2, 220, riseTime)
	end

	local start = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - start
		local pos, ahead
		if elapsed < riseTime then
			-- Accelerating vertical climb.
			local tt = elapsed / riseTime
			local eased = tt * tt
			pos = from:Lerp(liftTop, eased)
			ahead = pos + Vector3.new(0, 5, 0)
		else
			local t = math.min((elapsed - riseTime) / math.max(flight - riseTime, 0.1), 1)
			pos = quadBezier(liftTop, apex, to, t)
			ahead = quadBezier(liftTop, apex, to, math.min(t + 0.02, 1))
			if t >= 1 then
				conn:Disconnect()
				model:Destroy()
				if isNuke then
					nukeFX(to)
				else
					explosionFX(to)
				end
				return
			end
		end
		local lookCF
		if (ahead - pos).Magnitude > 0.01 then
			lookCF = CFrame.lookAt(pos, ahead)
		else
			lookCF = CFrame.new(pos)
		end
		body.CFrame = lookCF
		nose.CFrame = lookCF * CFrame.new(0, 0, -(body.Size.Z / 2 + nose.Size.Z / 2 - 0.4))
	end)
end

local function shieldFX(plotIndex, _pos)
	local center = Layout.plotCenter(plotIndex)
	local dome = anchoredPart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(20, 20, 20),
		Position = Vector3.new(center.X, Layout.GroundY, center.Z),
		Color = Color3.fromRGB(90, 180, 255),
		Material = Enum.Material.ForceField,
		Transparency = 0.2,
	})
	SoundBook.playAt("Glass", Vector3.new(center.X, Layout.GroundY + 20, center.Z), { RollOffMaxDistance = 900 })
	TweenService:Create(dome, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = Vector3.new(300, 300, 300),
	}):Play()
	task.delay(1.6, function()
		fadeOut(dome, 0.8)
	end)
end

function FX.init()
	Remotes.Events.MissileEvent.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		if typeof(payload.from) == "Vector3" and typeof(payload.to) == "Vector3" and type(payload.flight) == "number" then
			flyMissile(payload)
		end
	end)
	Remotes.Events.ShieldFX.OnClientEvent:Connect(function(plotIndex, pos)
		if type(plotIndex) == "number" then
			shieldFX(plotIndex, pos)
		end
	end)
end

return FX
