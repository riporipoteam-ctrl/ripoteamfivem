-- Small citizen avatars (real R15 rigs, scaled down) that walk the road
-- network of every occupied island, following intersection-to-intersection
-- paths with walk animations.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Layout = require(Shared.Layout)

local CitizensService = {}

local WALK_ANIM = "rbxassetid://507777826" -- Roblox default R15 walk
local MAX_CITIZENS = 12
local MAX_CARS = 6

local CAR_COLORS = {
	Color3.fromRGB(220, 60, 60), Color3.fromRGB(60, 110, 220), Color3.fromRGB(240, 200, 60),
	Color3.fromRGB(90, 90, 100), Color3.fromRGB(230, 230, 235), Color3.fromRGB(80, 180, 90),
}

local ctx
local rng = Random.new()
local folder
local carFolder
local citizens = {} -- [slotIndex] = { {model, alive}, ... }
local cars = {} -- [slotIndex] = { {model, alive}, ... }

-- Population/citizen/car counts scale with how many buildings the city has.
local function builtZones(slot)
	local n = 0
	for _, zone in pairs(slot.zones) do
		if zone.level > 0 and not zone.destroyed then
			n += 1
		end
	end
	return n
end

local function targetCitizens(slot)
	return math.clamp(2 + builtZones(slot), 2, MAX_CITIZENS)
end

local function targetCars(slot)
	local n = builtZones(slot)
	if n < 3 then
		return 0
	end
	return math.clamp(math.floor(n / 2), 1, MAX_CARS)
end

local SHIRT_COLORS = {
	Color3.fromRGB(235, 60, 60), Color3.fromRGB(60, 150, 240), Color3.fromRGB(88, 200, 60),
	Color3.fromRGB(250, 200, 60), Color3.fromRGB(190, 90, 240), Color3.fromRGB(255, 140, 60),
}

local function makeCitizenModel()
	local desc = Instance.new("HumanoidDescription")
	desc.HeightScale = 0.65
	desc.WidthScale = 0.7
	desc.HeadScale = 0.95
	local shirt = SHIRT_COLORS[rng:NextInteger(1, #SHIRT_COLORS)]
	local pants = SHIRT_COLORS[rng:NextInteger(1, #SHIRT_COLORS)]
	desc.TorsoColor = shirt
	desc.LeftArmColor = shirt
	desc.RightArmColor = shirt
	desc.LeftLegColor = pants
	desc.RightLegColor = pants
	desc.HeadColor = Color3.fromRGB(255, 204, 148)

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		return nil
	end
	return model
end

local function startWalking(record, slotIndex)
	task.spawn(function()
		local model = record.model
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		humanoid.WalkSpeed = 7

		-- Walk animation looped forever (citizens never stop strolling).
		pcall(function()
			local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
			local anim = Instance.new("Animation")
			anim.AnimationId = WALK_ANIM
			local track = animator:LoadAnimation(anim)
			track.Looped = true
			track:Play()
		end)

		-- Random walk over the UNLOCKED zone tiles only (the island grows
		-- tile by tile, so locked tiles are open ocean).
		while record.alive and model.Parent do
			local slot = ctx.Plot.slots()[slotIndex]
			local profile = slot and slot.owner and ctx.Data.get(slot.owner)
			local unlocked = profile and profile.unlocked or 1
			local zi = rng:NextInteger(1, math.max(unlocked, 1))
			local zc = Layout.zoneCenter(slotIndex, zi)
			local target = zc + Vector3.new(rng:NextNumber(-14, 14), 0, rng:NextNumber(-14, 14))
			humanoid:MoveTo(target)
			local reached = false
			local conn = humanoid.MoveToFinished:Once(function()
				reached = true
			end)
			local waited = 0
			while not reached and waited < 10 and record.alive do
				task.wait(0.25)
				waited += 0.25
			end
			conn:Disconnect()
			task.wait(rng:NextNumber(0.2, 1.2))
		end
	end)
end

local function spawnCitizen(slot)
	local model = makeCitizenModel()
	if not model then
		return nil
	end
	model.Name = "Citizen_" .. slot.index
	local profile = slot.owner and ctx.Data.get(slot.owner)
	local unlocked = profile and profile.unlocked or 1
	local spawnPos = Layout.zoneCenter(slot.index, rng:NextInteger(1, math.max(unlocked, 1)))
	model.Parent = folder
	model:PivotTo(CFrame.new(spawnPos + Vector3.new(0, 4, 0)))

	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp then
		pcall(function()
			hrp:SetNetworkOwner(nil)
		end)
	end

	local record = { model = model, alive = true }
	startWalking(record, slot.index)
	return record
end

local function clearIsland(slotIndex)
	local list = citizens[slotIndex]
	if list then
		for _, record in ipairs(list) do
			record.alive = false
			record.model:Destroy()
		end
		citizens[slotIndex] = nil
	end
	local clist = cars[slotIndex]
	if clist then
		for _, record in ipairs(clist) do
			record.alive = false
			record.model:Destroy()
		end
		cars[slotIndex] = nil
	end
end

-- Simple blocky car that drives the road grid.
local function makeCar()
	local model = Instance.new("Model")
	local color = CAR_COLORS[rng:NextInteger(1, #CAR_COLORS)]
	local function p(name, size, off, c)
		local piece = Instance.new("Part")
		piece.Name = name
		piece.Anchored = true
		piece.CanCollide = false
		piece.Size = size
		piece.Color = c
		piece.Material = Enum.Material.SmoothPlastic
		piece.Parent = model
		piece.CFrame = CFrame.new(off)
		return piece
	end
	local body = p("Body", Vector3.new(4, 1.6, 8), Vector3.new(0, 1.2, 0), color)
	p("Cabin", Vector3.new(3.4, 1.4, 4), Vector3.new(0, 2.5, -0.5), color)
	p("Glass", Vector3.new(3.5, 1.1, 4.1), Vector3.new(0, 2.6, -0.5), Color3.fromRGB(120, 180, 220))
	for _, wx in ipairs({ -1.8, 1.8 }) do
		for _, wz in ipairs({ -2.6, 2.6 }) do
			local w = p("Wheel", Vector3.new(0.7, 1.4, 1.4), Vector3.new(wx, 0.7, wz), Color3.fromRGB(30, 30, 30))
			w.Shape = Enum.PartType.Cylinder
			w.CFrame = CFrame.new(wx, 0.7, wz) * CFrame.Angles(0, 0, math.rad(90))
		end
	end
	model.PrimaryPart = body
	return model
end

local function driveCar(record, slotIndex)
	task.spawn(function()
		local model = record.model
		local pos = model:GetPivot().Position
		while record.alive and model.Parent do
			local slot = ctx.Plot.slots()[slotIndex]
			local profile = slot and slot.owner and ctx.Data.get(slot.owner)
			local unlocked = profile and profile.unlocked or 1
			local zi = rng:NextInteger(1, math.max(unlocked, 1))
			local target = Layout.zoneCenter(slotIndex, zi) + Vector3.new(0, 1.5, 0)
			local dist = (target - pos).Magnitude
			local speed = 22
			local dur = math.max(dist / speed, 0.2)
			local t0 = os.clock()
			local startPos = pos
			while record.alive and os.clock() - t0 < dur do
				local a = (os.clock() - t0) / dur
				local p = startPos:Lerp(target, a)
				model:PivotTo(CFrame.lookAt(p, target))
				task.wait()
			end
			pos = target
			task.wait(rng:NextNumber(0.1, 0.5))
		end
	end)
end

local function spawnCar(slot)
	local model = makeCar()
	model.Name = "Car_" .. slot.index
	model.Parent = carFolder
	local carProfile = slot.owner and ctx.Data.get(slot.owner)
	local carUnlocked = carProfile and carProfile.unlocked or 1
	local start = Layout.zoneCenter(slot.index, rng:NextInteger(1, math.max(carUnlocked, 1)))
	model:PivotTo(CFrame.new(start + Vector3.new(0, 1.5, 0)))
	local record = { model = model, alive = true }
	driveCar(record, slot.index)
	return record
end

function CitizensService.init(context)
	ctx = context
	folder = Instance.new("Folder")
	folder.Name = "Citizens"
	folder.Parent = workspace
	carFolder = Instance.new("Folder")
	carFolder.Name = "Cars"
	carFolder.Parent = workspace

	task.spawn(function()
		while true do
			task.wait(5)
			for _, slot in ipairs(ctx.Plot.slots()) do
				if slot.owner then
					-- Citizens scale with city size.
					local list = citizens[slot.index]
					if not list then
						list = {}
						citizens[slot.index] = list
					end
					for i = #list, 1, -1 do
						if not list[i].model.Parent then
							table.remove(list, i)
						end
					end
					local wantP = targetCitizens(slot)
					if #list < wantP then
						local record = spawnCitizen(slot)
						if record then
							list[#list + 1] = record
						end
					elseif #list > wantP then
						local rec = table.remove(list)
						if rec then
							rec.alive = false
							rec.model:Destroy()
						end
					end

					-- Cars appear once the city has a few buildings.
					local clist = cars[slot.index]
					if not clist then
						clist = {}
						cars[slot.index] = clist
					end
					for i = #clist, 1, -1 do
						if not clist[i].model.Parent then
							table.remove(clist, i)
						end
					end
					local wantC = targetCars(slot)
					if #clist < wantC then
						clist[#clist + 1] = spawnCar(slot)
					elseif #clist > wantC then
						local rec = table.remove(clist)
						if rec then
							rec.alive = false
							rec.model:Destroy()
						end
					end
				elseif citizens[slot.index] or cars[slot.index] then
					clearIsland(slot.index)
				end
			end
		end
	end)
end

return CitizensService
