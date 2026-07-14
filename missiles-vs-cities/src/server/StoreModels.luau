-- Shared loader for Creator Store assets: inserts, sanitizes (strips ALL
-- scripts/sounds), normalizes scale, caches templates. Everything pcall'd —
-- a broken id just means the caller falls back to part-built visuals.

local InsertService = game:GetService("InsertService")

local StoreModels = {}

local cache = {} -- [key] = { model, scale } | false (known-failed)

local function sanitize(model)
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("LuaSourceContainer") or obj:IsA("Sound")
			or obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
			obj:Destroy()
		end
	end
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = true
		end
	end
end

-- opts: { size = studs, byHeight = bool }
function StoreModels.get(key, ids, opts)
	if cache[key] ~= nil then
		return cache[key] or nil
	end
	for _, id in ipairs(ids or {}) do
		local ok, asset = pcall(function()
			return InsertService:LoadAsset(id)
		end)
		if ok and asset then
			local model = asset:FindFirstChildWhichIsA("Model")
			if not model then
				model = Instance.new("Model")
				for _, child in ipairs(asset:GetChildren()) do
					child.Parent = model
				end
			end
			sanitize(model)
			if #model:GetDescendants() > 0 then
				local okBB, bbSize = pcall(function()
					local _, size = model:GetBoundingBox()
					return size
				end)
				if okBB and bbSize and bbSize.Magnitude > 0.5 then
					local current = opts.byHeight and bbSize.Y or math.max(bbSize.X, bbSize.Z)
					local factor = math.clamp((opts.size or 10) / math.max(current, 0.5), 0.01, 50)
					local okScale = pcall(function()
						model:ScaleTo(factor)
					end)
					if okScale then
						model.Parent = nil
						cache[key] = { model = model, scale = factor }
						asset:Destroy()
						return cache[key]
					end
				end
			end
			asset:Destroy()
		end
	end
	warn("[MVC] Store asset unavailable for: " .. key .. " (using built-in visuals)")
	cache[key] = false
	return nil
end

return StoreModels
