-- Deterministic world layout math, shared by server (to build the world)
-- and client (to aim cameras, popups and crosshairs) so nothing needs replicating.

local Config = require(script.Parent.Config)

local Layout = {}

Layout.GroundY = Config.GroundY

local HALF = Config.PlotSize / 2

-- Zone grid: 4 columns x 3 rows of 40-stud zones separated by 12-stud roads.
local COL_X = { -78, -26, 26, 78 }
local ROW_Z = { 78, 26, -26 }

Layout.NukeIslandCenter = Vector3.new(0, 0, -880)
Layout.NukeIslandSize = 150

function Layout.plotCenter(plotIndex)
	-- Plots sit on a circle around the lobby, leaving due north clear
	-- for the bridge out to Nuke Island.
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
	return Vector3.new(c.X, Config.GroundY, c.Z - 84)
end

function Layout.plotSpawn(plotIndex)
	local c = Layout.plotCenter(plotIndex)
	return Vector3.new(c.X, Config.GroundY + 4, c.Z + 103)
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
	local eye = Vector3.new(c.X, 330, c.Z + 40)
	return CFrame.lookAt(eye, Vector3.new(c.X, Layout.GroundY, c.Z))
end

return Layout
