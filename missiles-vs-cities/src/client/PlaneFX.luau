-- Flight FX for the pilot's cropduster (PlaneEvent) and jet strikes (JetEvent).
-- Builds a little plane/jet, flies it along the path with engine + radio SFX,
-- and handles landing / takeoff / crash-explosion visuals.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local SoundBook = require(Shared.SoundBook)

local PlaneFX = {}

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

local function buildPlane(cropduster)
	local model = Instance.new("Model")
	model.Name = "MVC_Plane"
	local bodyColor = cropduster and Color3.fromRGB(220, 180, 70) or Color3.fromRGB(90, 100, 120)
	local body = anchoredPart({
		Name = "Body",
		Size = Vector3.new(2.4, 2, cropduster and 9 or 11),
		Color = bodyColor,
		Material = Enum.Material.Metal,
		Parent = model,
	})
	anchoredPart({
		Name = "Wing",
		Size = Vector3.new(cropduster and 14 or 12, 0.5, 3),
		Color = bodyColor,
		Parent = model,
	})
	anchoredPart({
		Name = "Tail",
		Size = Vector3.new(0.5, 2.4, 2),
		Color = bodyColor,
		Parent = model,
	})
	local prop = anchoredPart({
		Name = "Prop",
		Size = Vector3.new(cropduster and 5 or 3, 0.4, 0.4),
		Color = Color3.fromRGB(40, 40, 40),
		Parent = model,
	})
	model.PrimaryPart = body
	return model, body, prop
end

-- Flies a model from -> to over flight seconds, nose pointed along travel.
local function flyPath(model, body, prop, from, to, flight, onDone)
	local start = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = math.min((os.clock() - start) / flight, 1)
		local pos = from:Lerp(to, t)
		local ahead = from:Lerp(to, math.min(t + 0.02, 1))
		local look = (ahead - pos).Magnitude > 0.01 and CFrame.lookAt(pos, ahead) or CFrame.new(pos)
		model:PivotTo(look)
		if prop then
			prop.CFrame = body.CFrame * CFrame.new(0, 0, -(body.Size.Z / 2 + 0.3))
				* CFrame.Angles(0, 0, os.clock() * 40)
		end
		if t >= 1 then
			conn:Disconnect()
			if onDone then
				onDone()
			end
		end
	end)
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

local function radio(text)
	-- Static burst then the message plays via the notifier already; here we
	-- just add a short radio blip sound.
	SoundBook.play("Blip", workspace.CurrentCamera and game.Players.LocalPlayer:WaitForChild("PlayerGui"), { PlaybackSpeed = 0.7 })
	local _ = text
end

local function handlePlane(payload)
	local phase = payload.phase
	local cropduster = true
	local model, body, prop = buildPlane(cropduster)
	model.Parent = workspace

	local engine = SoundBook.make("BigRumble", { Looped = true, PlaybackSpeed = 0.7, Volume = 0.5 })
	if engine then
		engine.Parent = body
		engine:Play()
	end

	local function cleanup()
		if engine then
			engine:Stop()
		end
		model:Destroy()
	end

	if phase == "crash" then
		flyPath(model, body, prop, payload.from, payload.to, payload.flight, function()
			explosion(payload.to)
			cleanup()
		end)
		-- Trailing smoke while it goes down.
		local smoke = Instance.new("ParticleEmitter")
		smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
		smoke.Rate = 30
		smoke.Lifetime = NumberRange.new(0.8, 1.4)
		smoke.Color = ColorSequence.new(Color3.fromRGB(60, 60, 60))
		smoke.Parent = body
	elseif phase == "land" then
		flyPath(model, body, prop, payload.from, payload.to, payload.flight, function()
			task.delay(9, cleanup) -- sit on the runway a bit, then despawn
		end)
	elseif phase == "takeoff" then
		flyPath(model, body, prop, payload.from, payload.to, payload.flight, cleanup)
	else -- approach
		flyPath(model, body, prop, payload.from, payload.to, payload.flight, function()
			-- Circle-hold: keep it visible until land/crash/takeoff arrives.
			task.delay(30, cleanup)
		end)
	end
	radio(phase)
end

local function handleJet(payload)
	local model, body, prop = buildPlane(false)
	model.Parent = workspace
	SoundBook.playAt("Launch", payload.from, { PlaybackSpeed = 1.2, RollOffMaxDistance = 1200 })
	flyPath(model, body, prop, payload.from, payload.to, payload.flight, function()
		explosion(payload.to)
		model:Destroy()
	end)
end

function PlaneFX.init()
	Remotes.Events.PlaneEvent.OnClientEvent:Connect(function(payload)
		if type(payload) == "table" and typeof(payload.from) == "Vector3" then
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
