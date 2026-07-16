-- Admin panel backend. Only UserIds listed in Config.Admins can use these.
-- Actions are whitelisted and validated server-side; never trust the client.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")
local DataStoreService = game:GetService("DataStoreService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)

local AdminService = {}

local ctx
local CROSS_TOPIC = "MVC_AdminCross"

local banStore
do
	local ok, s = pcall(function()
		return DataStoreService:GetDataStore("MVC_Bans_v1")
	end)
	if ok then
		banStore = s
	end
end

function AdminService.isBanned(userId)
	if not banStore then
		return false
	end
	local ok, v = pcall(function()
		return banStore:GetAsync("ban_" .. userId)
	end)
	return ok and v == true
end

local function isAdmin(player)
	-- In Studio playtests everyone is an admin, so you can always see the panel.
	if RunService:IsStudio() then
		return true
	end
	-- The game's owner is always an admin.
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end
	if game.CreatorType == Enum.CreatorType.Group then
		local ok, rank = pcall(function()
			return player:GetRankInGroup(game.CreatorId)
		end)
		if ok and rank >= 254 then
			return true
		end
	end
	for _, id in ipairs(Config.Admins) do
		if id == player.UserId then
			return true
		end
	end
	return false
end
AdminService.isAdmin = isAdmin

local function notify(player, msg, kind)
	Remotes.Events.Notify:FireClient(player, { msg = msg, kind = kind or "info" })
end

local function onAdminAction(player, action, arg)
	if not isAdmin(player) then
		return -- silent: not an admin
	end
	local profile = ctx.Data.get(player)
	if not profile then
		return
	end

	if action == "give_cash" then
		local amount = tonumber(arg) or 1e9
		profile.cash += amount
		notify(player, "\u{1F6E0}\u{FE0F} Admin: +\u{1F4B5} " .. NumberFormat.abbrev(amount), "victory")
	elseif action == "give_gems" then
		local amount = tonumber(arg) or 1000
		profile.gems += amount
		notify(player, "\u{1F6E0}\u{FE0F} Admin: +\u{1F48E} " .. amount, "victory")
	elseif action == "max_rockets" then
		profile.rocketLevel = Config.Rocket.MaxLevel
		profile.siloCount = Config.Silos.Max
		local slot = ctx.Plot.getSlot(player)
		if slot then
			ctx.Plot.updateSilos(slot, profile.siloCount)
			ctx.Plot.updateRocketVisual(slot, profile.rocketLevel)
		end
		notify(player, "\u{1F6E0}\u{FE0F} Admin: rockets maxed!", "victory")
	elseif action == "give_nuke" then
		profile.nukeIsland = true
		profile.lastNukeAt = 0
		notify(player, "\u{1F6E0}\u{FE0F} Admin: nuke access + reset cooldown!", "victory")
	elseif action == "repair" then
		local slot = ctx.Plot.getSlot(player)
		if slot then
			ctx.Plot.repairAll(slot)
		end
		notify(player, "\u{1F6E0}\u{FE0F} Admin: city repaired!", "good")
	elseif action == "unlock_all" then
		local BuildingDefs = require(Shared.BuildingDefs)
		profile.unlocked = #BuildingDefs.List
		local slot = ctx.Plot.getSlot(player)
		if slot then
			ctx.Plot.resetBuildings(player) -- re-derives locks with new unlocked count
		end
		notify(player, "\u{1F6E0}\u{FE0F} Admin: all areas unlocked!", "victory")
	elseif action == "trigger_event" then
		if ctx.Events then
			ctx.Events.fireRandom()
		end
		notify(player, "\u{1F6E0}\u{FE0F} Admin: random event triggered!", "info")
	elseif action == "trigger_pilot" then
		local slot = ctx.Plot.getSlot(player)
		if slot and ctx.Pilot then
			ctx.Pilot.trigger(slot)
		end
	elseif action == "nuke_server" then
		AdminService.nukeServer(player.DisplayName)
	elseif action == "nuke_all_servers" then
		pcall(function()
			MessagingService:PublishAsync(CROSS_TOPIC, { kind = "nuke", by = player.DisplayName })
		end)
		AdminService.nukeServer(player.DisplayName)
		notify(player, "\u{1F6E0}\u{FE0F} Nuking ALL servers!", "victory")
	elseif action == "announce_server" then
		AdminService.announce(tostring(arg), player.DisplayName)
	elseif action == "announce_all" then
		pcall(function()
			MessagingService:PublishAsync(CROSS_TOPIC, { kind = "announce", text = tostring(arg), by = player.DisplayName })
		end)
		AdminService.announce(tostring(arg), player.DisplayName)
	elseif action == "kick" then
		local target = Players:GetPlayerByUserId(tonumber(arg) or 0)
		if target then
			target:Kick("Kicked by an admin.")
			notify(player, "\u{1F6E0}\u{FE0F} Kicked " .. target.DisplayName, "info")
		end
	elseif action == "ban" then
		local id = tonumber(arg) or 0
		if banStore then
			pcall(function()
				banStore:SetAsync("ban_" .. id, true)
			end)
		end
		local target = Players:GetPlayerByUserId(id)
		if target then
			target:Kick("You are banned from this game.")
		end
		notify(player, "\u{1F6E0}\u{FE0F} Banned user " .. id, "bad")
	elseif action == "unban" then
		local id = tonumber(arg) or 0
		if banStore then
			pcall(function()
				banStore:RemoveAsync("ban_" .. id)
			end)
		end
		notify(player, "\u{1F6E0}\u{FE0F} Unbanned user " .. id, "good")
	elseif action == "take_cash" then
		local target = Players:GetPlayerByUserId(tonumber(arg) or 0)
		local tp = target and ctx.Data.get(target)
		if tp then
			tp.cash = 0
			ctx.Economy.pushState(target)
			notify(player, "\u{1F6E0}\u{FE0F} Wiped " .. target.DisplayName .. "'s cash", "info")
		end
	elseif action == "take_gems" then
		local target = Players:GetPlayerByUserId(tonumber(arg) or 0)
		local tp = target and ctx.Data.get(target)
		if tp then
			tp.gems = 0
			ctx.Economy.pushState(target)
			notify(player, "\u{1F6E0}\u{FE0F} Wiped " .. target.DisplayName .. "'s gems", "info")
		end
	elseif action == "nuke_player" then
		local target = Players:GetPlayerByUserId(tonumber(arg) or 0)
		local slot = target and ctx.Plot.getSlot(target)
		if slot then
			ctx.Plot.nukeSlot(slot)
			notify(target, "\u{2622}\u{FE0F} An admin nuked your city!", "bad")
			ctx.Economy.pushState(target)
		end
	end
	ctx.Economy.pushState(player)
end

-- Nukes every owned city in THIS server.
function AdminService.nukeServer(byName)
	for _, slot in ipairs(ctx.Plot.slots()) do
		if slot.owner then
			ctx.Plot.nukeSlot(slot)
			ctx.Economy.pushState(slot.owner)
		end
	end
	Remotes.Events.Notify:FireAllClients({
		msg = "\u{2622}\u{FE0F} ADMIN " .. (byName or "") .. " NUKED THE ENTIRE SERVER!",
		kind = "bad",
	})
end

function AdminService.announce(text, byName)
	Remotes.Events.Notify:FireAllClients({
		msg = "\u{1F4E2} [ADMIN" .. (byName and " " .. byName or "") .. "] " .. text,
		kind = "victory",
	})
end

function AdminService.init(context)
	ctx = context
	ctx.isAdmin = isAdmin
	Remotes.Events.AdminAction.OnServerEvent:Connect(onAdminAction)

	-- Cross-server admin commands.
	pcall(function()
		MessagingService:SubscribeAsync(CROSS_TOPIC, function(message)
			local data = message.Data
			if type(data) ~= "table" then
				return
			end
			if data.kind == "nuke" then
				AdminService.nukeServer(data.by)
			elseif data.kind == "announce" then
				AdminService.announce(data.text, data.by)
			end
		end)
	end)

	-- Enforce bans on join.
	Players.PlayerAdded:Connect(function(plr)
		task.spawn(function()
			if AdminService.isBanned(plr.UserId) then
				plr:Kick("You are banned from this game.")
			end
		end)
	end)
end

return AdminService
