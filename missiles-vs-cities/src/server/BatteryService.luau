-- Missile Battery: a small island beside each player island holding several
-- BIG silos. No aiming — one "BLOW UP" button rains a volley across random
-- parts of the target city. Big cooldown; upgradeable damage.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Layout = require(Shared.Layout)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)

local BatteryService = {}

local ctx
local rng = Random.new()

local function now()
	return os.clock()
end

local function notify(player, msg, kind)
	Remotes.Events.Notify:FireClient(player, { msg = msg, kind = kind or "info" })
end

local function announceBattery(player, target)
	Remotes.Events.Notify:FireAllClients({
		msg = "\u{1F680} " .. player.DisplayName .. " unleashed a MISSILE BATTERY on " .. target.DisplayName .. "!",
		kind = "bad",
	})
end

local SMOOTH_MATERIALS = {
	[Enum.Material.Neon] = true, [Enum.Material.Glass] = true,
	[Enum.Material.Metal] = true, [Enum.Material.DiamondPlate] = true,
}
local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	local mat = props.Material or Enum.Material.Plastic
	if mat == Enum.Material.SmoothPlastic then mat = Enum.Material.Plastic end
	local smooth = SMOOTH_MATERIALS[mat]
	local s = smooth and Enum.SurfaceType.Smooth or Enum.SurfaceType.Studs
	p.TopSurface = s; p.BottomSurface = s
	p.LeftSurface = s; p.RightSurface = s
	p.FrontSurface = s; p.BackSurface = s
	for k, v in pairs(props) do
		if k ~= "Parent" and k ~= "Material" then
			p[k] = v
		end
	end
	p.Material = mat
	p.Parent = props.Parent
	return p
end

-- Builds the little battery island (hidden until unlocked).
function BatteryService.buildIsland(slot)
	local c = Layout.batteryIslandCenter(slot.index)
	local folder = Instance.new("Folder")
	folder.Name = "BatteryIsland"
	folder.Parent = slot.folder
	folder:SetAttribute("Hidden", true)

	part({
		Name = "Base",
		Size = Vector3.new(70, 8, 60),
		Position = Vector3.new(c.X, -1, c.Z),
		Color = Color3.fromRGB(96, 96, 104),
		Material = Enum.Material.Concrete,
		Parent = folder,
	})
	part({
		Name = "Rim",
		Size = Vector3.new(82, 6, 72),
		Position = Vector3.new(c.X, -1.6, c.Z),
		Color = Color3.fromRGB(226, 200, 140),
		Material = Enum.Material.Sand,
		Parent = folder,
	})

	local launchPositions = {}
	local cols, rowsN = 3, 2
	for r = 0, rowsN - 1 do
		for cc = 0, cols - 1 do
			local sx = c.X - 18 + cc * 18
			local sz = c.Z - 10 + r * 20
			-- Big silo tube.
			part({
				Name = "BigSilo",
				Size = Vector3.new(7, 4, 7),
				Position = Vector3.new(sx, Config.GroundY + 2, sz),
				Color = Color3.fromRGB(60, 62, 68),
				Material = Enum.Material.DiamondPlate,
				Parent = folder,
			})
			local rocket = part({
				Name = "BigRocket",
				Size = Vector3.new(4, 12, 4),
				Position = Vector3.new(sx, Config.GroundY + 9, sz),
				Color = Color3.fromRGB(220, 80, 60),
				Material = Enum.Material.Metal,
				Parent = folder,
			})
			part({
				Name = "BigNose",
				Size = Vector3.new(2.6, 3, 2.6),
				Position = Vector3.new(sx, Config.GroundY + 16, sz),
				Color = Color3.fromRGB(250, 210, 90),
				Material = Enum.Material.Neon,
				Parent = folder,
			})
			launchPositions[#launchPositions + 1] = Vector3.new(sx, Config.GroundY + 16, sz)
		end
	end

	-- BLOW UP battery pad the owner steps on.
	local pad = part({
		Name = "BatteryPad",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 14, 14),
		CFrame = CFrame.new(c.X, Config.GroundY + 0.5, c.Z + 24) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(235, 60, 60),
		Material = Enum.Material.Neon,
		Parent = folder,
	})
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(18, 0, 7, 0)
	gui.StudsOffset = Vector3.new(0, 6, 0)
	gui.MaxDistance = 260
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 200, 200)
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Text = "\u{1F680} MISSILE BATTERY\nOpen the Attack menu to fire"
	label.Parent = gui
	gui.Parent = pad

	slot.batteryFolder = folder
	slot.batteryLaunchPositions = launchPositions
end

function BatteryService.showIsland(slot, visible)
	if not slot.batteryFolder then
		return
	end
	slot.batteryFolder.Parent = visible and slot.folder or nil
end

local function batteryDamage(profile)
	local level = profile.batteryLevel or 1
	return math.floor(Config.Battery.BaseDamage * Config.Battery.DamageGrowth ^ (level - 1))
end

local function impactBatteryMissile(attackerUserId, targetUserId, pos, damage, isLast)
	local target = Players:GetPlayerByUserId(targetUserId)
	local attacker = Players:GetPlayerByUserId(attackerUserId)
	if not target then
		return
	end
	local slot = ctx.Plot.getSlot(target)
	if not slot then
		return
	end
	if ctx.Defense and ctx.Defense.tryIntercept(slot, "missile", pos) then
		return
	end
	local worth, count, popLost = ctx.Plot.applyBlast(slot, pos, damage)
	if count > 0 and attacker then
		ctx.Economy.addCash(attacker, worth)
		local aProfile = ctx.Data.get(attacker)
		if aProfile then
			aProfile.stats.stolen += worth
		end
		ctx.Economy.pushState(attacker)
	end
	if isLast then
		notify(target, "\u{1F680} A MISSILE BATTERY volley hit your city!", "bad")
		ctx.Economy.pushState(target)
	end
end

local function onRequestBattery(player, targetUserId)
	if type(targetUserId) ~= "number" then
		return
	end
	local session = ctx.session[player]
	local profile = ctx.Data.get(player)
	local mySlot = ctx.Plot.getSlot(player)
	if not session or not profile or not mySlot then
		return
	end
	if not profile.batteryUnlocked then
		notify(player, "\u{1F680} Buy the Missile Battery first!", "bad")
		return
	end
	if now() < (session.batteryReadyAt or 0) then
		notify(player, "\u{1F680} Battery reloading! " .. NumberFormat.clock((session.batteryReadyAt or 0) - now()), "bad")
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == player then
		notify(player, "That player isn't here!", "bad")
		return
	end
	local targetSlot = ctx.Plot.getSlot(target)
	if not targetSlot or ctx.Plot.isImmune(targetSlot) then
		notify(player, "\u{1F6E1}\u{FE0F} That city is protected right now!", "bad")
		return
	end

	session.batteryReadyAt = now() + Config.Battery.Cooldown
	local damage = batteryDamage(profile)
	local launches = mySlot.batteryLaunchPositions or {}
	local minX, minZ, maxX, maxZ = Layout.plotBounds(targetSlot.index)

	for i = 1, Config.Battery.Volley do
		local from = launches[((i - 1) % #launches) + 1] or Layout.batteryIslandCenter(mySlot.index)
		-- Random spread across the enemy city (no aiming).
		local pos = Vector3.new(rng:NextNumber(minX, maxX), Layout.GroundY, rng:NextNumber(minZ, maxZ))
		local flight = Config.Rocket.FlightTime + rng:NextNumber(0, 2)
		Remotes.Events.MissileEvent:FireAllClients({
			kind = "rocket",
			from = from,
			to = pos,
			flight = flight,
			attacker = player.DisplayName,
			previewFor = (i == 1) and player.UserId or nil,
		})
		task.delay(flight, impactBatteryMissile, player.UserId, target.UserId, pos, damage, i == Config.Battery.Volley)
	end

	Remotes.Events.Alarm:FireClient(target, {
		kind = "battery",
		pos = Layout.plotCenter(targetSlot.index),
		eta = Config.Rocket.FlightTime,
	})
	announceBattery(player, target)
	ctx.Economy.pushState(player)
end

local function onUpgradeBattery(player)
	local profile = ctx.Data.get(player)
	if not profile or not profile.batteryUnlocked then
		return
	end
	local lvl = profile.batteryLevel or 1
	if lvl >= Config.Battery.MaxLevel then
		notify(player, "\u{1F680} Battery is max level!", "info")
		return
	end
	local cost = math.floor(Config.Battery.BaseUpgradeCost * Config.Battery.CostGrowth ^ (lvl - 1))
	if not ctx.Economy.trySpend(player, cost) then
		notify(player, "Battery upgrade costs \u{1F4B5} " .. NumberFormat.abbrev(cost) .. "!", "bad")
		return
	end
	profile.batteryLevel = lvl + 1
	notify(player, "\u{1F680} Missile Battery upgraded to Lv" .. profile.batteryLevel .. "!", "buy")
	ctx.Economy.pushState(player)
end

function BatteryService.init(context)
	ctx = context
	for _, slot in ipairs(ctx.World.slots) do
		BatteryService.buildIsland(slot)
		BatteryService.showIsland(slot, false)
	end
	Remotes.Events.RequestBattery.OnServerEvent:Connect(onRequestBattery)
	Remotes.Events.UpgradeBattery.OnServerEvent:Connect(onUpgradeBattery)
end

return BatteryService
