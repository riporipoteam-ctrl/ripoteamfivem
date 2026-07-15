-- Loads free Creator Store UI packs at runtime and harvests their real image
-- assets (icons, button/panel textures) so the GUI uses designed art instead
-- of code-drawn shapes. Everything is best-effort with graceful fallback: if a
-- pack fails to load or an image isn't found, the caller keeps its drawn look.
--
-- InsertService:LoadAsset works in Studio AND live for public free assets
-- (it does NOT need API Services enabled), so these load during playtests too.

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local UIKit = {}

UIKit.ready = false
local images = {} -- lowercased name -> image asset id (string)
local buttonImages = {} -- images whose name looks like a button
local panelImages = {} -- images whose name looks like a panel/frame

local function record(name, id)
	if not id or id == "" or id == "rbxassetid://0" then
		return
	end
	local lname = string.lower(name or "")
	images[lname] = id
	if lname:find("button") or lname:find("btn") then
		buttonImages[#buttonImages + 1] = { name = lname, id = id }
	end
	if lname:find("panel") or lname:find("frame") or lname:find("bg") or lname:find("window") then
		panelImages[#panelImages + 1] = { name = lname, id = id }
	end
end

local function harvest(root)
	for _, obj in ipairs(root:GetDescendants()) do
		if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			record(obj.Name, obj.Image)
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			record(obj.Name, obj.Texture)
		end
	end
end

function UIKit.load()
	if not Config.UseStoreUIKit then
		return
	end
	for _, packId in ipairs(Config.UIKitPacks or {}) do
		local ok, asset = pcall(function()
			return InsertService:LoadAsset(packId)
		end)
		if ok and asset then
			harvest(asset)
			asset:Destroy()
		end
	end
	UIKit.ready = true
end

-- Returns the first harvested image id whose name contains any keyword.
function UIKit.icon(keywords)
	if not Config.UseStoreUIKit then
		return nil
	end
	for _, kw in ipairs(keywords) do
		for name, id in pairs(images) do
			if name:find(kw, 1, true) then
				return id
			end
		end
	end
	return nil
end

-- Best-guess button texture, preferring one whose name hints the colour.
function UIKit.button(colorHint)
	if not Config.UseStoreUIKit or #buttonImages == 0 then
		return nil
	end
	if colorHint then
		for _, b in ipairs(buttonImages) do
			if b.name:find(colorHint, 1, true) then
				return b.id
			end
		end
	end
	return buttonImages[1].id
end

function UIKit.panel()
	if not Config.UseStoreUIKit or #panelImages == 0 then
		return nil
	end
	return panelImages[1].id
end

return UIKit
