-- Top-down attack view. Modes:
--   rocket / nuke : aim a crosshair (tap to place), then BLOW UP.
--   jet           : no aiming; choose BOMB CITY or BOMB SILOS.
--   battery       : no aiming; BLOW UP rains a random volley.
-- Works on PC, mobile and console (ScreenPointToRay handles the GUI inset).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Layout = require(Shared.Layout)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)
local UILib = require(script.Parent.UILib)

local AttackView = {}

local ctx
local player = Players.LocalPlayer

local function camera()
	return workspace.CurrentCamera
end

local gui
local nameLabel
local hintLabel
local fireButton
local altButton -- "Bomb Silos" in jet mode
local barrageButton
local isOpen = false
local mode = "rocket"
local useBarrage = false
local targets = {}
local targetIndex = 1
local crosshairPos = nil
local crosshair = nil
local inputConn = nil

local function needsAim()
	return mode == "rocket" or mode == "nuke"
end

local function destroyCrosshair()
	if crosshair then
		crosshair:Destroy()
		crosshair = nil
	end
end

local function placeCrosshair(pos)
	destroyCrosshair()
	crosshairPos = pos
	if not needsAim() then
		return
	end
	local model = Instance.new("Model")
	model.Name = "MVC_Crosshair"
	local ring = Instance.new("Part")
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.4, 20, 20)
	ring.CFrame = CFrame.new(pos + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = Color3.fromRGB(255, 40, 40)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.25
	ring.Parent = model
	local dot = Instance.new("Part")
	dot.Anchored = true
	dot.CanCollide = false
	dot.CanQuery = false
	dot.CanTouch = false
	dot.Shape = Enum.PartType.Ball
	dot.Size = Vector3.new(4, 4, 4)
	dot.Position = pos + Vector3.new(0, 2, 0)
	dot.Color = Color3.fromRGB(255, 40, 40)
	dot.Material = Enum.Material.Neon
	dot.Parent = model
	model.Parent = workspace
	crosshair = model
end

local function currentTarget()
	return targets[targetIndex]
end

local function focusTarget()
	local target = currentTarget()
	if not target then
		return
	end
	nameLabel.Text = (target.immune and "\u{1F6E1}\u{FE0F} " or "") .. target.name
	local center = Layout.plotCenter(target.plotIndex)
	placeCrosshair(Vector3.new(center.X, Layout.GroundY, center.Z))
	TweenService:Create(camera(), TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = Layout.attackCameraCFrame(target.plotIndex),
	}):Play()
end

local function cycle(direction)
	if #targets == 0 then
		return
	end
	targetIndex = ((targetIndex - 1 + direction) % #targets) + 1
	focusTarget()
end

local function updateButtons()
	local state = ctx.State.get()
	if not state then
		return
	end
	barrageButton.Visible = false
	altButton.Visible = false

	if mode == "nuke" then
		local remaining = ctx.State.remaining("nukeRemaining")
		fireButton.Text = remaining > 0 and ("\u{2622}\u{FE0F} " .. NumberFormat.clock(remaining)) or "\u{2622}\u{FE0F} NUKE"
		fireButton.BackgroundColor3 = UILib.Colors.Purple
	elseif mode == "jet" then
		local remaining = ctx.State.remaining("jetRemaining")
		fireButton.Text = remaining > 0 and ("\u{2708}\u{FE0F} " .. NumberFormat.clock(remaining)) or "\u{2708}\u{FE0F} BOMB CITY"
		fireButton.BackgroundColor3 = UILib.Colors.Blue
		altButton.Visible = true
		altButton.Text = "\u{1F680} BOMB SILOS"
	elseif mode == "battery" then
		local remaining = ctx.State.remaining("batteryRemaining")
		fireButton.Text = remaining > 0 and ("\u{1F680} " .. NumberFormat.clock(remaining)) or "\u{1F680} BLOW UP"
		fireButton.BackgroundColor3 = UILib.Colors.Red
	else -- rocket
		local remaining = ctx.State.remaining("rocketRemaining")
		fireButton.Text = remaining > 0 and ("\u{23F3} " .. NumberFormat.clock(remaining)) or ("BLOW UP x" .. (state.siloCount or 1))
		fireButton.BackgroundColor3 = UILib.Colors.Red
		local barrage = state.barrage or 0
		barrageButton.Visible = barrage > 0
		barrageButton.Text = (useBarrage and "\u{2705} " or "") .. "\u{1F680}x3 Barrage (" .. barrage .. ")"
	end
end

function AttackView.close()
	if not isOpen then
		return
	end
	isOpen = false
	gui.Enabled = false
	destroyCrosshair()
	if inputConn then
		inputConn:Disconnect()
		inputConn = nil
	end
	local cam = camera()
	cam.CameraType = Enum.CameraType.Custom
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		cam.CameraSubject = humanoid
	end
end

local function fire(jetMode)
	local target = currentTarget()
	local state = ctx.State.get()
	if not target or not state then
		return
	end
	if mode == "nuke" then
		if ctx.State.remaining("nukeRemaining") > 0 or not crosshairPos then
			return
		end
		Remotes.Events.RequestLaunch:FireServer(target.userId, crosshairPos.X, crosshairPos.Z, true, false)
	elseif mode == "jet" then
		if ctx.State.remaining("jetRemaining") > 0 then
			return
		end
		Remotes.Events.RequestJet:FireServer(target.userId, jetMode or "city")
	elseif mode == "battery" then
		if ctx.State.remaining("batteryRemaining") > 0 then
			return
		end
		Remotes.Events.RequestBattery:FireServer(target.userId)
	else
		if ctx.State.remaining("rocketRemaining") > 0 or not crosshairPos then
			return
		end
		Remotes.Events.RequestLaunch:FireServer(target.userId, crosshairPos.X, crosshairPos.Z, false, useBarrage)
	end
	useBarrage = false
	task.delay(0.4, AttackView.close)
end

local function onTap(input, gameProcessed)
	if gameProcessed or not isOpen or not needsAim() then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local target = currentTarget()
	if not target then
		return
	end
	-- ScreenPointToRay accounts for the top GUI inset, so the crosshair lands
	-- exactly under the tap on both PC and mobile.
	local ray = camera():ScreenPointToRay(input.Position.X, input.Position.Y)
	if math.abs(ray.Direction.Y) < 1e-4 then
		return
	end
	local t = (Layout.GroundY - ray.Origin.Y) / ray.Direction.Y
	if t <= 0 then
		return
	end
	local hit = ray.Origin + ray.Direction * t
	placeCrosshair(Layout.clampToPlot(target.plotIndex, hit))
end

function AttackView.open(openMode)
	local ok, result = pcall(function()
		return Remotes.Functions.GetTargets:InvokeServer()
	end)
	if not ok or type(result) ~= "table" or #result == 0 then
		ctx.Notifier.show("No other players to attack yet!", "info")
		return
	end
	targets = result
	targetIndex = 1
	mode = openMode or "rocket"
	useBarrage = false
	isOpen = true
	gui.Enabled = true

	hintLabel.Text = needsAim() and "Tap anywhere on their city to aim!"
		or (mode == "jet" and "Choose your jet target — no aiming needed!"
			or "No aiming — missiles rain across their whole city!")

	camera().CameraType = Enum.CameraType.Scriptable
	focusTarget()
	updateButtons()
	inputConn = UserInputService.InputBegan:Connect(onTap)
end

function AttackView.init(context)
	ctx = context
	gui = UILib.screen("MVC_AttackView", 20)
	gui.Enabled = false

	local banner = UILib.frame({
		Size = UDim2.new(0, 380, 0, 52),
		Position = UDim2.new(0.5, 0, 0, 18),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = UILib.Colors.Panel,
		BackgroundTransparency = 0.25,
	}, gui)

	UILib.button({
		Size = UDim2.new(0, 54, 0, 40),
		Position = UDim2.new(0, 6, 0, 6),
		Text = "\u{25C0}\u{25C0}",
		BackgroundColor3 = UILib.Colors.LightBlue,
	}, banner, function()
		cycle(-1)
	end)

	nameLabel = UILib.text({
		Size = UDim2.new(1, -132, 1, -12),
		Position = UDim2.new(0, 66, 0, 6),
		Text = "",
	}, banner)

	UILib.button({
		Size = UDim2.new(0, 54, 0, 40),
		Position = UDim2.new(1, -60, 0, 6),
		Text = "\u{25B6}\u{25B6}",
		BackgroundColor3 = UILib.Colors.LightBlue,
	}, banner, function()
		cycle(1)
	end)

	hintLabel = UILib.text({
		Size = UDim2.new(0, 460, 0, 24),
		Position = UDim2.new(0.5, 0, 0, 74),
		AnchorPoint = Vector2.new(0.5, 0),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 230, 160),
	}, gui)

	fireButton = UILib.button({
		Size = UDim2.new(0, 300, 0, 74),
		Position = UDim2.new(0.5, 0, 1, -170),
		AnchorPoint = Vector2.new(0.5, 0),
		Text = "BLOW UP",
		BackgroundColor3 = UILib.Colors.Red,
	}, gui, function()
		fire("city")
	end)

	altButton = UILib.button({
		Size = UDim2.new(0, 260, 0, 50),
		Position = UDim2.new(0.5, 0, 1, -232),
		AnchorPoint = Vector2.new(0.5, 0),
		Text = "\u{1F680} BOMB SILOS",
		BackgroundColor3 = UILib.Colors.Purple,
		Visible = false,
	}, gui, function()
		fire("silos")
	end)

	barrageButton = UILib.button({
		Size = UDim2.new(0, 240, 0, 44),
		Position = UDim2.new(0.5, 0, 1, -232),
		AnchorPoint = Vector2.new(0.5, 0),
		Text = "",
		BackgroundColor3 = UILib.Colors.Purple,
		Visible = false,
	}, gui, function()
		useBarrage = not useBarrage
		updateButtons()
	end)

	UILib.button({
		Size = UDim2.new(0, 200, 0, 50),
		Position = UDim2.new(0.5, 0, 1, -84),
		AnchorPoint = Vector2.new(0.5, 0),
		Text = "CANCEL",
		BackgroundColor3 = UILib.Colors.Gray,
	}, gui, AttackView.close)

	task.spawn(function()
		while true do
			task.wait(0.5)
			if isOpen then
				updateButtons()
			end
		end
	end)

	ctx.State.changed.Event:Connect(function()
		if isOpen then
			updateButtons()
		end
	end)
end

return AttackView
