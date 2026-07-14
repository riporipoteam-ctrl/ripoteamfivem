-- DataStore persistence with retries and graceful degradation: if DataStores
-- are unavailable (unpublished place / Studio without API access) the game
-- still runs, it just won't save.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local DataService = {}

local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("MVC_PlayerData_v1")
	end)
	if ok then
		store = result
	else
		warn("[MVC] DataStores unavailable, running without saving: " .. tostring(result))
	end
end

local profiles = {} -- [player] = profile

local function defaultProfile()
	return {
		cash = Config.StartingCash,
		gems = Config.StartingGems,
		buildings = { house = 1 },
		unlocked = 1, -- how many zone areas of the island are unlocked
		rocketLevel = 1,
		shields = 0,
		barrage = 0,
		nukeIsland = false,
		nukeCharges = 0,
		lastNukeAt = 0,
		rebirths = 0,
		cosmetics = { speed = 0, jump = 0, trail = false, title = "" },
		quests = {},
		daily = { streak = 0, lastClaimAt = 0 },
		stats = { nukesFired = 0, missilesFired = 0, stolen = 0 },
	}
end

local function mergeInto(base, saved)
	for k, v in pairs(saved) do
		if type(v) == "table" and type(base[k]) == "table" then
			mergeInto(base[k], v)
		else
			base[k] = v
		end
	end
end

local function key(player)
	return "u_" .. player.UserId
end

function DataService.load(player)
	local profile = defaultProfile()
	if store then
		local loaded = nil
		for attempt = 1, 3 do
			local ok, result = pcall(function()
				return store:GetAsync(key(player))
			end)
			if ok then
				loaded = result
				profile.__loadOk = true
				break
			end
			if attempt < 3 then
				task.wait(1.5 * attempt)
			end
		end
		if type(loaded) == "table" then
			mergeInto(profile, loaded)
			profile.__loadOk = true
		end
	end
	if not profile.__loadOk and store then
		-- Never overwrite real data with defaults after a failed load.
		profile.__noSave = true
		warn("[MVC] Failed to load data for " .. player.Name .. "; running session-only.")
	end
	profiles[player] = profile
	return profile
end

function DataService.get(player)
	return profiles[player]
end

local function snapshot(profile)
	local copy = {}
	for k, v in pairs(profile) do
		if type(k) == "string" and k:sub(1, 2) ~= "__" then
			if type(v) == "table" then
				local inner = {}
				for k2, v2 in pairs(v) do
					inner[k2] = v2
				end
				copy[k] = inner
			else
				copy[k] = v
			end
		end
	end
	return copy
end

function DataService.save(player)
	local profile = profiles[player]
	if not profile or not store or profile.__noSave then
		return false
	end
	local data = snapshot(profile)
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			store:UpdateAsync(key(player), function()
				return data
			end)
		end)
		if ok then
			return true
		end
		warn("[MVC] Save attempt " .. attempt .. " failed for " .. player.Name .. ": " .. tostring(err))
		if attempt < 3 then
			task.wait(2 * attempt)
		end
	end
	return false
end

function DataService.forget(player)
	profiles[player] = nil
end

function DataService.available()
	return store ~= nil
end

function DataService.allPlayers()
	return profiles
end

return DataService
