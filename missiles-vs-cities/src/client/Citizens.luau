-- Ambient little citizens wandering around active cities. Purely client-side
-- (zero network cost): a plot is considered "active" if it produced income
-- popups recently, plus your own plot.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Layout = require(Shared.Layout)
local Remotes = require(Shared.Remotes)

local Citizens = {}

local CITIZENS_PER_PLOT = 5
local WALK_SPEED = 5
local SKIN = Color3.fromRGB(255, 204, 148)
local SHIRTS = {
	Color3.fromRGB(235, 60, 60), Color3.fromRGB(60, 150, 240), Color3.fromRGB(88, 200, 60),
	Color3.fromRGB(250, 200, 60), Color3.fromRGB(190, 90, 240), Color3.fromRGB(255, 140, 60),
}

local rng = Random.new()
local lastPop = {} -- [plotIndex] = os.clock() of last income popup
local citizens = {} -- flat list of citizen records
local perPlot = {} -- [plotIndex] = count
local ctx

local function tinyPerson(parent)
	local model = Instance.new("Model")
	local shirt = SHIRTS[rng:NextInteger(1, #SHIRTS)]
	local pants = SHIRTS[rng:NextInteger(1, #SHIRTS)]

	local function p(size, color)
		local piece = Instance.new("Part")
		piece.Anchored = true
		piece.CanCollide = false
		piece.CanQuery = false
		piece.CanTouch = false
		piece.TopSurface = Enum.SurfaceType.Smooth
		piece.BottomSurface = Enum.SurfaceType.Smooth
		piece.Size = size
		piece.Color = color
		piece.Parent = model
		return piece
	end

	local body = p(Vector3.new(1, 1.1, 0.6), shirt)
	local head = p(Vector3.new(0.7, 0.7, 0.7), SKIN)
	local legs = p(Vector3.new(0.9, 0.8, 0.55), pants)
	model.PrimaryPart = body
	model.Parent = parent
	return model, body, head, legs
end

local function spawnCitizen(plotIndex)
	local center = Layout.plotCenter(plotIndex)
	local half = Config.PlotSize / 2 - 24
	local model, body, head, legs = tinyPerson(workspace)
	model.Name = "MVC_Citizen"

	local record = {
		plotIndex = plotIndex,
		model = model,
		body = body,
		head = head,
		legs = legs,
		pos = Vector3.new(center.X + rng:NextNumber(-half, half), Layout.GroundY, center.Z + rng:NextNumber(-half, half)),
		target = nil,
		phase = rng:NextNumber(0, math.pi * 2),
	}
	record.target = record.pos
	citizens[#citizens + 1] = record
	perPlot[plotIndex] = (perPlot[plotIndex] or 0) + 1
end

local function removeCitizensOf(plotIndex)
	for i = #citizens, 1, -1 do
		local record = citizens[i]
		if record.plotIndex == plotIndex then
			record.model:Destroy()
			table.remove(citizens, i)
		end
	end
	perPlot[plotIndex] = 0
end

local function isActive(plotIndex)
	local state = ctx.State.get()
	if state and state.plotIndex == plotIndex then
		return true
	end
	local t = lastPop[plotIndex]
	return t ~= nil and os.clock() - t < 12
end

function Citizens.init(context)
	ctx = context

	Remotes.Events.IncomePops.OnClientEvent:Connect(function(plotIndex)
		if type(plotIndex) == "number" then
			lastPop[plotIndex] = os.clock()
		end
	end)

	-- Population manager.
	task.spawn(function()
		while true do
			task.wait(4)
			for plotIndex = 1, Config.PlotCount do
				if isActive(plotIndex) then
					while (perPlot[plotIndex] or 0) < CITIZENS_PER_PLOT do
						spawnCitizen(plotIndex)
					end
				elseif (perPlot[plotIndex] or 0) > 0 then
					removeCitizensOf(plotIndex)
				end
			end
		end
	end)

	-- Movement: waddle between random points, with a little bob.
	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for _, c in ipairs(citizens) do
			local toTarget = c.target - c.pos
			toTarget = Vector3.new(toTarget.X, 0, toTarget.Z)
			if toTarget.Magnitude < 1.5 then
				local center = Layout.plotCenter(c.plotIndex)
				local half = Config.PlotSize / 2 - 24
				c.target = Vector3.new(
					center.X + rng:NextNumber(-half, half),
					Layout.GroundY,
					center.Z + rng:NextNumber(-half, half)
				)
			else
				c.pos += toTarget.Unit * math.min(WALK_SPEED * dt, toTarget.Magnitude)
			end
			local bob = math.abs(math.sin(now * 8 + c.phase)) * 0.22
			local look = CFrame.lookAt(c.pos, Vector3.new(c.target.X, c.pos.Y, c.target.Z))
			local waddle = CFrame.Angles(0, 0, math.sin(now * 8 + c.phase) * 0.08)
			c.legs.CFrame = look * waddle * CFrame.new(0, 0.4 + bob, 0)
			c.body.CFrame = look * waddle * CFrame.new(0, 1.35 + bob, 0)
			c.head.CFrame = look * waddle * CFrame.new(0, 2.25 + bob, 0)
		end
	end)
end

return Citizens
