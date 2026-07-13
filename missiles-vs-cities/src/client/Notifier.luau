-- Toast notifications (top-right stack) + per-kind sounds.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local SoundBook = require(Shared.SoundBook)
local UILib = require(script.Parent.UILib)

local Notifier = {}

local KIND_STYLE = {
	good = { color = UILib.Colors.Green, sound = "Good" },
	bad = { color = UILib.Colors.Red, sound = "Bad" },
	buy = { color = UILib.Colors.Green, sound = "Buy" },
	victory = { color = UILib.Colors.Gold, sound = "Victory" },
	info = { color = UILib.Colors.Blue, sound = "Click" },
}

local gui
local holder

function Notifier.show(msg, kind)
	local style = KIND_STYLE[kind] or KIND_STYLE.info

	local toast = UILib.frame({
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = style.color,
		BackgroundTransparency = 0.05,
	}, holder)
	UILib.text({
		Size = UDim2.new(1, -16, 1, -12),
		Position = UDim2.new(0, 8, 0, 6),
		Text = msg,
		TextWrapped = true,
	}, toast)

	SoundBook.play(style.sound, UILib.playerGui())

	toast.Position = UDim2.new(1, 40, 0, 0)
	TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
	}):Play()

	task.delay(4.5, function()
		local out = TweenService:Create(toast, TweenInfo.new(0.3), {
			Position = UDim2.new(1, 60, 0, 0),
			BackgroundTransparency = 1,
		})
		out:Play()
		out.Completed:Once(function()
			toast:Destroy()
		end)
	end)
end

function Notifier.init()
	gui = UILib.screen("MVC_Toasts", 50)
	holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(1, 0)
	holder.Position = UDim2.new(1, -12, 0, 70)
	holder.Size = UDim2.new(0, 320, 1, -90)
	holder.Parent = gui

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 8)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = holder

	Remotes.Events.Notify.OnClientEvent:Connect(function(payload)
		if type(payload) == "table" and type(payload.msg) == "string" then
			Notifier.show(payload.msg, payload.kind)
		end
	end)
end

return Notifier
