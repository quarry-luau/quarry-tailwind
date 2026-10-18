--!strict
-- Borders, radii and rings: `border`, `border-2`, `border-input`,
-- `border-b`, `border-dashed`, `rounded-lg`, `rounded-t-md`, `ring-2`,
-- `ring-primary/50`.

local Declarations = require("../Declarations")
local Registry = require("../Registry")
local Theme = require("../../Theme")
local Values = require("../Values")

type Declarations = Declarations.Declarations

-- A width (`2`) or a colour (`input`, `primary/50`); the bare root is 1 px.
local function widthOrColor(
	width: (number) -> Declarations,
	color: (Declarations.Rgba) -> Declarations
): Registry.Functional
	return function(candidate, theme)
		local value = candidate.value
		if value == nil then
			return width(1)
		end
		local number = tonumber(value)
		local found = Values.color(theme, value, candidate.modifier)
		if number then
			return width(number)
		end
		return if found then color(found) else nil
	end
end

-- `rounded`, or a side or corner of it, at the radius its value names.
local function rounded(set: (number) -> Declarations): Registry.Functional
	return function(candidate: Registry.Candidate, theme: Theme.Theme)
		local radius = Values.radius(theme, candidate.value)
		return if radius then set(radius) else nil
	end
end

local group: Registry.Group = {
	static = {
		["border-solid"] = { borderStyle = "solid" },
		["border-dashed"] = { borderStyle = "dashed" },
		["border-dotted"] = { borderStyle = "dotted" },
		["border-t"] = { borderTop = 1 },
		["border-r"] = { borderRight = 1 },
		["border-b"] = { borderBottom = 1 },
		["border-l"] = { borderLeft = 1 },
		["border-x"] = { borderLeft = 1, borderRight = 1 },
		["border-y"] = { borderTop = 1, borderBottom = 1 },
	},
	functional = {
		border = widthOrColor(function(width)
			return { borderWidth = width }
		end, function(color)
			return { borderColor = color }
		end),
		ring = widthOrColor(function(width)
			return { ringWidth = width }
		end, function(color)
			return { ringColor = color }
		end),
		rounded = rounded(function(r)
			return { radius = r }
		end),
		["rounded-t"] = rounded(function(r)
			return { cornerTopLeft = r, cornerTopRight = r }
		end),
		["rounded-r"] = rounded(function(r)
			return { cornerTopRight = r, cornerBottomRight = r }
		end),
		["rounded-b"] = rounded(function(r)
			return { cornerBottomRight = r, cornerBottomLeft = r }
		end),
		["rounded-l"] = rounded(function(r)
			return { cornerTopLeft = r, cornerBottomLeft = r }
		end),
		["rounded-tl"] = rounded(function(r)
			return { cornerTopLeft = r }
		end),
		["rounded-tr"] = rounded(function(r)
			return { cornerTopRight = r }
		end),
		["rounded-br"] = rounded(function(r)
			return { cornerBottomRight = r }
		end),
		["rounded-bl"] = rounded(function(r)
			return { cornerBottomLeft = r }
		end),
	},
	noop = {
		["^ring%-offset%-"] = "Roblox draws one stroke per element",
		["^outline%-hidden$"] = "Roblox draws no focus outline",
		["^outline%-none$"] = "Roblox draws no focus outline",
	},
}

return group
