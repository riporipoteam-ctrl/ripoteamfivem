-- The old pilot's radio call: ACCEPT (payout, he lands) or DECLINE (he flies
-- on, runs out of fuel and may crash into your city). Auto-declines on timeout.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local NumberFormat = require(Shared.NumberFormat)
local SoundBook = require(Shared.SoundBook)
local UILib = require(script.Parent.UILib)

local PilotPrompt = {}

local gui
local timerLabel
local deadline = 0
local open = false

local function answer(accepted)
	if not open then
		return
	end
	open = false
	gui.Enabled = false
	Remotes.Events.PilotAnswer:FireServer(accepted)
end

function PilotPrompt.init()
	local panelGui, content = UILib.panel("MVC_Pilot", "\u{1F4FB} INCOMING RADIO", UDim2.new(0, 460, 0, 260), 30)
	gui = panelGui

	UILib.text({
		Size = UDim2.new(1, -20, 0, 96),
		Position = UDim2.new(0, 10, 0, 6),
		Text = "\u{1F468}\u{200D}\u{2708}\u{FE0F} \"Mayday... this here's an old cropduster, low on fuel."
			.. " Requestin' permission to land at your airport, over.\"",
		TextWrapped = true,
		TextSize = 20,
		TextScaled = false,
	}, content)

	timerLabel = UILib.text({
		Size = UDim2.new(1, -20, 0, 24),
		Position = UDim2.new(0, 10, 0, 104),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 220, 120),
	}, content)

	UILib.button({
		Size = UDim2.new(0.5, -16, 0, 60),
		Position = UDim2.new(0, 10, 1, -70),
		Text = "\u{2705} ACCEPT",
		BackgroundColor3 = UILib.Colors.Green,
	}, content, function()
		answer(true)
	end)

	UILib.button({
		Size = UDim2.new(0.5, -16, 0, 60),
		Position = UDim2.new(0.5, 6, 1, -70),
		Text = "\u{274C} DECLINE",
		BackgroundColor3 = UILib.Colors.Red,
	}, content, function()
		answer(false)
	end)

	Remotes.Events.PilotOffer.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		open = true
		deadline = os.clock() + (payload.seconds or 25)
		gui.Enabled = true
		SoundBook.play("Ding", UILib.playerGui())
	end)

	task.spawn(function()
		while true do
			task.wait(0.3)
			if open then
				local left = deadline - os.clock()
				if left <= 0 then
					answer(false)
				else
					timerLabel.Text = "Reward if you accept: \u{1F4B5} big payout   \u{2022}   Auto-decline in "
						.. NumberFormat.clock(left)
				end
			end
		end
	end)
end

return PilotPrompt
