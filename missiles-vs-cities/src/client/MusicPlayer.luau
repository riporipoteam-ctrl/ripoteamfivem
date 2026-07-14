-- Chill background music: finds the first track id that actually loads,
-- then loops it forever. Mute toggle bottom-right.

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundBook = require(Shared.SoundBook)
local UILib = require(script.Parent.UILib)

local MusicPlayer = {}

local muted = false
local current = nil
local VOLUME = 0.16

local function startMusic()
	for _, id in ipairs(SoundBook.Music) do
		local sound = Instance.new("Sound")
		sound.Name = "MVC_Music"
		sound.SoundId = "rbxassetid://" .. id
		sound.Volume = muted and 0 or VOLUME
		sound.Looped = true
		sound.Parent = SoundService

		local waited = 0
		while not sound.IsLoaded and waited < 6 do
			task.wait(0.5)
			waited += 0.5
		end
		if sound.IsLoaded then
			current = sound
			sound:Play()
			return -- loop this one forever
		end
		sound:Destroy() -- broken/moderated id, try the next
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
			current.Volume = muted and 0 or VOLUME
		end
	end)

	task.spawn(startMusic)
end

return MusicPlayer
