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

local ctx = {
	State = ClientState,
	Notifier = Notifier,
	AttackView = AttackView,
	DailyUI = DailyRewardsUI,
}

Notifier.init()
HUD.init(ctx)
AttackView.init(ctx)
DailyRewardsUI.init(ctx)
SidePanel.init(ctx)
RocketPanel.init(ctx)
AlarmUI.init()
FX.init()
CashPopups.init()
MusicPlayer.init()

ClientState.start()
