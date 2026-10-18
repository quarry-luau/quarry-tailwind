--!strict
-- How a tween runs: its length in seconds, its easing and an optional
-- delay. `transition` reads an element's CSS transition for one kind of
-- property.

local Bezier = require("./Bezier")
local Declarations = require("../Compiler/Declarations")

export type Timing = { duration: number, ease: Bezier.Easing, delay: number? }
export type Kind = "colors" | "opacity" | "transform" | "shadow" | "size"

local INSTANT: Timing = { duration = 0, ease = Bezier.linear }

local function covered(covers: Declarations.Covers, kind: Kind): boolean
	return if kind == "colors"
		then covers.colors
		elseif kind == "opacity" then covers.opacity
		elseif kind == "transform" then covers.transform
		elseif kind == "shadow" then covers.shadow
		else covers.size
end

-- The timing of the transition in `base` (an element's base declarations)
-- for `kind`; instant when it does not cover that kind.
local function transition(base: Declarations.Declarations, kind: Kind): Timing
	local covers, curve = base.transition, base.ease
	if covers == nil or curve == nil or not covered(covers, kind) then
		return INSTANT
	end
	return {
		duration = base.duration or 0,
		ease = Bezier.new(curve[1], curve[2], curve[3], curve[4]),
		delay = base.delay,
	}
end

return { transition = transition }
