-- All game audio in one place. The rbxasset:// entries are built into every
-- Roblox install so they always play; swap any of them for marketplace ids
-- ("rbxassetid://12345") if you want richer audio later.

local SoundBook = {}

SoundBook.Defs = {
	Click = { id = "rbxasset://sounds/button.wav", volume = 0.6 },
	Good = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.7 },
	Bad = { id = "rbxasset://sounds/uuhhh.wav", volume = 0.7 },
	Buy = { id = "rbxasset://sounds/snap.wav", volume = 0.8 },
	Launch = { id = "rbxasset://sounds/swoosh.wav", volume = 1 },
	Explosion = { id = "rbxasset://sounds/collide.wav", volume = 1 },
	BigRumble = { id = "rbxasset://sounds/bass.wav", volume = 1 },
	Glass = { id = "rbxasset://sounds/glassbreak.wav", volume = 0.9 },
	Victory = { id = "rbxasset://sounds/victory.wav", volume = 0.8 },
	Flash = { id = "rbxasset://sounds/flashbulb.wav", volume = 0.9 },
	Siren = { id = "rbxasset://sounds/bass.wav", volume = 0.9 }, -- pitch-modulated into a wail by AlarmUI
}

-- Background music playlist (Roblox library asset ids). Edit freely.
SoundBook.Music = { 142376088 }

function SoundBook.make(key, props)
	local def = SoundBook.Defs[key]
	if not def then
		return nil
	end
	local s = Instance.new("Sound")
	s.SoundId = def.id
	s.Volume = def.volume
	if props then
		for k, v in pairs(props) do
			s[k] = v
		end
	end
	return s
end

function SoundBook.play(key, parent, props)
	local s = SoundBook.make(key, props)
	if not s then
		return nil
	end
	s.Parent = parent
	s:Play()
	s.Ended:Once(function()
		s:Destroy()
	end)
	task.delay(12, function()
		if s and s.Parent then
			s:Destroy()
		end
	end)
	return s
end

-- Positional one-shot: spins up a throwaway invisible part to host the sound.
function SoundBook.playAt(key, position, props)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(1, 1, 1)
	holder.Position = position
	holder.Parent = workspace
	local s = SoundBook.play(key, holder, props)
	task.delay(12, function()
		holder:Destroy()
	end)
	return s
end

return SoundBook
