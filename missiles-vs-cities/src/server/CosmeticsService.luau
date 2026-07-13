-- Character shop cosmetics: speed/jump tiers, overhead titles, rainbow trail.
-- Purchases come through the ShopBuy remote (handled by EconomyService,
-- which calls buy() here); effects are applied on every character spawn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local CosmeticsService = {}

local ctx

local function notify(player, msg, kind)
	Remotes.Events.Notify:FireClient(player, { msg = msg, kind = kind or "info" })
end

local function titleById(id)
	for _, t in ipairs(Config.Character.Titles) do
		if t.id == id then
			return t
		end
	end
	return nil
end

function CosmeticsService.apply(player, character)
	local profile = ctx.Data.get(player)
	if not profile or not character then
		return
	end
	local cos = profile.cosmetics or {}
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if not humanoid then
		return
	end

	humanoid.WalkSpeed = 16 + (cos.speed or 0) * Config.Character.SpeedPerTier
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 50 + (cos.jump or 0) * Config.Character.JumpPerTier

	-- Overhead title.
	local head = character:FindFirstChild("Head")
	if head and cos.title and cos.title ~= "" then
		local old = head:FindFirstChild("MVC_Title")
		if old then
			old:Destroy()
		end
		local titleDef = titleById(cos.title)
		if titleDef then
			local gui = Instance.new("BillboardGui")
			gui.Name = "MVC_Title"
			gui.Size = UDim2.new(12, 0, 2.4, 0)
			gui.StudsOffset = Vector3.new(0, 2.4, 0)
			gui.AlwaysOnTop = true
			gui.MaxDistance = 200
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.TextColor3 = Color3.fromRGB(255, 215, 80)
			label.TextStrokeColor3 = Color3.new(0, 0, 0)
			label.TextStrokeTransparency = 0
			label.Text = titleDef.label
			label.Parent = gui
			gui.Parent = head
		end
	end

	-- Rainbow trail.
	if cos.trail then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp and not hrp:FindFirstChild("MVC_Trail") then
			local a0 = Instance.new("Attachment")
			a0.Position = Vector3.new(0, 1, 0)
			a0.Parent = hrp
			local a1 = Instance.new("Attachment")
			a1.Position = Vector3.new(0, -1, 0)
			a1.Parent = hrp
			local trail = Instance.new("Trail")
			trail.Name = "MVC_Trail"
			trail.Attachment0 = a0
			trail.Attachment1 = a1
			trail.Lifetime = 0.6
			trail.WidthScale = NumberSequence.new(1, 0)
			trail.Transparency = NumberSequence.new(0.2, 1)
			trail.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
				ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 200, 60)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 220, 90)),
				ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 160, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 90, 240)),
			})
			trail.Parent = hrp
		end
	end
end

local function reapply(player)
	if player.Character then
		CosmeticsService.apply(player, player.Character)
	end
end

-- Returns true if the itemId was a cosmetics purchase (handled here).
function CosmeticsService.buy(player, itemId)
	local profile = ctx.Data.get(player)
	if not profile then
		return false
	end
	profile.cosmetics = profile.cosmetics or { speed = 0, jump = 0, trail = false, title = "" }
	local cos = profile.cosmetics

	if itemId == "cos_speed" then
		local tier = (cos.speed or 0) + 1
		local cost = Config.Character.SpeedCosts[tier]
		if not cost then
			notify(player, "\u{1F45F} Speed is already maxed!", "info")
		elseif ctx.Economy.trySpendGems(player, cost) then
			cos.speed = tier
			reapply(player)
			notify(player, "\u{1F45F} Speed boost tier " .. tier .. " equipped!", "buy")
		else
			notify(player, "Need \u{1F48E} " .. cost .. " gems!", "bad")
		end
		return true
	elseif itemId == "cos_jump" then
		local tier = (cos.jump or 0) + 1
		local cost = Config.Character.JumpCosts[tier]
		if not cost then
			notify(player, "\u{1F998} Jump is already maxed!", "info")
		elseif ctx.Economy.trySpendGems(player, cost) then
			cos.jump = tier
			reapply(player)
			notify(player, "\u{1F998} Jump boost tier " .. tier .. " equipped!", "buy")
		else
			notify(player, "Need \u{1F48E} " .. cost .. " gems!", "bad")
		end
		return true
	elseif itemId == "cos_trail" then
		if cos.trail then
			notify(player, "\u{1F308} You already have the rainbow trail!", "info")
		elseif ctx.Economy.trySpendGems(player, Config.Character.TrailCost) then
			cos.trail = true
			reapply(player)
			notify(player, "\u{1F308} Rainbow trail equipped!", "buy")
		else
			notify(player, "Need \u{1F48E} " .. Config.Character.TrailCost .. " gems!", "bad")
		end
		return true
	elseif itemId:sub(1, 10) == "cos_title_" then
		local titleId = itemId:sub(11)
		local titleDef = titleById(titleId)
		if not titleDef then
			return true
		end
		if cos.title == titleId then
			notify(player, "That title is already equipped!", "info")
		elseif ctx.Economy.trySpendGems(player, titleDef.cost) then
			cos.title = titleId
			reapply(player)
			notify(player, "\u{1F3F7}\u{FE0F} Title equipped: " .. titleDef.label, "buy")
		else
			notify(player, "Need \u{1F48E} " .. titleDef.cost .. " gems!", "bad")
		end
		return true
	end
	return false
end

function CosmeticsService.init(context)
	ctx = context
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			task.wait(0.2)
			CosmeticsService.apply(player, character)
		end)
	end)
end

return CosmeticsService
