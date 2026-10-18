--!strict
-- CSS's `linear()` easing with evenly spaced points: the output at a
-- progress is interpolated between the two points either side of it, as
-- the browser does.

local Bezier = require("./Bezier")

local function new(points: { number }): Bezier.Easing
	local segments = #points - 1
	return function(progress: number): number
		local position = math.clamp(progress, 0, 1) * segments
		local index = math.min(math.floor(position), segments - 1)
		local from, to = points[index + 1], points[index + 2]
		return from + (to - from) * (position - index)
	end
end

return { new = new }
