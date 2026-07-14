-- Deterministic world layout math, shared by server (to build the world)
-- and client (to aim cameras, popups and crosshairs) so nothing needs replicating.

local Config = require(script.Parent.Config)

local Layout = {}

Layout.GroundY = Config.GroundY

local HALF = Config.PlotSize / 2

-- Zone grid: 4 columns x 4 rows of 40-stud zones separated by 12-stud roads.
local COL_X = { -78, -26, 26, 78 }
local ROW_Z = { 104, 52, 0, -52 }

-- Each island also has a "town square" strip at the front (positive Z)
-- holding the spawn, shop stand, NPCs, leaderboard and rebirth shrine.
Layout.TownDepth = 60 -- extra island depth in front of the city grid

function Layout.plotCenter(plotIndex)
	local angle = math.rad(-54 + (plotIndex - 1) * 72)
	return Vector3.new(math.cos(angle) * Config.PlotDistance, 0, math.sin(angle) * Config.PlotDistance)
end

function Layout.zoneOffset(zoneIndex)
	local row = math.ceil(zoneIndex / 4)
	local col = ((zoneIndex - 1) % 4) + 1
	return Vector3.new(COL_X[col], 0, ROW_Z[row])
end

function Layout.zoneCenter(plotIndex, zoneIndex)
	local c = Layout.plotCenter(plotIndex)
	local o = Layout.zoneOffset(zoneIndex)
	return Vector3.new(c.X + o.X, Config.GroundY, c.Z + o.Z)
end

-- Buy/upgrade pad sits on the road directly in front of its zone.
function Layout.padPos(plotIndex, zoneIndex)
	return Layout.zoneCenter(plotIndex, zoneIndex) + Vector3.new(0, 0, 26)
end

function Layout.siloPos(plotIndex)
	local c = Layout.plotCenter(plotIndex)
	return Vector3.new(c.X, Config.GroundY, c.Z - 110)
end

function Layout.plotSpawn(plotIndex)
	local c = Layout.plotCenter(plotIndex)
	return Vector3.new(c.X, Config.GroundY + 4, c.Z + 152)
end

-- Road intersection waypoints (world space) that citizens walk between.
Layout.RoadXs = { -104, -52, 0, 52, 104 }
Layout.RoadZs = { 130, 78, 26, -26, -78 }

function Layout.intersection(plotIndex, ix, iz)
	local c = Layout.plotCenter(plotIndex)
	return Vector3.new(c.X + Layout.RoadXs[ix], Config.GroundY, c.Z + Layout.RoadZs[iz])
end

function Layout.plotBounds(plotIndex)
	local c = Layout.plotCenter(plotIndex)
	return c.X - HALF, c.Z - HALF, c.X + HALF, c.Z + HALF
end

function Layout.clampToPlot(plotIndex, pos)
	local minX, minZ, maxX, maxZ = Layout.plotBounds(plotIndex)
	return Vector3.new(
		math.clamp(pos.X, minX, maxX),
		Layout.GroundY,
		math.clamp(pos.Z, minZ, maxZ)
	)
end

-- Top-down camera used by the attack ("BLOW UP") view.
function Layout.attackCameraCFrame(plotIndex)
	local c = Layout.plotCenter(plotIndex)
	local eye = Vector3.new(c.X, 390, c.Z + 50)
	return CFrame.lookAt(eye, Vector3.new(c.X, Layout.GroundY, c.Z))
end

return Layout
