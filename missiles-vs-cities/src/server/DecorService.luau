-- Inserts real Roblox Creator Store models (trees, benches, lamps, fountain,
-- rocks, a car) onto every island, plus a community skybox. Everything is
-- pcall-guarded: if an asset fails to load (offline Studio, moderated id),
-- the game keeps its built-in part decorations instead.
--
-- SECURITY: every script inside inserted free models is destroyed before the
-- model touches the world.

local InsertService = game:GetService("InsertService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Layout = require(Shared.Layout)
local DecorSets = require(Shared.DecorSets)

local DecorService = {}

local templates = {} -- [category] = sanitized template Model or false

local function sanitize(model)
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("LuaSourceContainer") or obj:IsA("Sound") or obj:IsA("RemoteEvent")
			or obj:IsA("RemoteFunction") or obj:IsA("Fire") and obj.Size > 15 then
			obj:Destroy()
		end
	end
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = true
		end
	end
end

local function loadTemplate(category)
	if templates[category] ~= nil then
		return templates[category] or nil
	end
	for _, id in ipairs(DecorSets.Models[category] or {}) do
		local ok, asset = pcall(function()
			return InsertService:LoadAsset(id)
		end)
		if ok and asset then
			local model = asset:FindFirstChildWhichIsA("Model")
			if not model then
				-- Wrap loose parts in a Model.
				model = Instance.new("Model")
				for _, child in ipairs(asset:GetChildren()) do
					child.Parent = model
				end
			end
			sanitize(model)
			if #model:GetDescendants() > 0 then
				-- Normalize to the target size for this category.
				local okBB, bbCF, bbSize = pcall(function()
					local cf, size = model:GetBoundingBox()
					return cf, size
				end)
				if okBB and bbSize then
					local target = DecorSets.TargetSize[category] or 8
					local current = (category == "tree" or category == "lamp") and bbSize.Y
						or math.max(bbSize.X, bbSize.Z)
					if current > 0.5 then
						local scale = math.clamp(target / current, 0.02, 30)
						pcall(function()
							model:ScaleTo(scale)
						end)
					end
					model.Parent = nil
					templates[category] = model
					asset:Destroy()
					return model
				end
			end
			asset:Destroy()
		end
	end
	warn("[MVC] No Store model loaded for decor category: " .. category)
	templates[category] = false
	return nil
end

local function place(category, position, folder, faceTowards)
	local template = loadTemplate(category)
	if not template then
		return
	end
	local clone = template:Clone()
	clone.Name = "Decor_" .. category
	clone.Parent = folder

	local bbCF, bbSize = clone:GetBoundingBox()
	local pivotY = clone:GetPivot().Position.Y
	local feetOffset = pivotY - (bbCF.Position.Y - bbSize.Y / 2)
	local pos = Vector3.new(position.X, Config.GroundY + feetOffset, position.Z)
	if faceTowards then
		clone:PivotTo(CFrame.lookAt(pos, Vector3.new(faceTowards.X, pos.Y, faceTowards.Z)))
	else
		clone:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	end
end

local function decorateIsland(slot, folder)
	local c = Layout.plotCenter(slot.index)
	local half = Config.PlotSize / 2
	local townZ = c.Z + half

	-- Town square: fountain centerpiece, benches facing it, lamps, greenery.
	place("fountain", Vector3.new(c.X, 0, townZ + 40), folder)
	place("bench", Vector3.new(c.X - 22, 0, townZ + 32), folder, Vector3.new(c.X, 0, townZ + 40))
	place("bench", Vector3.new(c.X + 22, 0, townZ + 32), folder, Vector3.new(c.X, 0, townZ + 40))
	place("lamp", Vector3.new(c.X - 58, 0, townZ + 12), folder)
	place("lamp", Vector3.new(c.X + 58, 0, townZ + 12), folder)
	place("tree", Vector3.new(c.X - 122, 0, townZ + 48), folder)
	place("tree", Vector3.new(c.X + 122, 0, townZ + 50), folder)
	place("bush", Vector3.new(c.X - 100, 0, townZ + 52), folder)
	place("bush", Vector3.new(c.X + 100, 0, townZ + 52), folder)

	-- Island edges: trees, bushes, rocks along the fence line.
	place("tree", Vector3.new(c.X - 122, 0, c.Z - 20), folder)
	place("tree", Vector3.new(c.X + 122, 0, c.Z + 30), folder)
	place("bush", Vector3.new(c.X - 122, 0, c.Z + 60), folder)
	place("bush", Vector3.new(c.X + 122, 0, c.Z - 60), folder)
	place("rock", Vector3.new(c.X - 122, 0, c.Z - 120), folder)
	place("rock", Vector3.new(c.X + 122, 0, c.Z - 116), folder)

	-- A parked car at the roadside.
	place("car", Vector3.new(c.X + 58, 0, c.Z - 40), folder, Vector3.new(c.X + 58, 0, c.Z + 40))
end

local function applySky()
	for _, id in ipairs(DecorSets.Sky) do
		local ok, asset = pcall(function()
			return InsertService:LoadAsset(id)
		end)
		if ok and asset then
			sanitize(asset)
			local sky = asset:FindFirstChildWhichIsA("Sky", true)
			if sky then
				-- Replace any existing skybox.
				for _, old in ipairs(Lighting:GetChildren()) do
					if old:IsA("Sky") then
						old:Destroy()
					end
				end
				sky.Parent = Lighting
				asset:Destroy()
				return
			end
			asset:Destroy()
		end
	end
	warn("[MVC] No Store skybox loaded; keeping the default sky.")
end

function DecorService.init(ctx)
	if Config.UseStoreDecor == false then
		return
	end
	task.spawn(applySky)
	task.spawn(function()
		local folder = Instance.new("Folder")
		folder.Name = "StoreDecor"
		folder.Parent = workspace
		for _, slot in ipairs(ctx.World.slots) do
			decorateIsland(slot, folder)
			task.wait() -- spread the work out
		end
	end)
end

return DecorService
