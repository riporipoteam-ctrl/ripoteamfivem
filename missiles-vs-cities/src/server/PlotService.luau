-- Owns plot assignment and all zone state: buying/upgrading via step-on pads,
-- damage, destruction, rebuild timers and HP regen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Layout = require(Shared.Layout)
local BuildingDefs = require(Shared.BuildingDefs)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)

local PlotService = {}

local ctx
local slots
local playerSlot = {} -- [player] = slot
local touchDebounce = {} -- [player.UserId .. ":" .. zi] = last touch clock

local function now()
	return os.clock()
end

local function notify(player, msg, kind)
	Remotes.Events.Notify:FireClient(player, { msg = msg, kind = kind or "info" })
end

function PlotService.getSlot(player)
	return playerSlot[player]
end

function PlotService.slots()
	return slots
end

local function renderZone(slot, zi)
	local def = BuildingDefs.List[zi]
	local zone = slot.zones[zi]
	local center = Layout.zoneCenter(slot.index, zi)
	ctx.Visuals.render(slot.zoneData[zi].buildings, def, zone.level, slot.index, zi, center, zone.destroyed)
end

-- Locked areas look like flat sand; unlocked areas get grass + sidewalk.
local function setZoneGround(slot, zi, locked)
	local data = slot.zoneData[zi]
	if locked then
		data.plate.Color = Color3.fromRGB(226, 200, 140)
		data.plate.Material = Enum.Material.Sand
		data.sidewalk.Transparency = 1
	else
		data.plate.Color = Color3.fromRGB(116, 202, 94)
		data.plate.Material = Enum.Material.Grass
		data.sidewalk.Transparency = 0
	end
end

function PlotService.updatePad(slot, zi)
	local def = BuildingDefs.List[zi]
	local zone = slot.zones[zi]
	local data = slot.zoneData[zi]
	local label = data.padLabel
	local pad = data.pad

	local function hidePad()
		label.Text = ""
		pad.Transparency = 1
	end

	if not slot.owner then
		hidePad()
		return
	end
	local profile = ctx.Data.get(slot.owner)
	if not profile then
		hidePad()
		return
	end

	-- Island expansion: only the NEXT locked area shows an unlock pad.
	if zone.locked then
		if zi == (profile.unlocked or 1) + 1 then
			pad.Transparency = 0
			pad.Color = Color3.fromRGB(250, 200, 60)
			label.Text = "\u{1F513} UNLOCK NEW AREA\n\u{1F4B5} " .. NumberFormat.abbrev(BuildingDefs.unlockCost(def))
		else
			hidePad()
		end
		return
	end
	pad.Transparency = 0

	if zone.destroyed then
		local remaining = math.max(0, math.ceil(zone.repairAt - now()))
		label.Text = "\u{1F4A5} " .. def.name .. " destroyed!\nRebuilding " .. NumberFormat.clock(remaining)
		pad.Color = Color3.fromRGB(120, 120, 120)
	elseif zone.level <= 0 then
		label.Text = "\u{1F3D7}\u{FE0F} Buy " .. def.name .. "\n\u{1F4B5} " .. NumberFormat.abbrev(BuildingDefs.upgradeCost(def, 1))
		pad.Color = Color3.fromRGB(80, 235, 90)
	elseif zone.level >= Config.BuildingMaxLevel then
		label.Text = def.emoji .. " " .. def.name .. " Lv MAX"
		pad.Color = Color3.fromRGB(250, 200, 60)
	else
		local maxHp = BuildingDefs.maxHp(def, zone.level)
		local hpLine = ""
		if zone.hp < maxHp then
			hpLine = "\n\u{2764}\u{FE0F} " .. NumberFormat.commas(zone.hp) .. " / " .. NumberFormat.commas(maxHp) .. " HP"
		end
		label.Text = def.emoji .. " " .. def.name .. " Lv" .. zone.level
			.. "\n\u{2B06}\u{FE0F} Upgrade \u{1F4B5} " .. NumberFormat.abbrev(BuildingDefs.upgradeCost(def, zone.level + 1))
			.. hpLine
		pad.Color = Color3.fromRGB(80, 235, 90)
	end
end

local function onPadTouched(slot, zi, hit)
	local character = hit.Parent
	if not character then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if not player and character.Parent then
		player = Players:GetPlayerFromCharacter(character.Parent)
	end
	if not player or slot.owner ~= player then
		return
	end

	local dKey = player.UserId .. ":" .. zi
	if touchDebounce[dKey] and now() - touchDebounce[dKey] < 0.8 then
		return
	end
	touchDebounce[dKey] = now()

	local profile = ctx.Data.get(player)
	if not profile then
		return
	end
	local def = BuildingDefs.List[zi]
	local zone = slot.zones[zi]

	-- Unlock the next island area.
	if zone.locked then
		if zi ~= (profile.unlocked or 1) + 1 then
			return
		end
		local cost = BuildingDefs.unlockCost(def)
		if not ctx.Economy.trySpend(player, cost) then
			notify(player, "Unlocking this area costs \u{1F4B5} " .. NumberFormat.abbrev(cost) .. "!", "bad")
			return
		end
		profile.unlocked = zi
		zone.locked = false
		setZoneGround(slot, zi, false)
		PlotService.updatePad(slot, zi)
		if slot.zones[zi + 1] then
			PlotService.updatePad(slot, zi + 1)
		end
		notify(player, "\u{1F513} NEW AREA UNLOCKED! You can now build " .. def.name .. " here.", "victory")
		ctx.Economy.pushState(player)
		return
	end

	if zone.destroyed then
		notify(player, "\u{1F4A5} " .. def.name .. " is rebuilding, hang tight!", "bad")
		return
	end
	if zone.level >= Config.BuildingMaxLevel then
		return
	end

	local targetLevel = zone.level + 1
	local cost = BuildingDefs.upgradeCost(def, targetLevel)
	if not ctx.Economy.trySpend(player, cost) then
		notify(player, "Need \u{1F4B5} " .. NumberFormat.abbrev(cost) .. " for " .. def.name .. "!", "bad")
		return
	end

	zone.level = targetLevel
	zone.hp = BuildingDefs.maxHp(def, targetLevel)
	profile.buildings[def.id] = targetLevel
	renderZone(slot, zi)
	PlotService.updatePad(slot, zi)
	if targetLevel == 1 then
		notify(player, def.emoji .. " Built " .. def.name .. "!", "buy")
	else
		notify(player, def.emoji .. " " .. def.name .. " upgraded to Lv" .. targetLevel .. "!", "buy")
	end
	if ctx.Quests then
		ctx.Quests.onEvent(player, "upgrade", 1)
	end
	ctx.Economy.pushState(player)
end

local function onNukePadTouched(slot, hit)
	local character = hit.Parent
	if not character then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if not player or slot.owner ~= player then
		return
	end
	local dKey = player.UserId .. ":nuke"
	if touchDebounce[dKey] and now() - touchDebounce[dKey] < 1 then
		return
	end
	touchDebounce[dKey] = now()

	local profile = ctx.Data.get(player)
	if not profile then
		return
	end
	if profile.nukeIsland then
		notify(player, "\u{2622}\u{FE0F} You already own Nuke Access!", "info")
		return
	end
	if not ctx.Economy.trySpend(player, Config.Nuke.IslandCost) then
		notify(player, "Nuke Access costs \u{1F4B5} " .. NumberFormat.abbrev(Config.Nuke.IslandCost) .. "!", "bad")
		return
	end
	profile.nukeIsland = true
	notify(player, "\u{2622}\u{FE0F} NUKE ACCESS UNLOCKED! One nuke every 24 hours.", "victory")
	Remotes.Events.Notify:FireAllClients({
		msg = "\u{2622}\u{FE0F} " .. player.DisplayName .. " just bought NUKE ACCESS. Be afraid.",
		kind = "info",
	})
	ctx.Economy.pushState(player)
end

function PlotService.assign(player)
	local slot
	for _, s in ipairs(slots) do
		if not s.owner then
			slot = s
			break
		end
	end
	if not slot then
		player:Kick("Server is full (5 cities max). Please try another server!")
		return nil
	end

	local profile = ctx.Data.get(player)
	slot.owner = player
	slot.immuneUntil = now() + Config.JoinImmunity
	playerSlot[player] = slot

	-- Old saves may predate area unlocks: derive from owned buildings.
	local unlocked = profile.unlocked or 1
	for zi, def in ipairs(BuildingDefs.List) do
		local level = (profile.buildings and profile.buildings[def.id]) or 0
		if level > 0 and zi > unlocked then
			unlocked = zi
		end
	end
	profile.unlocked = math.clamp(unlocked, 1, #BuildingDefs.List)

	for zi, def in ipairs(BuildingDefs.List) do
		local level = (profile.buildings and profile.buildings[def.id]) or 0
		slot.zones[zi] = {
			level = level,
			hp = BuildingDefs.maxHp(def, math.max(level, 1)),
			destroyed = false,
			repairAt = 0,
			lastHitAt = 0,
			locked = zi > profile.unlocked,
		}
		setZoneGround(slot, zi, slot.zones[zi].locked)
		renderZone(slot, zi)
		PlotService.updatePad(slot, zi)
	end

	slot.bannerLabel.Text = "\u{1F3D9}\u{FE0F} " .. player.DisplayName
	PlotService.updateSilos(slot, profile.siloCount or 1)

	local function place(character)
		local hrp = character:WaitForChild("HumanoidRootPart", 8)
		if hrp and playerSlot[player] == slot then
			task.wait(0.15)
			character:PivotTo(CFrame.new(Layout.plotSpawn(slot.index)))
		end
	end
	slot.charConn = player.CharacterAdded:Connect(place)
	if player.Character then
		task.spawn(place, player.Character)
	end

	return slot
end

function PlotService.release(player)
	local slot = playerSlot[player]
	if not slot then
		return
	end
	if slot.charConn then
		slot.charConn:Disconnect()
		slot.charConn = nil
	end
	slot.owner = nil
	slot.bannerLabel.Text = "\u{1F3DD}\u{FE0F} Empty Plot"
	PlotService.updateSilos(slot, 1)
	for zi in ipairs(BuildingDefs.List) do
		slot.zones[zi] = { level = 0, hp = 0, destroyed = false, repairAt = 0, lastHitAt = 0, locked = true }
		setZoneGround(slot, zi, true)
		renderZone(slot, zi)
		PlotService.updatePad(slot, zi)
	end
	playerSlot[player] = nil
end

function PlotService.isImmune(slot)
	return slot.immuneUntil and now() < slot.immuneUntil
end

-- Sum of invested value across intact buildings (used for nuke payouts).
function PlotService.intactWorth(slot)
	local worth = 0
	for zi, def in ipairs(BuildingDefs.List) do
		local zone = slot.zones[zi]
		if zone.level > 0 and not zone.destroyed then
			worth += BuildingDefs.totalWorth(def, zone.level)
		end
	end
	return worth
end

function PlotService.cityWorth(slot)
	local worth = 0
	for zi, def in ipairs(BuildingDefs.List) do
		local zone = slot.zones[zi]
		if zone.level > 0 then
			worth += BuildingDefs.totalWorth(def, zone.level)
		end
	end
	return worth
end

function PlotService.destroyZone(slot, zi, repairAfter)
	local zone = slot.zones[zi]
	zone.destroyed = true
	zone.repairAt = now() + repairAfter
	renderZone(slot, zi)
	PlotService.updatePad(slot, zi)
end

-- Missile blast: damages every intact building within the radius.
-- Returns total worth destroyed and how many buildings fell.
function PlotService.applyBlast(slot, pos, damage)
	local worthDestroyed = 0
	local destroyedCount = 0
	for zi, def in ipairs(BuildingDefs.List) do
		local zone = slot.zones[zi]
		if zone.level > 0 and not zone.destroyed then
			local center = Layout.zoneCenter(slot.index, zi)
			local dx = center.X - pos.X
			local dz = center.Z - pos.Z
			if math.sqrt(dx * dx + dz * dz) <= Config.Rocket.BlastRadius then
				zone.hp -= damage
				zone.lastHitAt = now()
				if zone.hp <= 0 then
					worthDestroyed += BuildingDefs.totalWorth(def, zone.level)
					destroyedCount += 1
					PlotService.destroyZone(slot, zi, Config.MissileRepairTime)
				else
					PlotService.updatePad(slot, zi)
				end
			end
		end
	end
	return worthDestroyed, destroyedCount
end

-- Nuke: flattens the whole city, staggered rebuild, temporary immunity.
function PlotService.nukeSlot(slot)
	local worth = 0
	local delayStep = 0
	for zi, def in ipairs(BuildingDefs.List) do
		local zone = slot.zones[zi]
		if zone.level > 0 and not zone.destroyed then
			worth += BuildingDefs.totalWorth(def, zone.level)
			delayStep += 1
			PlotService.destroyZone(slot, zi, 60 + delayStep * 15)
		end
	end
	slot.immuneUntil = now() + Config.Nuke.ImmunityAfter
	return worth
end

-- Show/hide extra silo models to match how many the player owns.
function PlotService.updateSilos(slot, count)
	for i = 2, #slot.siloGroups do
		local group = slot.siloGroups[i]
		if i <= count then
			group.model.Parent = slot.folder
		else
			group.model.Parent = nil
		end
	end
end

-- Hide/show a silo's decorative rocket (during launches).
function PlotService.setSiloRocket(slot, siloIndex, visible)
	local group = slot.siloGroups[siloIndex]
	if not group then
		return
	end
	for _, p in ipairs(group.rocketParts) do
		p.Transparency = visible and 0 or 1
	end
end

-- Rebirth: wipe the city back to a single house (visuals + profile).
function PlotService.resetBuildings(player)
	local slot = playerSlot[player]
	local profile = ctx.Data.get(player)
	if not slot or not profile then
		return
	end
	profile.buildings = { house = 1 }
	-- Unlocked areas survive rebirth; only buildings reset.
	for zi, def in ipairs(BuildingDefs.List) do
		local level = (def.id == "house") and 1 or 0
		slot.zones[zi] = {
			level = level,
			hp = BuildingDefs.maxHp(def, math.max(level, 1)),
			destroyed = false,
			repairAt = 0,
			lastHitAt = 0,
			locked = zi > (profile.unlocked or 1),
		}
		setZoneGround(slot, zi, slot.zones[zi].locked)
		renderZone(slot, zi)
		PlotService.updatePad(slot, zi)
	end
end

-- Re-render every owned city (used after Store building models finish loading).
function PlotService.rerenderAll()
	for _, slot in ipairs(slots) do
		if slot.owner then
			for zi in ipairs(BuildingDefs.List) do
				renderZone(slot, zi)
				PlotService.updatePad(slot, zi)
			end
		end
	end
end

function PlotService.repairAll(slot)
	local repaired = 0
	for zi, def in ipairs(BuildingDefs.List) do
		local zone = slot.zones[zi]
		if zone.level > 0 and zone.destroyed then
			zone.destroyed = false
			zone.hp = BuildingDefs.maxHp(def, zone.level)
			renderZone(slot, zi)
			PlotService.updatePad(slot, zi)
			repaired += 1
		end
	end
	return repaired
end

local function maintenanceLoop()
	while true do
		task.wait(1)
		for _, slot in ipairs(slots) do
			if slot.owner then
				for zi, def in ipairs(BuildingDefs.List) do
					local zone = slot.zones[zi]
					if zone.destroyed then
						if now() >= zone.repairAt then
							zone.destroyed = false
							zone.hp = BuildingDefs.maxHp(def, zone.level)
							renderZone(slot, zi)
							PlotService.updatePad(slot, zi)
							notify(slot.owner, "\u{2705} " .. def.name .. " rebuilt!", "good")
						else
							PlotService.updatePad(slot, zi) -- live countdown text
						end
					elseif zone.level > 0 then
						local maxHp = BuildingDefs.maxHp(def, zone.level)
						if zone.hp < maxHp and now() - zone.lastHitAt > Config.HpRegenDelay then
							zone.hp = maxHp
							PlotService.updatePad(slot, zi)
						end
					end
				end
			end
		end
	end
end

function PlotService.init(context)
	ctx = context
	slots = ctx.World.slots

	for _, slot in ipairs(slots) do
		slot.zones = {}
		for zi in ipairs(BuildingDefs.List) do
			slot.zones[zi] = { level = 0, hp = 0, destroyed = false, repairAt = 0, lastHitAt = 0, locked = true }
			setZoneGround(slot, zi, true)
			PlotService.updatePad(slot, zi)
		end
		for zi in ipairs(BuildingDefs.List) do
			local pad = slot.zoneData[zi].pad
			pad.Touched:Connect(function(hit)
				onPadTouched(slot, zi, hit)
			end)
		end
	end

	for _, slot in ipairs(slots) do
		slot.nukePad.Touched:Connect(function(hit)
			onNukePadTouched(slot, hit)
		end)
	end

	task.spawn(maintenanceLoop)
end

return PlotService
