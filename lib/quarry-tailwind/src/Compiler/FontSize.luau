--!strict
-- The Roblox TextSize that draws text closest in width to Chrome at a CSS
-- size and weight (TextMetrics; within about 3%). TextSize is a whole
-- number of at most 100, so only past that is a UIScale needed (`scale`,
-- 1 otherwise): scaled text is snapped to the pixel grid again and comes
-- out narrower than the scale implies. Between calibrated sizes the size is
-- interpolated; an uncalibrated weight uses the nearest one.

local TextMetrics = require("./TextMetrics")

export type Family = "sans" | "mono"
export type Size = { textSize: number, scale: number }

type Sizes = { [number]: { number } }

local MAX_TEXT_SIZE = 100

local function nearestWeight(family: Family, weight: number): Sizes
	local weights: { [number]: Sizes } = TextMetrics[family]
	local best, distance = nil, math.huge
	for candidate, sizes in weights do
		if math.abs(candidate - weight) < distance then
			best, distance = sizes, math.abs(candidate - weight)
		end
	end
	return best or {}
end

-- The calibrated sizes either side of `size`.
local function around(sizes: Sizes, size: number): (number?, number?)
	local below, above = nil, nil
	for calibrated in sizes do
		if
			calibrated < size
			and (below == nil or calibrated > below)
		then
			below = calibrated
		elseif
			calibrated > size
			and (above == nil or calibrated < above)
		then
			above = calibrated
		end
	end
	return below, above
end

-- TextSize times scale, over the CSS size, at a calibrated size.
local function ratio(sizes: Sizes, size: number): number
	local pair = sizes[size]
	return pair[1] * pair[2] / size
end

-- The effective size (TextSize times scale) for `size`.
local function effective(sizes: Sizes, size: number): number
	local exact = sizes[size]
	if exact then
		return exact[1] * exact[2]
	end
	local below, above = around(sizes, size)
	if below and above then
		local t = (size - below) / (above - below)
		local low, high = ratio(sizes, below), ratio(sizes, above)
		return size * (low + (high - low) * t)
	end
	local nearest = below or above
	return if nearest then size * ratio(sizes, nearest) else size
end

local function resolve(family: Family, weight: number, size: number): Size
	local sizes = nearestWeight(family, weight)
	local exact = sizes[size]
	if exact and exact[1] < MAX_TEXT_SIZE then
		return { textSize = exact[1], scale = 1 }
	end
	local wanted = effective(sizes, size)
	if wanted <= MAX_TEXT_SIZE then
		return { textSize = math.max(1, math.round(wanted)), scale = 1 }
	end
	return { textSize = MAX_TEXT_SIZE, scale = wanted / MAX_TEXT_SIZE }
end

return { resolve = resolve }
