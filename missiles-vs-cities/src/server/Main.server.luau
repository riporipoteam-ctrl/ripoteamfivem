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
local NPCBuilder = require(script.Parent.NPCBuilder)

StarterPlayer.CameraMaxZoomDistance = 400
Players.RespawnTime = 3

local world = WorldBuilder.build()
NPCBuilder.build(world.root)

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

local function onPlayerAdded(player)
	ctx.session[player] = {}
	DataService.load(player)
	if not player.Parent then
		return -- left while loading
	end
	EconomyService.onJoin(player)
	PlotService.assign(player)
	EconomyService.pushState(player)
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
