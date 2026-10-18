--!strict
-- CSS `cubic-bezier(x1, y1, x2, y2)` timing functions: progress in [0, 1]
-- to eased progress. The curve's x is solved for the input with Newton's
-- method, falling back to bisection, as browsers do.

export type Easing = (progress: number) -> number

local NEWTON_STEPS = 8
local BISECTION_STEPS = 32
local EPSILON = 1e-6

type Polynomial = { a: number, b: number, c: number }

-- The coefficients of one axis of the curve through (0, 0), p1, p2, (1, 1).
local function polynomial(p1: number, p2: number): Polynomial
	local c = 3 * p1
	local b = 3 * (p2 - p1) - c
	return { a = 1 - c - b, b = b, c = c }
end

local function sample(axis: Polynomial, t: number): number
	return ((axis.a * t + axis.b) * t + axis.c) * t
end

local function slope(axis: Polynomial, t: number): number
	return (3 * axis.a * t + 2 * axis.b) * t + axis.c
end

local function newton(axis: Polynomial, x: number): number?
	local t = x
	for _ = 1, NEWTON_STEPS do
		local miss = sample(axis, t) - x
		local gradient = slope(axis, t)
		if math.abs(miss) < EPSILON then
			return t
		elseif math.abs(gradient) < EPSILON then
			return nil
		end
		t -= miss / gradient
	end
	return nil
end

local function bisect(axis: Polynomial, x: number): number
	local low, high, t = 0, 1, x
	for _ = 1, BISECTION_STEPS do
		local value = sample(axis, t)
		if math.abs(value - x) < EPSILON then
			return t
		elseif value < x then
			low = t
		else
			high = t
		end
		t = (low + high) / 2
	end
	return t
end

local function new(x1: number, y1: number, x2: number, y2: number): Easing
	local x, y = polynomial(x1, x2), polynomial(y1, y2)
	return function(progress: number): number
		if progress <= 0 then
			return 0
		elseif progress >= 1 then
			return 1
		end
		local t = newton(x, progress) or bisect(x, progress)
		return sample(y, t)
	end
end

local function linear(progress: number): number
	return math.clamp(progress, 0, 1)
end

return { new = new, linear = linear }
