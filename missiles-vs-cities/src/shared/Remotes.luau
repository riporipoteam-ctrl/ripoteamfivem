-- Creates (server) or fetches (client) all RemoteEvents/RemoteFunctions.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = {
	"State", -- server -> client: full player state snapshot
	"IncomePops", -- server -> all: floating +$ popup batches
	"Notify", -- server -> client(s): toast messages
	"MissileEvent", -- server -> all: rocket/nuke flight for client FX
	"Alarm", -- server -> victim: incoming strike warning
	"ShieldFX", -- server -> all: shield block visual
	"DailyData", -- server -> client: daily rewards refresh
	"RequestLaunch", -- client -> server: fire rocket/nuke
	"UpgradeRocket", -- client -> server
	"ClaimDaily", -- client -> server
	"ShopBuy", -- client -> server: gem shop / gamepass / character shop
	"ClaimGift", -- client -> server
	"GameEvent", -- server -> all: random world events (frenzy, meteors, ...)
	"RequestRebirth", -- client -> server
	"RequestJet", -- client -> server: jet strike (city or silos)
	"RequestBattery", -- client -> server: battery volley
	"UpgradeBattery", -- client -> server
	"JetEvent", -- server -> all: jet flight FX
	"PlaneEvent", -- server -> all: pilot plane FX (landing / crash)
	"PilotOffer", -- server -> client: the old pilot asks to land
	"PilotAnswer", -- client -> server: accept / decline
	"AdminAction", -- client -> server (validated against Config.Admins)
}
local FUNCTIONS = {
	"GetSnapshot", -- client asks for initial state
	"GetTargets", -- client asks who can be attacked
}

local Remotes = { Events = {}, Functions = {} }

if RunService:IsServer() then
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in ipairs(EVENTS) do
		local ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = folder
		Remotes.Events[name] = ev
	end
	for _, name in ipairs(FUNCTIONS) do
		local fn = Instance.new("RemoteFunction")
		fn.Name = name
		fn.Parent = folder
		Remotes.Functions[name] = fn
	end
	folder.Parent = ReplicatedStorage
else
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	for _, name in ipairs(EVENTS) do
		Remotes.Events[name] = folder:WaitForChild(name)
	end
	for _, name in ipairs(FUNCTIONS) do
		Remotes.Functions[name] = folder:WaitForChild(name)
	end
end

return Remotes
