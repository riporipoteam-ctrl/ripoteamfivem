-- Missiles vs Cities: server bootstrap.
-- Builds the world, wires the services, manages player lifecycle.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
require(Shared.Remotes) -- create remotes before any client can ask for them

local DataService = require(script.Parent.DataService)
local WorldBuilder = require(script.Parent.WorldBuilder)
local BuildingVisuals = require(script.Parent.BuildingVisuals)
local PlotService = require(script.Parent.PlotService)
local EconomyService = require(script.Parent.EconomyService)
local CombatService = require(script.Parent.CombatService)
local RewardsService = require(script.Parent.RewardsService)
local QuestService = require(script.Parent.QuestService)
local EventsService = require(script.Parent.EventsService)
local CosmeticsService = require(script.Parent.CosmeticsService)
local LeaderboardService = require(script.Parent.LeaderboardService)
local CitizensService = require(script.Parent.CitizensService)
local DecorService = require(script.Parent.DecorService)
local NPCBuilder = require(script.Parent.NPCBuilder)
local DefenseService = require(script.Parent.DefenseService)
local JetService = require(script.Parent.JetService)
local BatteryService = require(script.Parent.BatteryService)
local PilotService = require(script.Parent.PilotService)
local AdminService = require(script.Parent.AdminService)
local FXTemplates = require(script.Parent.FXTemplates)

StarterPlayer.CameraMaxZoomDistance = 500
Players.RespawnTime = 3

local world = WorldBuilder.build()
task.spawn(function()
	NPCBuilder.build(world) -- avatar loading yields; don't block startup
end)
task.spawn(function()
	-- Warm the Store building templates, then upgrade any already-built
	-- cities from part visuals to the real models.
	BuildingVisuals.preload()
	PlotService.rerenderAll()
end)
task.spawn(function()
	-- Load FX vehicle/rocket models + UI kit art, then swap the decorative
	-- silo rockets and nuke displays to the real models.
	FXTemplates.init()
	PlotService.applyStoreRockets()
end)

local ctx = {
	Data = DataService,
	Visuals = BuildingVisuals,
	World = world,
	Plot = PlotService,
	Economy = EconomyService,
	Combat = CombatService,
	Rewards = RewardsService,
	Quests = QuestService,
	Events = EventsService,
	Cosmetics = CosmeticsService,
	Leaderboard = LeaderboardService,
	Defense = DefenseService,
	Jets = JetService,
	Battery = BatteryService,
	Pilot = PilotService,
	Admin = AdminService,
	eventCashMult = 1,
	session = {}, -- [player] = { giftReadyAt, rocketReadyAt, passCash, passDamage }
}

PlotService.init(ctx)
EconomyService.init(ctx)
CombatService.init(ctx)
RewardsService.init(ctx)
QuestService.init(ctx)
CosmeticsService.init(ctx)
EventsService.init(ctx)
LeaderboardService.init(ctx)
DefenseService.init(ctx)
JetService.init(ctx)
BatteryService.init(ctx)
PilotService.init(ctx)
AdminService.init(ctx)
CitizensService.init(ctx)
DecorService.init(ctx)

local Remotes = require(Shared.Remotes)

local function onPlayerAdded(player)
	ctx.session[player] = {}
	DataService.load(player)
	if not player.Parent then
		return -- left while loading
	end
	EconomyService.onJoin(player)
	PlotService.assign(player)
	EconomyService.pushState(player)

	-- Make it obvious when progress can't be saved (unpublished / API off).
	local profile = DataService.get(player)
	if profile and (profile.__noSave or not DataService.available()) then
		task.delay(6, function()
			if player.Parent then
				Remotes.Events.Notify:FireClient(player, {
					msg = "\u{26A0}\u{FE0F} SAVING IS OFF! Publish the game, then enable "
						.. "Game Settings \u{2192} Security \u{2192} Allow Studio Access to API Services.",
					kind = "bad",
				})
			end
		end)
	end
end

local function onPlayerRemoving(player)
	PlotService.release(player)
	DataService.save(player)
	DataService.forget(player)
	ctx.session[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Autosave.
task.spawn(function()
	while true do
		task.wait(Config.AutosaveInterval)
		for _, player in ipairs(Players:GetPlayers()) do
			DataService.save(player)
		end
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataService.save(player)
	end
	task.wait(1)
end)

print("[MVC] Missiles vs Cities server ready. Max " .. Config.MaxPlayers .. " players per server.")
