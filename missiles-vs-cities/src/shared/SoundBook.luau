-- All game audio in one place. The rbxasset:// entries are built into every
-- Roblox install so they always play; swap any of them for marketplace ids
-- ("rbxassetid://12345") if you want richer audio later.

local SoundBook = {}

-- Primary ids are real Creator Store SFX (all licensed for any experience,
-- curated from create.roblox.com/store audio). Every entry has a built-in
-- rbxasset fallback that plays if the Store id ever fails to load.
SoundBook.Defs = {
	Click = { id = "rbxassetid://8755541422", fallback = "rbxasset://sounds/button.wav", volume = 0.7 }, -- pop click
	Good = { id = "rbxassetid://8646410774", fallback = "rbxasset://sounds/electronicpingshort.wav", volume = 0.8 }, -- coin collect
	Bad = { id = "rbxasset://sounds/uuhhh.wav", volume = 0.7 },
	Buy = { id = "rbxassetid://134810204798705", fallback = "rbxasset://sounds/snap.wav", volume = 0.9 }, -- cash register
	Launch = { id = "rbxassetid://12222065", fallback = "rbxasset://sounds/swoosh.wav", volume = 1 }, -- official Roblox rocket launch
	Explosion = { id = "rbxassetid://125127520917980", fallback = "rbxasset://sounds/collide.wav", volume = 1 }, -- big explosion
	Nuke = { id = "rbxassetid://7163539309", fallback = "rbxasset://sounds/bass.wav", volume = 1 }, -- 21s nuclear blast
	BigRumble = { id = "rbxasset://sounds/bass.wav", volume = 1 },
	Glass = { id = "rbxasset://sounds/glassbreak.wav", volume = 0.9 },
	Victory = { id = "rbxassetid://1836473422", fallback = "rbxasset://sounds/victory.wav", volume = 0.9 }, -- APM fanfare
	Flash = { id = "rbxasset://sounds/flashbulb.wav", volume = 0.9 },
	Siren = { id = "rbxassetid://9113073796", fallback = "rbxasset://sounds/bass.wav", volume = 0.9 }, -- real air raid siren
	PanelOpen = { id = "rbxassetid://138890894929151", fallback = "rbxasset://sounds/swoosh.wav", volume = 0.6 }, -- whoosh
	Blip = { id = "rbxasset://sounds/button.wav", volume = 0.25 }, -- dialogue typewriter
	Horn = { id = "rbxasset://sounds/bass.wav", volume = 0.9 }, -- world event fanfare (pitched up)
	Ding = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.9 },
	Splat = { id = "rbxasset://sounds/splat.wav", volume = 0.8 },
	Hit = { id = "rbxasset://sounds/hit.wav", volume = 0.8 },
}

-- Chill background music (Creator Store, free-to-use): first id that loads
-- plays on loop forever. "Pixel Dreams" leads — fits the blocky vibe.
SoundBook.Music = { 123846926386533, 136419664364400, 137626560269194 }

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
	local def = SoundBook.Defs[key]
	local s = SoundBook.make(key, props)
	if not s then
		return nil
	end
	s.Parent = parent
	s:Play()
	-- If the Store id hasn't loaded shortly after, swap to the built-in.
	if def.fallback then
		task.delay(0.7, function()
			if s.Parent and not s.IsLoaded then
				s:Stop()
				s.SoundId = def.fallback
				s:Play()
			end
		end)
	end
	s.Ended:Once(function()
		s:Destroy()
	end)
	task.delay(25, function()
		if s and s.Parent then
			s:Destroy()
		end
	end)
	return s
end

-- Client-side: warm the Store sound ids so first plays are instant.
function SoundBook.preload()
	task.spawn(function()
		local ContentProvider = game:GetService("ContentProvider")
		local SoundService = game:GetService("SoundService")
		local temp = {}
		for _, def in pairs(SoundBook.Defs) do
			if def.id:sub(1, 11) == "rbxassetid:" then
				local s = Instance.new("Sound")
				s.SoundId = def.id
				s.Parent = SoundService
				temp[#temp + 1] = s
			end
		end
		pcall(function()
			ContentProvider:PreloadAsync(temp)
		end)
		task.delay(5, function()
			for _, s in ipairs(temp) do
				s:Destroy()
			end
		end)
	end)
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
