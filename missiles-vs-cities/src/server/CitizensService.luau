-- Small citizen avatars (real R15 rigs, scaled down) that walk the road
-- network of every occupied island, following intersection-to-intersection
-- paths with walk animations.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Layout = require(Shared.Layout)

local CitizensService = {}

local CITIZENS_PER_ISLAND = 4
local WALK_ANIM = "rbxassetid://507777826" -- Roblox default R15 walk

local ctx
local rng = Random.new()
local folder
local citizens = {} -- [slotIndex] = { {model, alive}, ... }

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

		-- Random walk over the road intersection grid.
		local ix = rng:NextInteger(1, #Layout.RoadXs)
		local iz = rng:NextInteger(1, #Layout.RoadZs)
		while record.alive and model.Parent do
			-- Step to a random adjacent intersection.
			if rng:NextNumber() < 0.5 then
				ix = math.clamp(ix + (rng:NextNumber() < 0.5 and -1 or 1), 1, #Layout.RoadXs)
			else
				iz = math.clamp(iz + (rng:NextNumber() < 0.5 and -1 or 1), 1, #Layout.RoadZs)
			end
			local target = Layout.intersection(slotIndex, ix, iz)
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
	local spawnPos = Layout.intersection(slot.index, rng:NextInteger(1, #Layout.RoadXs), rng:NextInteger(1, #Layout.RoadZs))
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
	if not list then
		return
	end
	for _, record in ipairs(list) do
		record.alive = false
		record.model:Destroy()
	end
	citizens[slotIndex] = nil
end

function CitizensService.init(context)
	ctx = context
	folder = Instance.new("Folder")
	folder.Name = "Citizens"
	folder.Parent = workspace

	task.spawn(function()
		while true do
			task.wait(5)
			for _, slot in ipairs(ctx.Plot.slots()) do
				if slot.owner then
					local list = citizens[slot.index]
					if not list then
						list = {}
						citizens[slot.index] = list
					end
					-- Cull dead entries, top up to target population.
					for i = #list, 1, -1 do
						if not list[i].model.Parent then
							table.remove(list, i)
						end
					end
					if #list < CITIZENS_PER_ISLAND then
						local record = spawnCitizen(slot)
						if record then
							list[#list + 1] = record
						end
					end
				elseif citizens[slot.index] then
					clearIsland(slot.index)
				end
			end
		end
	end)
end

return CitizensService
