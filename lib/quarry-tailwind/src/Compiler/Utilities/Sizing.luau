--!strict
-- Widths and heights: `w-64`, `h-full`, `size-4`, `w-1/2`, `w-[40%]`,
-- `min-h-9`, `max-w-lg` (a container size, which only max-* takes).

local Declarations = require("../Declarations")
local Registry = require("../Registry")
local Values = require("../Values")

type Declarations = Declarations.Declarations
type Length = Declarations.Length

local function size(
	containers: boolean,
	set: (Length) -> Declarations
): Registry.Functional
	return function(candidate, theme)
		local value = if candidate.value
			then Values.length(theme, candidate.value, containers)
			else nil
		return if value then set(value) else nil
	end
end

local group: Registry.Group = {
	functional = {
		w = size(false, function(v)
			return { width = v }
		end),
		h = size(false, function(v)
			return { height = v }
		end),
		size = size(false, function(v)
			return { width = v, height = v }
		end),
		["min-w"] = size(false, function(v)
			return { minWidth = v }
		end),
		["min-h"] = size(false, function(v)
			return { minHeight = v }
		end),
		["max-w"] = size(true, function(v)
			return { maxWidth = v }
		end),
		["max-h"] = size(true, function(v)
			return { maxHeight = v }
		end),
	},
}

return group
