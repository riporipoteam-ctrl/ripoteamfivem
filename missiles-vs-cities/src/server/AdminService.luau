-- Admin panel backend. Only UserIds listed in Config.Admins can use these.
-- Actions are whitelisted and validated server-side; never trust the client.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)

local AdminService = {}

local ctx

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
	end
	ctx.Economy.pushState(player)
end

function AdminService.init(context)
	ctx = context
	ctx.isAdmin = isAdmin
	Remotes.Events.AdminAction.OnServerEvent:Connect(onAdminAction)
end

return AdminService
