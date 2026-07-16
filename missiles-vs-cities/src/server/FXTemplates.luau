-- Loads Store models used by flight/weapon FX (silo rockets, nuke, planes)
-- into ReplicatedStorage.FXModels so CLIENTS can clone them, and harvests the
-- UI-kit image assets into ReplicatedStorage.UIKitImages (InsertService only
-- works on the server, so the client reads the results from here).

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local DecorSets = require(Shared.DecorSets)
local StoreModels = require(script.Parent.StoreModels)

local FXTemplates = {}

local MODEL_DEFS = {
	{ key = "SiloRocket", ids = DecorSets.FX.rocket, size = 18, byHeight = true },
	{ key = "NukeRocket", ids = DecorSets.FX.nuke, size = 26, byHeight = true },
	{ key = "Cropduster", ids = DecorSets.FX.cropduster, size = 16 },
	{ key = "Jet", ids = DecorSets.FX.jet, size = 14 },
}

local function loadModels()
	local folder = Instance.new("Folder")
	folder.Name = "FXModels"
	folder.Parent = ReplicatedStorage
	for _, d in ipairs(MODEL_DEFS) do
		local entry = StoreModels.get("fx_" .. d.key, d.ids, { size = d.size, byHeight = d.byHeight })
		if entry then
			local clone = entry.model:Clone()
			clone.Name = d.key
			clone:SetAttribute("BaseScale", entry.scale)
			if not clone.PrimaryPart then
				clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart", true)
			end
			clone.Parent = folder
		end
	end
end

local function harvestUIKit()
	if not Config.UseStoreUIKit then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "UIKitImages"
	folder.Parent = ReplicatedStorage
	local seen = {}
	local function record(name, image)
		if not image or image == "" then
			return
		end
		local lname = string.lower(name or "img")
		if seen[lname] then
			return
		end
		seen[lname] = true
		local v = Instance.new("StringValue")
		v.Name = lname
		v.Value = image
		v.Parent = folder
	end
	for _, packId in ipairs(Config.UIKitPacks or {}) do
		local ok, asset = pcall(function()
			return InsertService:LoadAsset(packId)
		end)
		if ok and asset then
			for _, obj in ipairs(asset:GetDescendants()) do
				if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
					record(obj.Name, obj.Image)
				elseif obj:IsA("Decal") or obj:IsA("Texture") then
					record(obj.Name, obj.Texture)
				end
			end
			asset:Destroy()
		end
	end
end

function FXTemplates.init()
	loadModels()
	harvestUIKit()
end

return FXTemplates
