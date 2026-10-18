--!strict
-- Positioning: `relative`, `absolute`, `fixed`, insets (`top-4`, `inset-0`,
-- `-left-2`), `z-10` and translates (`-translate-x-1/2`, `translate-y-px`).

local Declarations = require("../Declarations")
local Registry = require("../Registry")
local Theme = require("../../Theme")
local Values = require("../Values")

type Declarations = Declarations.Declarations
type Length = Declarations.Length

local function negate(length: Length): Length
	if length.kind == "px" then
		return { kind = "px", value = -length.value }
	elseif length.kind == "fraction" then
		return {
			kind = "fraction",
			value = -length.value,
			offset = if length.offset then -length.offset else nil,
		}
	end
	return length
end

-- A length utility, negated by a leading `-`, set by `set`.
local function offset(set: (Length) -> Declarations): Registry.Functional
	return function(candidate, theme)
		local value = if candidate.value
			then Values.length(theme, candidate.value, false)
			else nil
		if value == nil then
			return nil
		end
		return set(if candidate.negative then negate(value) else value)
	end
end

local function z(candidate: Registry.Candidate, _: Theme.Theme): Declarations?
	local value = if candidate.value then tonumber(candidate.value) else nil
	return if value then { z = value } else nil
end

local group: Registry.Group = {
	static = {
		relative = { position = "relative" },
		absolute = { position = "absolute" },
		fixed = { position = "fixed" },
		sticky = { position = "sticky" },
	},
	functional = {
		z = z,
		["translate-x"] = offset(function(v)
			return { translateX = v }
		end),
		["translate-y"] = offset(function(v)
			return { translateY = v }
		end),
		inset = offset(function(v)
			return {
				insetTop = v,
				insetRight = v,
				insetBottom = v,
				insetLeft = v,
			}
		end),
		["inset-x"] = offset(function(v)
			return { insetLeft = v, insetRight = v }
		end),
		["inset-y"] = offset(function(v)
			return { insetTop = v, insetBottom = v }
		end),
		top = offset(function(v)
			return { insetTop = v }
		end),
		right = offset(function(v)
			return { insetRight = v }
		end),
		bottom = offset(function(v)
			return { insetBottom = v }
		end),
		left = offset(function(v)
			return { insetLeft = v }
		end),
	},
	negative = {
		"translate-x",
		"translate-y",
		"inset",
		"inset-x",
		"inset-y",
		"top",
		"right",
		"bottom",
		"left",
	},
	noop = {
		["^pointer%-events%-"] = "only buttons take input",
		["^touch%-none$"] = "Roblox has no browser gestures to stop",
		["^select%-"] = "Roblox text cannot be selected",
		["^cursor%-"] = "Roblox has no per-element cursor",
		["^appearance%-none$"] = "Roblox draws no native controls",
		["^resize%-none$"] = "TextBoxes do not resize",
		["^peer$"] = "a marker for peer-* variants",
		["^group$"] = "a marker for group-* variants",
	},
}

return group
