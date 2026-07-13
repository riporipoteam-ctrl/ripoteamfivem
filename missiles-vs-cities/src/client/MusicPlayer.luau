-- Background music playlist with a mute toggle (bottom-right).

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundBook = require(Shared.SoundBook)
local UILib = require(script.Parent.UILib)

local MusicPlayer = {}

local muted = false
local current = nil

local function playLoop()
	local trackIndex = 0
	while true do
		if #SoundBook.Music == 0 then
			return
		end
		trackIndex = (trackIndex % #SoundBook.Music) + 1

		local sound = Instance.new("Sound")
		sound.Name = "MVC_Music"
		sound.SoundId = "rbxassetid://" .. SoundBook.Music[trackIndex]
		sound.Volume = muted and 0 or 0.2
		sound.Parent = SoundService
		current = sound
		sound:Play()

		-- Give it a moment to load; skip broken/moderated ids gracefully.
		local waited = 0
		while not sound.IsLoaded and waited < 6 do
			task.wait(0.5)
			waited += 0.5
		end
		if sound.IsLoaded then
			while sound.IsPlaying do
				task.wait(1)
			end
		end
		sound:Destroy()
		current = nil
		task.wait(2)
	end
end

function MusicPlayer.init()
	local gui = UILib.screen("MVC_Music", 4)
	local toggle = UILib.button({
		Size = UDim2.new(0, 44, 0, 44),
		Position = UDim2.new(1, -56, 1, -110),
		Text = "\u{1F50A}",
		BackgroundColor3 = UILib.Colors.DarkGray,
	}, gui, nil)
	toggle.Activated:Connect(function()
		muted = not muted
		toggle.Text = muted and "\u{1F507}" or "\u{1F50A}"
		if current then
			current.Volume = muted and 0 or 0.2
		end
	end)

	task.spawn(playLoop)
end

return MusicPlayer
