-- World event banner (Cash Frenzy, Meteor Shower, ...) with horn fanfare
-- and a live countdown for timed events.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local SoundBook = require(Shared.SoundBook)
local NumberFormat = require(Shared.NumberFormat)
local UILib = require(script.Parent.UILib)

local GameEvents = {}

-- Flak burst when air defense intercepts something.
local function flakBurst(pos)
	SoundBook.playAt("Explosion", pos, { PlaybackSpeed = 1.5, Volume = 0.6, RollOffMaxDistance = 500 })
	for _ = 1, 5 do
		local puff = Instance.new("Part")
		puff.Anchored = true
		puff.CanCollide = false
		puff.CanQuery = false
		puff.Shape = Enum.PartType.Ball
		puff.Material = Enum.Material.Neon
		puff.Color = Color3.fromRGB(60, 60, 60)
		puff.Size = Vector3.new(3, 3, 3)
		puff.Position = pos + Vector3.new(math.random(-20, 20), 45 + math.random(-8, 8), math.random(-20, 20))
		puff.Parent = workspace
		task.spawn(function()
			for i = 1, 8 do
				puff.Size += Vector3.new(1.5, 1.5, 1.5)
				puff.Transparency = i / 8
				task.wait(0.04)
			end
			puff:Destroy()
		end)
	end
end

local KIND_COLORS = {
	frenzy = Color3.fromRGB(88, 200, 60),
	gems = Color3.fromRGB(190, 90, 240),
	meteor = Color3.fromRGB(235, 120, 40),
	supply = Color3.fromRGB(250, 200, 60),
	supply_claim = Color3.fromRGB(250, 200, 60),
}

local gui
local banner
local label
local hideAt = 0
local baseMsg = ""

local function show(payload)
	baseMsg = payload.msg or ""
	banner.BackgroundColor3 = KIND_COLORS[payload.kind] or UILib.Colors.Blue
	label.Text = baseMsg
	hideAt = os.clock() + math.max(payload.duration or 5, 5)

	banner.Visible = true
	banner.Position = UDim2.new(0.5, 0, 0, -70)
	TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 104),
	}):Play()

	SoundBook.play("Horn", UILib.playerGui(), { PlaybackSpeed = 1.6 })
	SoundBook.play("Ding", UILib.playerGui())
end

function GameEvents.init()
	gui = UILib.screen("MVC_Events", 8)
	banner = UILib.frame({
		Size = UDim2.new(0, 620, 0, 46),
		Position = UDim2.new(0.5, 0, 0, 104),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = UILib.Colors.Blue,
		Visible = false,
	}, gui)
	label = UILib.text({
		Size = UDim2.new(1, -16, 1, -8),
		Position = UDim2.new(0, 8, 0, 4),
		Text = "",
	}, banner)

	Remotes.Events.GameEvent.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		if payload.kind == "intercept" and typeof(payload.pos) == "Vector3" then
			flakBurst(payload.pos)
			return
		end
		if type(payload.msg) == "string" then
			show(payload)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.5)
			if banner.Visible then
				local left = hideAt - os.clock()
				if left <= 0 then
					banner.Visible = false
				elseif left < 120 then
					label.Text = baseMsg .. "  (" .. NumberFormat.clock(left) .. ")"
				end
			end
		end
	end)
end

return GameEvents
