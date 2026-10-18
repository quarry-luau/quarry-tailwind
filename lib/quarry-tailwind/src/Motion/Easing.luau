--!strict
-- The Roblox easing closest to a CSS cubic-bezier curve, for the style
-- engine's transitions, which take only Roblox easings. Each curve is
-- compared with every style and direction at 99 points and the one with the
-- smallest largest difference wins: Tailwind's ease-out curves come within
-- 4%, its default ease-in-out within 18% (about a frame of a 150 ms colour
-- change). Results are cached.

local TweenService = game:GetService("TweenService")

local Bezier = require("./Bezier")

export type Nearest = {
	style: Enum.EasingStyle,
	direction: Enum.EasingDirection,
}

local SAMPLES = 99
local SKIPPED: { [Enum.EasingStyle]: boolean } = {
	[Enum.EasingStyle.Back] = true,
	[Enum.EasingStyle.Bounce] = true,
	[Enum.EasingStyle.Elastic] = true,
}

local cache: { [string]: Nearest } = {}

-- The largest difference between `ease` and a Roblox easing.
local function distance(
	ease: Bezier.Easing,
	style: Enum.EasingStyle,
	direction: Enum.EasingDirection
): number
	local worst = 0
	for index = 1, SAMPLES do
		local x = index / (SAMPLES + 1)
		local roblox = TweenService:GetValue(x, style, direction)
		worst = math.max(worst, math.abs(roblox - ease(x)))
	end
	return worst
end

local function search(ease: Bezier.Easing): Nearest
	local best: Nearest = {
		style = Enum.EasingStyle.Linear,
		direction = Enum.EasingDirection.Out,
	}
	local bestDistance = math.huge
	for _, style in Enum.EasingStyle:GetEnumItems() do
		for _, direction in Enum.EasingDirection:GetEnumItems() do
			local miss = if SKIPPED[style]
				then math.huge
				else distance(ease, style, direction)
			if miss < bestDistance then
				best = { style = style, direction = direction }
				bestDistance = miss
			end
		end
	end
	return best
end

local function nearest(curve: { number }): Nearest
	local key = table.concat(curve, ",")
	local found = cache[key]
		or search(Bezier.new(curve[1], curve[2], curve[3], curve[4]))
	cache[key] = found
	return found
end

-- A TweenInfo for `duration` seconds along `curve`, after `delay`.
local function tweenInfo(
	duration: number,
	curve: { number },
	delay: number
): TweenInfo
	local closest = nearest(curve)
	return TweenInfo.new(
		duration,
		closest.style,
		closest.direction,
		0,
		false,
		delay
	)
end

return { tweenInfo = tweenInfo }
