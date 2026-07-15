-- Missiles vs Cities: client bootstrap.

local ClientState = require(script.Parent.ClientState)
local Notifier = require(script.Parent.Notifier)
local HUD = require(script.Parent.HUD)
local SidePanel = require(script.Parent.SidePanel)
local RocketPanel = require(script.Parent.RocketPanel)
local AttackView = require(script.Parent.AttackView)
local DailyRewardsUI = require(script.Parent.DailyRewardsUI)
local AlarmUI = require(script.Parent.AlarmUI)
local FX = require(script.Parent.FX)
local CashPopups = require(script.Parent.CashPopups)
local MusicPlayer = require(script.Parent.MusicPlayer)
local Dialogue = require(script.Parent.Dialogue)
local QuestUI = require(script.Parent.QuestUI)
local CharacterShop = require(script.Parent.CharacterShop)
local GameEvents = require(script.Parent.GameEvents)
local RebirthUI = require(script.Parent.RebirthUI)
local MissileCam = require(script.Parent.MissileCam)
local PlaneFX = require(script.Parent.PlaneFX)
local PilotPrompt = require(script.Parent.PilotPrompt)
local AdminPanel = require(script.Parent.AdminPanel)
local MilitaryPanel = require(script.Parent.MilitaryPanel)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundBook = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundBook"))
SoundBook.preload() -- warm the Store SFX so first plays are instant

local ctx = {
	State = ClientState,
	Notifier = Notifier,
	AttackView = AttackView,
	DailyUI = DailyRewardsUI,
	QuestUI = QuestUI,
	CharShop = CharacterShop,
	Military = MilitaryPanel,
	ShopToggle = SidePanel.toggleShop,
}

Notifier.init()
HUD.init(ctx)
AttackView.init(ctx)
DailyRewardsUI.init(ctx)
QuestUI.init(ctx)
CharacterShop.init(ctx)
MilitaryPanel.init(ctx)
AdminPanel.init(ctx)
SidePanel.init(ctx)
RocketPanel.init(ctx)
Dialogue.init(ctx)
RebirthUI.init(ctx)
AlarmUI.init()
FX.init()
CashPopups.init()
GameEvents.init()
MissileCam.init()
PlaneFX.init()
PilotPrompt.init()
MusicPlayer.init()

ClientState.start()
