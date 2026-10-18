--!strict
-- Padding, margins and gaps: `p-4`, `px-2.5`, `-mt-1`, `mx-auto`, `gap-2`,
-- `space-y-4`. A margin can be negative or `auto`; `space-*` is the gap
-- between children, which is how a Roblox list layout spaces them.

local Declarations = require("../Declarations")
local Registry = require("../Registry")
local Values = require("../Values")

type Declarations = Declarations.Declarations
type Margin = Declarations.Margin

-- A utility whose value is a spacing step, turned into declarations by
-- `set`.
local function spacing(set: (number) -> Declarations): Registry.Functional
	return function(candidate, theme)
		local value = if candidate.value
			then Values.spacing(theme, candidate.value)
			else nil
		return if value then set(value) else nil
	end
end

-- A margin utility: a spacing step (negated by a leading `-`) or `auto`.
local function margin(set: (Margin) -> Declarations): Registry.Functional
	return function(candidate, theme)
		local text = candidate.value
		if text == "auto" and not candidate.negative then
			return set("auto")
		end
		local value = if text then Values.spacing(theme, text) else nil
		if value == nil then
			return nil
		end
		return set(if candidate.negative then -value else value)
	end
end

local group: Registry.Group = {
	functional = {
		p = spacing(function(v)
			return {
				paddingTop = v,
				paddingRight = v,
				paddingBottom = v,
				paddingLeft = v,
			}
		end),
		px = spacing(function(v)
			return { paddingLeft = v, paddingRight = v }
		end),
		py = spacing(function(v)
			return { paddingTop = v, paddingBottom = v }
		end),
		pt = spacing(function(v)
			return { paddingTop = v }
		end),
		pr = spacing(function(v)
			return { paddingRight = v }
		end),
		pb = spacing(function(v)
			return { paddingBottom = v }
		end),
		pl = spacing(function(v)
			return { paddingLeft = v }
		end),
		ps = spacing(function(v)
			return { paddingLeft = v }
		end),
		pe = spacing(function(v)
			return { paddingRight = v }
		end),
		m = margin(function(v)
			return {
				marginTop = v,
				marginRight = v,
				marginBottom = v,
				marginLeft = v,
			}
		end),
		mx = margin(function(v)
			return { marginLeft = v, marginRight = v }
		end),
		my = margin(function(v)
			return { marginTop = v, marginBottom = v }
		end),
		mt = margin(function(v)
			return { marginTop = v }
		end),
		mr = margin(function(v)
			return { marginRight = v }
		end),
		mb = margin(function(v)
			return { marginBottom = v }
		end),
		ml = margin(function(v)
			return { marginLeft = v }
		end),
		gap = spacing(function(v)
			return { gapX = v, gapY = v }
		end),
		["gap-x"] = spacing(function(v)
			return { gapX = v }
		end),
		["gap-y"] = spacing(function(v)
			return { gapY = v }
		end),
		["space-x"] = spacing(function(v)
			return { gapX = v }
		end),
		["space-y"] = spacing(function(v)
			return { gapY = v }
		end),
	},
	negative = { "m", "mx", "my", "mt", "mr", "mb", "ml" },
}

return group
