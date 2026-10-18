--!strict
-- Fills and gradients: `bg-primary`, `bg-black/50`, `bg-[#fb5c49]`,
-- `bg-linear-to-r from-success from-80% to-info`.

local Declarations = require("../Declarations")
local Registry = require("../Registry")
local Theme = require("../../Theme")
local Values = require("../Values")

type Declarations = Declarations.Declarations

local ANGLES: { [string]: number } =
	{ ["linear-to-r"] = 0, ["linear-to-b"] = 90 }

local function background(
	candidate: Registry.Candidate,
	theme: Theme.Theme
): Declarations?
	local name = candidate.value
	if name == nil then
		return nil
	elseif ANGLES[name] then
		return { gradientAngle = ANGLES[name] }
	end
	local color = Values.color(theme, name, candidate.modifier)
	return if color then { fillColor = color } else nil
end

local function from(
	candidate: Registry.Candidate,
	theme: Theme.Theme
): Declarations?
	local name = candidate.value or ""
	local color = Values.color(theme, name, candidate.modifier)
	local stop = string.match(name, "^(%d+)%%$")
	if color then
		return { gradientFrom = color }
	end
	return if stop
		then { gradientFromStop = (tonumber(stop) or 0) / 100 }
		else nil
end

local function to(
	candidate: Registry.Candidate,
	theme: Theme.Theme
): Declarations?
	local color = if candidate.value
		then Values.color(theme, candidate.value, candidate.modifier)
		else nil
	return if color then { gradientTo = color } else nil
end

local group: Registry.Group = {
	functional = { bg = background, from = from, to = to },
	noop = {
		["^bg%-opacity%-"] = "removed in Tailwind 4",
	},
}

return group
