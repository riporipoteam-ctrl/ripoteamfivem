-- Global "Richest Cities of All Time" leaderboard: an OrderedDataStore
-- keeps the top city worths ever seen, displayed on a big board in the lobby.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local NumberFormat = require(Shared.NumberFormat)

local LeaderboardService = {}

local ctx
local store = nil
local rowLabels = {}
local nameCache = {}

-- OrderedDataStores only take integers up to ~9e18; clamp huge worths.
local MAX_STORE = 9e15

do
	local ok, result = pcall(function()
		return DataStoreService:GetOrderedDataStore("MVC_TopWorth_v1")
	end)
	if ok then
		store = result
	else
		warn("[MVC] Leaderboard store unavailable: " .. tostring(result))
	end
end

local function buildBoard()
	local base = Vector3.new(0, Config.GroundY, -42)
	local board = Instance.new("Part")
	board.Name = "Leaderboard"
	board.Anchored = true
	board.Size = Vector3.new(22, 14, 1.5)
	board.Position = base + Vector3.new(0, 8, 0)
	board.Color = Color3.fromRGB(44, 46, 56)
	board.Parent = workspace

	for _, off in ipairs({ Vector3.new(-9, 0, 0), Vector3.new(9, 0, 0) }) do
		local leg = Instance.new("Part")
		leg.Anchored = true
		leg.Size = Vector3.new(1.2, 8, 1.2)
		leg.Position = base + off + Vector3.new(0, 2, 0)
		leg.Color = Color3.fromRGB(120, 120, 128)
		leg.Parent = workspace
	end

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(440, 280)
	gui.Parent = board

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 42)
	title.BackgroundColor3 = Color3.fromRGB(235, 60, 60)
	title.BorderSizePixel = 0
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextStrokeColor3 = Color3.new(0, 0, 0)
	title.TextStrokeTransparency = 0
	title.Text = "\u{1F3C6} RICHEST CITIES OF ALL TIME \u{1F3C6}"
	title.Parent = gui

	for i = 1, 10 do
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, -16, 0, 22)
		row.Position = UDim2.new(0, 8, 0, 44 + (i - 1) * 23)
		row.BackgroundTransparency = 1
		row.Font = Enum.Font.FredokaOne
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = i <= 3 and Color3.fromRGB(255, 215, 80) or Color3.new(1, 1, 1)
		row.TextStrokeColor3 = Color3.new(0, 0, 0)
		row.TextStrokeTransparency = 0
		row.Text = i .. ". ..."
		row.Parent = gui
		rowLabels[i] = row
	end
end

local function playerName(userId)
	if nameCache[userId] then
		return nameCache[userId]
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	nameCache[userId] = ok and name or ("Player " .. userId)
	return nameCache[userId]
end

local function submitScores()
	if not store then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local slot = ctx.Plot.getSlot(player)
		if slot then
			local worth = math.floor(math.min(ctx.Plot.cityWorth(slot), MAX_STORE))
			if worth > 0 then
				pcall(function()
					store:UpdateAsync(tostring(player.UserId), function(old)
						if old and old >= worth then
							return old
						end
						return worth
					end)
				end)
			end
		end
	end
end

local function refreshBoard()
	if not store then
		for i = 1, 10 do
			rowLabels[i].Text = i .. ". (enable API access to activate)"
		end
		return
	end
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, 10)
	end)
	if not ok then
		return
	end
	local top = pages:GetCurrentPage()
	for i = 1, 10 do
		local entry = top[i]
		if entry then
			rowLabels[i].Text = i .. ". " .. playerName(tonumber(entry.key)) .. " — \u{1F4B5} "
				.. NumberFormat.abbrev(entry.value)
		else
			rowLabels[i].Text = i .. ". ---"
		end
	end
end

function LeaderboardService.init(context)
	ctx = context
	buildBoard()
	task.spawn(function()
		while true do
			submitScores()
			refreshBoard()
			task.wait(90)
		end
	end)
end

return LeaderboardService
