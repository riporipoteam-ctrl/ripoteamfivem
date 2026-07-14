-- Chunky cartoon UI toolkit: rounded frames, thick black outlines,
-- bright colors, FredokaOne everywhere. All panels share this look.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundBook = require(Shared.SoundBook)

local UILib = {}

UILib.Font = Enum.Font.FredokaOne
UILib.Colors = {
	Green = Color3.fromRGB(88, 200, 60),
	DarkGreen = Color3.fromRGB(58, 160, 40),
	Red = Color3.fromRGB(235, 60, 60),
	Blue = Color3.fromRGB(60, 150, 240),
	LightBlue = Color3.fromRGB(120, 200, 250),
	Purple = Color3.fromRGB(150, 80, 220),
	Gold = Color3.fromRGB(250, 200, 60),
	Gray = Color3.fromRGB(120, 120, 128),
	DarkGray = Color3.fromRGB(70, 70, 78),
	Panel = Color3.fromRGB(44, 46, 56),
}

local player = Players.LocalPlayer

function UILib.playerGui()
	return player:WaitForChild("PlayerGui")
end

function UILib.screen(name, displayOrder)
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = displayOrder or 1
	gui.Parent = UILib.playerGui()
	return gui
end

function UILib.corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

function UILib.stroke(parent, thickness, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 3
	s.Color = color or Color3.new(0, 0, 0)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

function UILib.frame(props, parent)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = UILib.Colors.Panel
	for k, v in pairs(props) do
		f[k] = v
	end
	UILib.corner(f)
	UILib.stroke(f)
	f.Parent = parent
	return f
end

function UILib.text(props, parent)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = UILib.Font
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeColor3 = Color3.new(0, 0, 0)
	t.TextStrokeTransparency = 0
	for k, v in pairs(props) do
		t[k] = v
	end
	t.Parent = parent
	return t
end

function UILib.button(props, parent, onClick)
	local b = Instance.new("TextButton")
	b.BorderSizePixel = 0
	b.Font = UILib.Font
	b.TextScaled = true
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextStrokeColor3 = Color3.new(0, 0, 0)
	b.TextStrokeTransparency = 0
	b.AutoButtonColor = false
	b.BackgroundColor3 = UILib.Colors.Green
	for k, v in pairs(props) do
		b[k] = v
	end
	UILib.corner(b)
	local strokeObj = UILib.stroke(b)

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(215, 215, 215))
	gradient.Parent = b

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 6)
	padding.PaddingRight = UDim.new(0, 6)
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = b

	-- Hover feedback via the outline so runtime BackgroundColor3 changes stay intact.
	b.MouseEnter:Connect(function()
		TweenService:Create(strokeObj, TweenInfo.new(0.08), {
			Color = Color3.fromRGB(255, 255, 255),
		}):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(strokeObj, TweenInfo.new(0.08), { Color = Color3.new(0, 0, 0) }):Play()
	end)
	b.Activated:Connect(function()
		SoundBook.play("Click", UILib.playerGui())
		if onClick then
			onClick()
		end
	end)
	if parent then
		b.Parent = parent
	end
	return b
end

-- Standard panel with the red header bar + X close button from the screenshots.
function UILib.panel(name, title, size, displayOrder)
	local gui = UILib.screen(name, displayOrder or 10)
	gui.Enabled = false

	-- Whoosh whenever any panel opens.
	gui:GetPropertyChangedSignal("Enabled"):Connect(function()
		if gui.Enabled then
			SoundBook.play("PanelOpen", UILib.playerGui())
		end
	end)

	local frame = UILib.frame({
		Name = "Panel",
		Size = size,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
	}, gui)

	local header = UILib.frame({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 46),
		Position = UDim2.new(0, 0, 0, -23),
		BackgroundColor3 = UILib.Colors.Red,
	}, frame)

	UILib.text({
		Name = "Title",
		Size = UDim2.new(1, -70, 1, -10),
		Position = UDim2.new(0, 14, 0, 5),
		Text = title,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)

	UILib.button({
		Name = "Close",
		Size = UDim2.new(0, 38, 0, 34),
		Position = UDim2.new(1, -46, 0, 6),
		Text = "X",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		TextColor3 = UILib.Colors.Red,
	}, header, function()
		gui.Enabled = false
	end)

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Size = UDim2.new(1, -20, 1, -46)
	content.Position = UDim2.new(0, 10, 0, 32)
	content.Parent = frame

	return gui, content
end

return UILib
