-- Reads UI-kit image assets harvested by the SERVER (FXTemplates) from
-- ReplicatedStorage.UIKitImages. InsertService only works server-side, so the
-- client never loads assets itself — it just reads the results. Graceful:
-- if nothing was harvested, callers keep their drawn fallback icons.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local UIKit = {}

UIKit.ready = false
local images = {} -- lowercased name -> image id
local buttonImages = {}
local panelImages = {}

local function record(name, id)
	images[name] = id
	if name:find("button") or name:find("btn") then
		buttonImages[#buttonImages + 1] = { name = name, id = id }
	end
	if name:find("panel") or name:find("frame") or name:find("bg") or name:find("window") then
		panelImages[#panelImages + 1] = { name = name, id = id }
	end
end

function UIKit.load()
	if not Config.UseStoreUIKit then
		UIKit.ready = true
		return
	end
	local folder = ReplicatedStorage:WaitForChild("UIKitImages", 8)
	if folder then
		for _, v in ipairs(folder:GetChildren()) do
			if v:IsA("StringValue") then
				record(v.Name, v.Value)
			end
		end
		-- Late arrivals (server still harvesting).
		folder.ChildAdded:Connect(function(v)
			if v:IsA("StringValue") then
				record(v.Name, v.Value)
			end
		end)
	end
	UIKit.ready = true
end

-- First harvested image whose name contains any keyword.
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

function UIKit.button(colorHint)
	if #buttonImages == 0 then
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
	if #panelImages == 0 then
		return nil
	end
	return panelImages[1].id
end

return UIKit
