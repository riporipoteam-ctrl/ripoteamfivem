-- Incoming-strike warning: flashing red overlay, siren wail, countdown,
-- and a red beacon beam marking exactly where the strike will land.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local SoundBook = require(Shared.SoundBook)
local NumberFormat = require(Shared.NumberFormat)

local AlarmUI = {}

local player = Players.LocalPlayer
local activeAlarm = nil

local function beacon(pos, duration)
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.Size = Vector3.new(2, 120, 2)
	beam.Position = pos + Vector3.new(0, 60, 0)
	beam.Color = Color3.fromRGB(255, 40, 40)
	beam.Material = Enum.Material.Neon
	beam.Transparency = 0.25
	beam.Parent = workspace

	local ring = Instance.new("Part")
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.4, 30, 30)
	ring.CFrame = CFrame.new(pos + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = Color3.fromRGB(255, 40, 40)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.3
	ring.Parent = workspace

	task.spawn(function()
		local elapsed = 0
		while elapsed < duration do
			local pulse = TweenService:Create(ring, TweenInfo.new(0.5), { Transparency = 0.75 })
			pulse:Play()
			task.wait(0.5)
			ring.Transparency = 0.3
			elapsed += 0.6
			task.wait(0.1)
		end
		beam:Destroy()
		ring:Destroy()
	end)
end

local function runSiren(duration)
	local sound = SoundBook.make("Siren", { Looped = true })
	if not sound then
		return
	end
	sound.Parent = player:WaitForChild("PlayerGui")
	sound:Play()
	task.spawn(function()
		task.wait(0.8)
		-- Real air-raid siren loaded? Let it wail naturally. Otherwise
		-- pitch-modulate the fallback bass into a siren.
		local isRealSiren = sound.IsLoaded and sound.TimeLength > 3
		local elapsed = 0.8
		local up = true
		while elapsed < duration do
			if not isRealSiren then
				local target = up and 1.4 or 0.55
				TweenService:Create(sound, TweenInfo.new(0.45), { PlaybackSpeed = target }):Play()
				up = not up
			end
			task.wait(0.45)
			elapsed += 0.45
		end
		sound:Stop()
		sound:Destroy()
	end)
end

local function showAlarm(payload)
	if activeAlarm then
		activeAlarm:Destroy()
		activeAlarm = nil
	end

	local isNuke = payload.kind == "nuke"
	local eta = payload.eta or 6

	local gui = Instance.new("ScreenGui")
	gui.Name = "MVC_Alarm"
	gui.DisplayOrder = 60
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	activeAlarm = gui

	local vignette = Instance.new("Frame")
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
	vignette.BackgroundTransparency = 0.85
	vignette.BorderSizePixel = 0
	vignette.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 64)
	title.Position = UDim2.new(0, 0, 0.16, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 60, 60)
	title.TextStrokeColor3 = Color3.new(0, 0, 0)
	title.TextStrokeTransparency = 0
	local titleByKind = {
		nuke = "\u{2622}\u{FE0F} NUCLEAR STRIKE INCOMING \u{2622}\u{FE0F}",
		jet = "\u{2708}\u{FE0F} ENEMY JETS INBOUND \u{2708}\u{FE0F}",
		battery = "\u{1F680} MISSILE BARRAGE INCOMING \u{1F680}",
		rocket = "\u{1F6A8} INCOMING MISSILE \u{1F6A8}",
	}
	title.Text = titleByKind[payload.kind] or titleByKind.rocket
	title.Parent = gui

	local countdown = Instance.new("TextLabel")
	countdown.Size = UDim2.new(1, 0, 0, 40)
	countdown.Position = UDim2.new(0, 0, 0.16, 66)
	countdown.BackgroundTransparency = 1
	countdown.Font = Enum.Font.FredokaOne
	countdown.TextScaled = true
	countdown.TextColor3 = Color3.new(1, 1, 1)
	countdown.TextStrokeColor3 = Color3.new(0, 0, 0)
	countdown.TextStrokeTransparency = 0
	countdown.Parent = gui

	if typeof(payload.pos) == "Vector3" then
		beacon(payload.pos, eta)
	end
	runSiren(math.min(eta, 15))

	task.spawn(function()
		local deadline = os.clock() + eta
		local flashUp = true
		while os.clock() < deadline and gui.Parent do
			countdown.Text = "Impact in " .. NumberFormat.clock(deadline - os.clock()) .. "!"
			vignette.BackgroundTransparency = flashUp and 0.75 or 0.9
			title.TextTransparency = flashUp and 0 or 0.25
			flashUp = not flashUp
			task.wait(0.4)
		end
		if gui.Parent then
			gui:Destroy()
		end
		if activeAlarm == gui then
			activeAlarm = nil
		end
	end)
end

function AlarmUI.init()
	Remotes.Events.Alarm.OnClientEvent:Connect(function(payload)
		if type(payload) == "table" then
			showAlarm(payload)
		end
	end)
end

return AlarmUI
