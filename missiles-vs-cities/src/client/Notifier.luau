-- Toast notifications: redesigned as rounded cards with a colored side stripe,
-- an emoji badge, drop-in bounce and auto-dismiss. Stacks bottom-left so it
-- never collides with the right-side buttons or the top HUD.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local SoundBook = require(Shared.SoundBook)
local UILib = require(script.Parent.UILib)

local Notifier = {}

local KIND_STYLE = {
	good = { color = Color3.fromRGB(80, 200, 90), sound = "Good", badge = "\u{2705}" },
	bad = { color = Color3.fromRGB(235, 70, 70), sound = "Bad", badge = "\u{26A0}\u{FE0F}" },
	buy = { color = Color3.fromRGB(90, 200, 120), sound = "Buy", badge = "\u{1F6D2}" },
	victory = { color = Color3.fromRGB(250, 200, 60), sound = "Victory", badge = "\u{1F389}" },
	info = { color = Color3.fromRGB(80, 160, 240), sound = "Click", badge = "\u{2139}\u{FE0F}" },
}

local gui
local holder

function Notifier.show(msg, kind)
	local style = KIND_STYLE[kind] or KIND_STYLE.info

	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(1, 0, 0, 56)
	toast.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
	toast.BackgroundTransparency = 0.08
	toast.BorderSizePixel = 0
	UILib.corner(toast, 8)
	UILib.stroke(toast, 2, Color3.new(0, 0, 0))
	toast.Parent = holder

	-- Colored side stripe.
	local stripe = Instance.new("Frame")
	stripe.Size = UDim2.new(0, 7, 1, -10)
	stripe.Position = UDim2.new(0, 5, 0, 5)
	stripe.BackgroundColor3 = style.color
	stripe.BorderSizePixel = 0
	UILib.corner(stripe, 3)
	stripe.Parent = toast

	-- Emoji badge.
	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.new(0, 34, 0, 34)
	badge.Position = UDim2.new(0, 16, 0.5, -17)
	badge.BackgroundTransparency = 1
	badge.Font = UILib.Font
	badge.TextScaled = true
	badge.Text = style.badge
	badge.Parent = toast

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, -64, 1, -10)
	text.Position = UDim2.new(0, 56, 0, 5)
	text.BackgroundTransparency = 1
	text.Font = UILib.Font
	text.TextScaled = true
	text.TextWrapped = true
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeColor3 = Color3.new(0, 0, 0)
	text.TextStrokeTransparency = 0.4
	text.Text = msg
	text.Parent = toast

	SoundBook.play(style.sound, UILib.playerGui())

	toast.Position = UDim2.new(-1, -40, 0, 0)
	TweenService:Create(toast, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
	}):Play()

	task.delay(4.5, function()
		local out = TweenService:Create(toast, TweenInfo.new(0.3), {
			Position = UDim2.new(-1, -60, 0, 0),
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
	holder.AnchorPoint = Vector2.new(0, 1)
	holder.Position = UDim2.new(0, 108, 1, -20)
	holder.Size = UDim2.new(0, 340, 0, 400)
	holder.Parent = gui
	UILib.autoScale(holder)

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 8)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Left
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = holder

	Remotes.Events.Notify.OnClientEvent:Connect(function(payload)
		if type(payload) == "table" and type(payload.msg) == "string" then
			Notifier.show(payload.msg, payload.kind)
		end
	end)
end

return Notifier
