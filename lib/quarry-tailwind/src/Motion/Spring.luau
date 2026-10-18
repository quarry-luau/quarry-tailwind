--!strict
-- motion's spring with `bounce: 0` (critically damped) over a duration, as
-- an easing: 1 - (1 + wt)e^(-wt), with w set so the spring has settled to
-- within 1% at the end, scaled so the easing ends at exactly 1.

local Bezier = require("./Bezier")

-- The wt at which (1 + wt)e^(-wt) is 0.01.
local SETTLED = 6.638

local function position(t: number): number
	return 1 - (1 + SETTLED * t) * math.exp(-SETTLED * t)
end

local END = position(1)

local critical: Bezier.Easing = function(progress: number): number
	return position(math.clamp(progress, 0, 1)) / END
end

return { critical = critical }
