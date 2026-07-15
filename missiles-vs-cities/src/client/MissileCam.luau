-- Preview camera: when YOU launch a missile/nuke, the camera rides behind it
-- and watches it strike. A SKIP button returns to normal instantly.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local SoundBook = require(Shared.SoundBook)
local UILib = require(script.Parent.UILib)

local MissileCam = {}

local player = Players.LocalPlayer
local active = false
local gui
local skipButton

local function camera()
	return workspace.CurrentCamera
end

local function quadBezier(p0, p1, p2, t)
	local a = p0:Lerp(p1, t)
	local b = p1:Lerp(p2, t)
	return a:Lerp(b, t)
end

local function stop()
	if not active then
		return
	end
	active = false
	gui.Enabled = false
	local cam = camera()
	cam.CameraType = Enum.CameraType.Custom
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		cam.CameraSubject = hum
	end
end

local function ride(payload)
	if active then
		return -- one preview at a time
	end
	active = true
	gui.Enabled = true

	local isNuke = payload.kind == "nuke"
	local from = payload.from
	local to = payload.to
	local flight = payload.flight or 8
	local riseTime = isNuke and 2.4 or 1.6
	local riseHeight = isNuke and 110 or 70
	local liftTop = from + Vector3.new(0, riseHeight, 0)
	local apex = (liftTop + to) / 2 + Vector3.new(0, isNuke and 340 or 190, 0)

	local cam = camera()
	cam.CameraType = Enum.CameraType.Scriptable

	SoundBook.play("Launch", UILib.playerGui(), { PlaybackSpeed = isNuke and 0.75 or 1 })

	local start = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not active then
			conn:Disconnect()
			return
		end
		local elapsed = os.clock() - start
		local pos, ahead
		if elapsed < riseTime then
			local tt = elapsed / riseTime
			pos = from:Lerp(liftTop, tt * tt)
			ahead = pos + Vector3.new(0, 8, 0)
		else
			local t = math.min((elapsed - riseTime) / math.max(flight - riseTime, 0.1), 1)
			pos = quadBezier(liftTop, apex, to, t)
			ahead = quadBezier(liftTop, apex, to, math.min(t + 0.03, 1))
			if t >= 1 then
				-- Hold on the impact for a beat, then return.
				cam.CFrame = CFrame.lookAt(to + Vector3.new(30, 40, 30), to)
				task.delay(isNuke and 2.5 or 1.2, stop)
				conn:Disconnect()
				return
			end
		end
		-- Chase camera just behind and above the warhead.
		local dir = (ahead - pos)
		if dir.Magnitude < 0.01 then
			dir = Vector3.new(0, 1, 0)
		end
		local behind = pos - dir.Unit * 22 + Vector3.new(0, 8, 0)
		cam.CFrame = CFrame.lookAt(behind, pos + dir.Unit * 10)
	end)
end

function MissileCam.init()
	gui = UILib.screen("MVC_MissileCam", 40)
	gui.Enabled = false

	local hint = UILib.text({
		Size = UDim2.new(0, 320, 0, 30),
		Position = UDim2.new(0.5, 0, 0, 20),
		AnchorPoint = Vector2.new(0.5, 0),
		Text = "\u{1F4F9} MISSILE CAM",
		TextColor3 = Color3.fromRGB(255, 90, 90),
	}, gui)

	skipButton = UILib.button({
		Size = UDim2.new(0, 150, 0, 50),
		Position = UDim2.new(1, -24, 1, -90),
		AnchorPoint = Vector2.new(1, 1),
		Text = "SKIP \u{23ED}\u{FE0F}",
		BackgroundColor3 = UILib.Colors.DarkGray,
	}, gui, stop)

	Remotes.Events.MissileEvent.OnClientEvent:Connect(function(payload)
		if type(payload) == "table" and payload.previewFor == player.UserId
			and typeof(payload.from) == "Vector3" and typeof(payload.to) == "Vector3" then
			ride(payload)
		end
	end)
end

return MissileCam
