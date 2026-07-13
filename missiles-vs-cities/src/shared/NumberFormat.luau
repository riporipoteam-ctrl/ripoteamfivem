-- Big-number formatting: 1.28M / 846T / 71.3Sx style plus full comma strings.

local NumberFormat = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "UDc", "DDc", "TDc" }

function NumberFormat.abbrev(n)
	n = math.floor(n + 0.5)
	if n < 0 then
		return "-" .. NumberFormat.abbrev(-n)
	end
	if n < 1000 then
		return tostring(n)
	end
	local idx = math.floor(math.log10(n) / 3)
	idx = math.min(idx, #SUFFIXES - 1)
	local scaled = n / 10 ^ (idx * 3)
	local txt
	if scaled >= 100 then
		txt = string.format("%.0f", scaled)
	elseif scaled >= 10 then
		txt = string.format("%.1f", scaled)
	else
		txt = string.format("%.2f", scaled)
	end
	txt = txt:gsub("%.0+$", ""):gsub("(%.%d-)0+$", "%1")
	return txt .. SUFFIXES[idx + 1]
end

function NumberFormat.commas(n)
	n = math.floor(n + 0.5)
	local neg = n < 0
	local s = string.format("%.0f", math.abs(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,")
	out = out:reverse():gsub("^,", "")
	return (neg and "-" or "") .. out
end

-- 1:35:03 style countdown text.
function NumberFormat.clock(sec)
	sec = math.max(0, math.floor(sec))
	local h = sec // 3600
	local m = (sec % 3600) // 60
	local s = sec % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

return NumberFormat
