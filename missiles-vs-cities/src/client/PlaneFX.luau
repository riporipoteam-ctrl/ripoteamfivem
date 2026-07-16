-- Flight FX for the pilot's cropduster (PlaneEvent) and jet strikes (JetEvent).
-- The pilot uses ONE continuous plane per island that transitions between
-- phases (approach -> circle/hold -> land or takeoff or crash), so there is
-- never a second plane and the landing is a smooth lined-up approach.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local SoundBook = require(Shared.SoundBook)

local PlaneFX = {}

local activePlanes = {} -- [plotIndex] = record

local function anchoredPart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	for k, v in pairs(props) do
		if k ~= "Parent" then
			p[k] = v
		end
	end
	p.Parent = props.Parent or workspace
	return p
end

-- Builds a plane. Prefers a Store model template from ReplicatedStorage.FXModels
-- (loaded by the server); otherwise assembles a blocky plane from properly
-- offset parts (nose points -Z so CFrame.lookAt flies it forward).
local function buildPlane(cropduster)
	local fx = ReplicatedStorage:FindFirstChild("FXModels")
	local template = fx and fx:FindFirstChild(cropduster and "Cropduster" or "Jet")
	if template and template.PrimaryPart then
		local m = template:Clone()
		m.Name = "MVC_Plane"
		return m, nil -- no prop to spin on store models
	end

	local model = Instance.new("Model")
	model.Name = "MVC_Plane"
	local bodyColor = cropduster and Color3.fromRGB(220, 170, 60) or Color3.fromRGB(90, 100, 120)
	local bodyLen = cropduster and 9 or 11
	local body = anchoredPart({
		Name = "Body",
		Size = Vector3.new(2.4, 2, bodyLen),
		CFrame = CFrame.new(0, 0, 0),
		Color = bodyColor,
		Material = Enum.Material.Metal,
		Parent = model,
	})
	anchoredPart({
		Name = "Wing",
		Size = Vector3.new(cropduster and 15 or 12, 0.5, 3),
		CFrame = CFrame.new(0, 0.6, -0.5),
		Color = bodyColor,
		Parent = model,
	})
	anchoredPart({
		Name = "TailWing",
		Size = Vector3.new(5, 0.4, 1.6),
		CFrame = CFrame.new(0, 0.6, bodyLen / 2 - 0.8),
		Color = bodyColor,
		Parent = model,
	})
	anchoredPart({
		Name = "Tail",
		Size = Vector3.new(0.5, 2.2, 1.6),
		CFrame = CFrame.new(0, 1.6, bodyLen / 2 - 0.8),
		Color = bodyColor,
		Parent = model,
	})
	if cropduster then
		anchoredPart({
			Name = "Cockpit",
			Size = Vector3.new(1.6, 1.2, 2),
			CFrame = CFrame.new(0, 1.4, -1),
			Color = Color3.fromRGB(120, 180, 220),
			Material = Enum.Material.Glass,
			Parent = model,
		})
	end
	anchoredPart({
		Name = "Prop",
		Size = Vector3.new(cropduster and 5.5 or 3, 0.4, 0.4),
		CFrame = CFrame.new(0, 0, -(bodyLen / 2 + 0.3)),
		Color = Color3.fromRGB(40, 40, 40),
		Parent = model,
	})
	model.PrimaryPart = body
	return model, model:FindFirstChild("Prop")
end

-- Poses the whole plane model at pos facing 'facing', spinning the prop.
local function poseAt(model, prop, pos, facing, bank)
	local look = facing.Magnitude > 0.01 and CFrame.lookAt(pos, pos + facing) or CFrame.new(pos)
	if bank then
		look = look * CFrame.Angles(0, 0, bank)
	end
	model:PivotTo(look)
	if prop and model.PrimaryPart then
		local bodyLen = model.PrimaryPart.Size.Z
		prop.CFrame = model.PrimaryPart.CFrame
			* CFrame.new(0, 0, -(bodyLen / 2 + 0.3))
			* CFrame.Angles(0, 0, os.clock() * 45)
	end
end

-- Cancels a record's current motion loop (by bumping its token).
local function cancelMotion(rec)
	rec.token = (rec.token or 0) + 1
end

local function destroyPlane(plotIndex)
	local rec = activePlanes[plotIndex]
	if rec then
		cancelMotion(rec)
		if rec.engine then
			rec.engine:Stop()
		end
		if rec.model then
			rec.model:Destroy()
		end
		activePlanes[plotIndex] = nil
	end
end

local function explosion(pos)
	SoundBook.playAt("Explosion", pos, { PlaybackSpeed = 0.7, RollOffMaxDistance = 600 })
	local boom = Instance.new("Explosion")
	boom.Position = pos
	boom.BlastPressure = 0
	boom.BlastRadius = 0
	boom.DestroyJointRadiusPercent = 0
	boom.Parent = workspace
	local flash = anchoredPart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(8, 8, 8),
		Position = pos + Vector3.new(0, 4, 0),
		Color = Color3.fromRGB(255, 180, 60),
		Material = Enum.Material.Neon,
	})
	task.spawn(function()
		for i = 1, 12 do
			flash.Size += Vector3.new(4, 4, 4)
			flash.Transparency = i / 12
			task.wait(0.03)
		end
		flash:Destroy()
	end)
end

-- Flies the plane from its current position to 'to' over 'flight' seconds,
-- along a smooth arc, then runs onDone. Cancellable via token.
local function flyTo(rec, to, flight, arcHeight, onDone)
	cancelMotion(rec)
	local token = rec.token
	task.spawn(function()
		local from = rec.model:GetPivot().Position
		local mid = (from + to) / 2 + Vector3.new(0, arcHeight or 0, 0)
		local t0 = os.clock()
		while rec.token == token and rec.model.Parent do
			local a = math.min((os.clock() - t0) / flight, 1)
			-- Quadratic bezier for a smooth curved path.
			local p1 = from:Lerp(mid, a)
			local p2 = mid:Lerp(to, a)
			local pos = p1:Lerp(p2, a)
			local ahead1 = from:Lerp(mid, math.min(a + 0.03, 1))
			local ahead2 = mid:Lerp(to, math.min(a + 0.03, 1))
			local ahead = ahead1:Lerp(ahead2, math.min(a + 0.03, 1))
			poseAt(rec.model, rec.prop, pos, (ahead - pos), math.sin(a * math.pi) * 0.15)
			if a >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
		if rec.token == token and onDone then
			onDone()
		end
	end)
end

-- Circles the plane around a center point until interrupted (hold pattern).
local function orbit(rec, center, radius, height)
	cancelMotion(rec)
	local token = rec.token
	task.spawn(function()
		local angle = 0
		while rec.token == token and rec.model.Parent do
			angle += 0.012
			local pos = center + Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
			local ahead = center + Vector3.new(math.cos(angle + 0.1) * radius, height, math.sin(angle + 0.1) * radius)
			poseAt(rec.model, rec.prop, pos, (ahead - pos), 0.35) -- banked turn
			RunService.RenderStepped:Wait()
		end
	end)
end

local function ensurePlane(plotIndex, startPos)
	local rec = activePlanes[plotIndex]
	if rec and rec.model.Parent then
		return rec
	end
	local model, prop = buildPlane(true)
	model.Parent = workspace
	model:PivotTo(CFrame.new(startPos or Vector3.new(0, 100, 0)))
	local engine = SoundBook.make("BigRumble", { Looped = true, PlaybackSpeed = 0.7, Volume = 0.5 })
	if engine and model.PrimaryPart then
		engine.Parent = model.PrimaryPart
		engine:Play()
	end
	rec = { model = model, prop = prop, engine = engine, token = 0 }
	activePlanes[plotIndex] = rec
	return rec
end

local function handlePlane(payload)
	local plotIndex = payload.plotIndex or 0
	local phase = payload.phase

	if phase == "approach" then
		destroyPlane(plotIndex) -- clear any stale plane first (no doubles)
		local rec = ensurePlane(plotIndex, payload.from)
		-- Fly in, then hold in a circle above the airport until we're told
		-- whether to land, take off, or crash.
		flyTo(rec, payload.to, payload.flight or 8, 20, function()
			orbit(rec, payload.to, 60, 0)
		end)
	elseif phase == "land" then
		local rec = ensurePlane(plotIndex, payload.from)
		-- Line up and descend smoothly onto the runway, then touch down.
		local lineup = payload.to + Vector3.new(0, 40, 90)
		flyTo(rec, lineup, 2.5, 10, function()
			flyTo(rec, payload.to, (payload.flight or 6), -6, function()
				-- Touchdown: little screech + engine spool-down.
				SoundBook.playAt("Hit", payload.to, { PlaybackSpeed = 0.7, Volume = 0.6, RollOffMaxDistance = 300 })
				if rec.engine then
					rec.engine.PlaybackSpeed = 0.45
					rec.engine.Volume = 0.25
				end
			end)
		end)
	elseif phase == "takeoff" then
		local rec = activePlanes[plotIndex]
		if not rec or not rec.model.Parent then
			return
		end
		SoundBook.playAt("Launch", rec.model:GetPivot().Position, { PlaybackSpeed = 0.9, RollOffMaxDistance = 600 })
		if rec.engine then
			rec.engine.PlaybackSpeed = 0.8
			rec.engine.Volume = 0.5
		end
		flyTo(rec, payload.to, payload.flight or 9, 60, function()
			destroyPlane(plotIndex)
		end)
	elseif phase == "crash" then
		local rec = ensurePlane(plotIndex, payload.from)
		if rec.model.PrimaryPart then
			local smoke = Instance.new("ParticleEmitter")
			smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
			smoke.Rate = 30
			smoke.Lifetime = NumberRange.new(0.8, 1.4)
			smoke.Color = ColorSequence.new(Color3.fromRGB(60, 60, 60))
			smoke.Parent = rec.model.PrimaryPart
		end
		-- Sputtering engine as the fuel runs out.
		if rec.engine then
			task.spawn(function()
				for _ = 1, 6 do
					rec.engine.PlaybackSpeed = 0.4 + math.random() * 0.5
					task.wait(0.5)
				end
			end)
		end
		flyTo(rec, payload.to, payload.flight or 7, 10, function()
			explosion(payload.to)
			destroyPlane(plotIndex)
		end)
	end
end

local function handleJet(payload)
	local model, prop = buildPlane(false)
	model.Parent = workspace
	model:PivotTo(CFrame.new(payload.from))
	SoundBook.playAt("Launch", payload.from, { PlaybackSpeed = 1.2, RollOffMaxDistance = 1200 })
	local from = payload.from
	local to = payload.to
	local flight = payload.flight or 8
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = math.min((os.clock() - t0) / flight, 1)
		local mid = (from + to) / 2 + Vector3.new(0, 40, 0)
		local pos = from:Lerp(mid, a):Lerp(mid:Lerp(to, a), a)
		local ahead = from:Lerp(mid, math.min(a + 0.03, 1)):Lerp(mid:Lerp(to, math.min(a + 0.03, 1)), math.min(a + 0.03, 1))
		poseAt(model, prop, pos, (ahead - pos))
		if a >= 1 then
			conn:Disconnect()
			explosion(to)
			model:Destroy()
		end
	end)
end

function PlaneFX.init()
	Remotes.Events.PlaneEvent.OnClientEvent:Connect(function(payload)
		if type(payload) == "table" and typeof(payload.to) == "Vector3" then
			handlePlane(payload)
		end
	end)
	Remotes.Events.JetEvent.OnClientEvent:Connect(function(payload)
		if type(payload) == "table" and typeof(payload.from) == "Vector3" then
			handleJet(payload)
		end
	end)
end

return PlaneFX
