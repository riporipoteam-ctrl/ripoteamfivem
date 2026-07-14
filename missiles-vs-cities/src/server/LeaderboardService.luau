-- Global "Richest Cities of All Time" leaderboard (OrderedDataStore),
-- displayed on a board in EVERY island's town square.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local NumberFormat = require(Shared.NumberFormat)

local LeaderboardService = {}

local ctx
local store = nil
local boards = {} -- array of { rows = {TextLabel x10} }
local nameCache = {}

local MAX_STORE = 9e15 -- OrderedDataStore integer ceiling safety

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

local function buildBoard(pos)
	local board = Instance.new("Part")
	board.Name = "Leaderboard"
	board.Anchored = true
	board.Size = Vector3.new(20, 12, 1.4)
	board.Position = pos + Vector3.new(0, 7, 0)
	board.Color = Color3.fromRGB(38, 40, 50)
	board.Material = Enum.Material.SmoothPlastic
	board.Parent = workspace

	for _, off in ipairs({ Vector3.new(-8, 0, 0), Vector3.new(8, 0, 0) }) do
		local leg = Instance.new("Part")
		leg.Anchored = true
		leg.Size = Vector3.new(1, 7, 1)
		leg.Position = pos + off + Vector3.new(0, 1.5, 0)
		leg.Color = Color3.fromRGB(110, 110, 118)
		leg.Material = Enum.Material.Metal
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

	local rows = {}
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
		rows[i] = row
	end
	boards[#boards + 1] = { rows = rows }
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

local function setAllRows(i, text)
	for _, board in ipairs(boards) do
		board.rows[i].Text = text
	end
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

local function refreshBoards()
	if not store then
		for i = 1, 10 do
			setAllRows(i, i .. ". (publish + enable API access)")
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
			setAllRows(i, i .. ". " .. playerName(tonumber(entry.key)) .. " — \u{1F4B5} " .. NumberFormat.abbrev(entry.value))
		else
			setAllRows(i, i .. ". ---")
		end
	end
end

function LeaderboardService.init(context)
	ctx = context
	for _, slot in ipairs(ctx.World.slots) do
		buildBoard(slot.boardPos)
	end
	task.spawn(function()
		while true do
			submitScores()
			refreshBoards()
			task.wait(90)
		end
	end)
end

return LeaderboardService
