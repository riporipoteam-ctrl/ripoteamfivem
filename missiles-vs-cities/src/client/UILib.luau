-- Chunky cartoon UI toolkit: rounded frames, thick black outlines,
-- bright colors, FredokaOne everywhere. All panels share this look.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundBook = require(Shared.SoundBook)

local UILib = {}

UILib.Font = Enum.Font.FredokaOne
UILib.TitleFont = Enum.Font.Arcade -- blocky pixel font for titles/captions
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
	c.CornerRadius = UDim.new(0, radius or 6) -- blockier, old-Roblox feel
	c.Parent = parent
	return c
end

-- Adds a UIScale that keeps UI a sensible size on phones, tablets, TVs.
-- Baselined to a ~900px-tall window; shrinks on small screens.
function UILib.autoScale(frame)
	local scaleObj = Instance.new("UIScale")
	scaleObj.Parent = frame
	local function update()
		local cam = workspace.CurrentCamera
		local vh = cam and cam.ViewportSize.Y or 900
		scaleObj.Scale = math.clamp(vh / 900, 0.55, 1.15)
	end
	update()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	end
	return scaleObj
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
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = b

	-- Chunky 3D bottom edge + stud dots, like the reference game's buttons.
	local edge = Instance.new("Frame")
	edge.Name = "Edge"
	edge.AnchorPoint = Vector2.new(0.5, 1)
	edge.Position = UDim2.new(0.5, 0, 1, 10)
	edge.Size = UDim2.new(1, 12, 0, 7)
	edge.BackgroundColor3 = Color3.new(0, 0, 0)
	edge.BackgroundTransparency = 0.65
	edge.BorderSizePixel = 0
	edge.ZIndex = b.ZIndex
	UILib.corner(edge, 6)
	edge.Parent = b

	if b.Size.Y.Offset >= 50 then
		for i = 1, 4 do
			local stud = Instance.new("Frame")
			stud.Size = UDim2.new(0, 8, 0, 8)
			stud.Position = UDim2.new((i - 0.5) / 4, -4, 0, 0)
			stud.BackgroundColor3 = Color3.new(1, 1, 1)
			stud.BackgroundTransparency = 0.82
			stud.BorderSizePixel = 0
			UILib.corner(stud, 4)
			stud.Parent = b
		end
	end

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

-- Flat cartoon icons drawn from UI shapes (no image assets, no emoji).
-- Returns a square Frame you size/position yourself.
function UILib.icon(kind, parent)
	local box = Instance.new("Frame")
	box.Name = "Icon_" .. kind
	box.BackgroundTransparency = 1

	local function shape(props)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		for k, v in pairs(props) do
			if k ~= "Round" and k ~= "Parent" then
				f[k] = v
			end
		end
		UILib.corner(f, props.Round or 3)
		f.Parent = props.Parent or box
		return f
	end

	if kind == "gift" then
		shape({ Size = UDim2.fromScale(0.72, 0.5), Position = UDim2.fromScale(0.5, 0.68), BackgroundColor3 = Color3.fromRGB(235, 60, 60) })
		shape({ Size = UDim2.fromScale(0.84, 0.18), Position = UDim2.fromScale(0.5, 0.4), BackgroundColor3 = Color3.fromRGB(255, 90, 90) })
		shape({ Size = UDim2.fromScale(0.16, 0.78), Position = UDim2.fromScale(0.5, 0.54), BackgroundColor3 = Color3.fromRGB(255, 220, 90) })
		shape({ Size = UDim2.fromScale(0.2, 0.16), Position = UDim2.fromScale(0.36, 0.24), BackgroundColor3 = Color3.fromRGB(255, 220, 90), Round = 8 })
		shape({ Size = UDim2.fromScale(0.2, 0.16), Position = UDim2.fromScale(0.64, 0.24), BackgroundColor3 = Color3.fromRGB(255, 220, 90), Round = 8 })
	elseif kind == "calendar" then
		shape({ Size = UDim2.fromScale(0.78, 0.7), Position = UDim2.fromScale(0.5, 0.6), BackgroundColor3 = Color3.fromRGB(245, 245, 250), Round = 5 })
		shape({ Size = UDim2.fromScale(0.78, 0.24), Position = UDim2.fromScale(0.5, 0.32), BackgroundColor3 = Color3.fromRGB(235, 60, 60), Round = 5 })
		for r = 0, 1 do
			for c = 0, 2 do
				shape({ Size = UDim2.fromScale(0.13, 0.1), Position = UDim2.fromScale(0.32 + c * 0.18, 0.56 + r * 0.18), BackgroundColor3 = Color3.fromRGB(160, 170, 190), Round = 2 })
			end
		end
	elseif kind == "cart" then
		shape({ Size = UDim2.fromScale(0.6, 0.38), Position = UDim2.fromScale(0.52, 0.46), BackgroundColor3 = Color3.fromRGB(235, 90, 100), Round = 5 })
		shape({ Size = UDim2.fromScale(0.5, 0.1), Position = UDim2.fromScale(0.52, 0.3), BackgroundColor3 = Color3.fromRGB(255, 130, 140), Round = 4 })
		local handle = shape({ Size = UDim2.fromScale(0.3, 0.08), Position = UDim2.fromScale(0.2, 0.32), BackgroundColor3 = Color3.fromRGB(120, 130, 150), Round = 4 })
		handle.Rotation = -35
		shape({ Size = UDim2.fromScale(0.16, 0.16), Position = UDim2.fromScale(0.36, 0.76), BackgroundColor3 = Color3.fromRGB(60, 65, 80), Round = 12 })
		shape({ Size = UDim2.fromScale(0.16, 0.16), Position = UDim2.fromScale(0.7, 0.76), BackgroundColor3 = Color3.fromRGB(60, 65, 80), Round = 12 })
	elseif kind == "bomb" then
		shape({ Size = UDim2.fromScale(0.6, 0.6), Position = UDim2.fromScale(0.46, 0.62), BackgroundColor3 = Color3.fromRGB(52, 56, 68), Round = 24 })
		shape({ Size = UDim2.fromScale(0.18, 0.14), Position = UDim2.fromScale(0.62, 0.3), BackgroundColor3 = Color3.fromRGB(120, 128, 142), Round = 3 })
		local fuse = shape({ Size = UDim2.fromScale(0.26, 0.07), Position = UDim2.fromScale(0.76, 0.22), BackgroundColor3 = Color3.fromRGB(200, 160, 90), Round = 4 })
		fuse.Rotation = -30
		shape({ Size = UDim2.fromScale(0.16, 0.16), Position = UDim2.fromScale(0.88, 0.14), BackgroundColor3 = Color3.fromRGB(255, 170, 40), Round = 12 })
		shape({ Size = UDim2.fromScale(0.14, 0.14), Position = UDim2.fromScale(0.34, 0.5), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.6, Round = 10 })
	elseif kind == "scroll" then
		shape({ Size = UDim2.fromScale(0.66, 0.74), Position = UDim2.fromScale(0.5, 0.54), BackgroundColor3 = Color3.fromRGB(245, 230, 190), Round = 5 })
		shape({ Size = UDim2.fromScale(0.74, 0.16), Position = UDim2.fromScale(0.5, 0.22), BackgroundColor3 = Color3.fromRGB(210, 180, 130), Round = 8 })
		for r = 0, 2 do
			shape({ Size = UDim2.fromScale(0.46, 0.06), Position = UDim2.fromScale(0.5, 0.46 + r * 0.16), BackgroundColor3 = Color3.fromRGB(170, 150, 110), Round = 3 })
		end
	elseif kind == "gem" then
		local outer = shape({ Size = UDim2.fromScale(0.58, 0.58), Position = UDim2.fromScale(0.5, 0.52), BackgroundColor3 = Color3.fromRGB(190, 90, 240), Round = 6 })
		outer.Rotation = 45
		local inner = shape({ Size = UDim2.fromScale(0.32, 0.32), Position = UDim2.fromScale(0.5, 0.52), BackgroundColor3 = Color3.fromRGB(225, 160, 255), Round = 4 })
		inner.Rotation = 45
	elseif kind == "admin" then
		-- Gold shield badge with a star.
		local shield = shape({ Size = UDim2.fromScale(0.66, 0.74), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(240, 190, 50), Round = 6 })
		shape({ Size = UDim2.fromScale(0.44, 0.5), Position = UDim2.fromScale(0.5, 0.46), BackgroundColor3 = Color3.fromRGB(255, 225, 120), Round = 5 })
		local star = Instance.new("TextLabel")
		star.AnchorPoint = Vector2.new(0.5, 0.5)
		star.Position = UDim2.fromScale(0.5, 0.48)
		star.Size = UDim2.fromScale(0.6, 0.6)
		star.BackgroundTransparency = 1
		star.Font = UILib.Font
		star.TextScaled = true
		star.Text = "\u{2605}"
		star.TextColor3 = Color3.fromRGB(180, 120, 20)
		star.Parent = box
		local _ = shield
	elseif kind == "jet" then
		local body = shape({ Size = UDim2.fromScale(0.2, 0.6), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(120, 140, 170), Round = 4 })
		shape({ Size = UDim2.fromScale(0.8, 0.16), Position = UDim2.fromScale(0.5, 0.52), BackgroundColor3 = Color3.fromRGB(150, 170, 200), Round = 3 })
		shape({ Size = UDim2.fromScale(0.34, 0.12), Position = UDim2.fromScale(0.5, 0.78), BackgroundColor3 = Color3.fromRGB(150, 170, 200), Round = 3 })
		local _ = body
	elseif kind == "shield" then
		shape({ Size = UDim2.fromScale(0.66, 0.74), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(90, 180, 255), Round = 6 })
		shape({ Size = UDim2.fromScale(0.4, 0.46), Position = UDim2.fromScale(0.5, 0.46), BackgroundColor3 = Color3.fromRGB(150, 210, 255), Round = 5 })
	elseif kind == "cash" then
		shape({ Size = UDim2.fromScale(0.82, 0.52), Position = UDim2.fromScale(0.5, 0.52), BackgroundColor3 = Color3.fromRGB(88, 190, 70), Round = 5 })
		shape({ Size = UDim2.fromScale(0.66, 0.36), Position = UDim2.fromScale(0.5, 0.52), BackgroundColor3 = Color3.fromRGB(120, 215, 95), Round = 4 })
		local dollar = Instance.new("TextLabel")
		dollar.AnchorPoint = Vector2.new(0.5, 0.5)
		dollar.Position = UDim2.fromScale(0.5, 0.52)
		dollar.Size = UDim2.fromScale(0.5, 0.44)
		dollar.BackgroundTransparency = 1
		dollar.Font = UILib.Font
		dollar.TextScaled = true
		dollar.Text = "$"
		dollar.TextColor3 = Color3.fromRGB(40, 110, 35)
		dollar.Parent = box
	end

	if parent then
		box.Parent = parent
	end
	return box
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
	UILib.autoScale(frame) -- keep panels usable on phones/tablets/TVs

	local header = UILib.frame({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 46),
		Position = UDim2.new(0, 0, 0, -23),
		BackgroundColor3 = UILib.Colors.Red,
	}, frame)

	UILib.text({
		Name = "Title",
		Size = UDim2.new(1, -70, 1, -14),
		Position = UDim2.new(0, 14, 0, 7),
		Text = title,
		Font = UILib.TitleFont,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)

	-- Stud dots along the header, like classic brick UI.
	for i = 1, 5 do
		local stud = Instance.new("Frame")
		stud.Size = UDim2.new(0, 7, 0, 7)
		stud.Position = UDim2.new(1, -60 - i * 14, 0, 4)
		stud.BackgroundColor3 = Color3.new(1, 1, 1)
		stud.BackgroundTransparency = 0.75
		stud.BorderSizePixel = 0
		UILib.corner(stud, 3)
		stud.Parent = header
	end

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
