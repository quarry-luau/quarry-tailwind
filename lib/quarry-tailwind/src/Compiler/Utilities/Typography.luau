--!strict
-- Text: `text-sm` (with its line height, or `text-sm/6`), `text-center`,
-- `text-muted-foreground`, `text-[13px]`, `font-medium`, `font-mono`,
-- `leading-tight`, `uppercase`, `whitespace-nowrap`, `truncate`.

local Declarations = require("../Declarations")
local Registry = require("../Registry")
local Theme = require("../../Theme")
local Values = require("../Values")

type Declarations = Declarations.Declarations

local ALIGN: { [string]: Declarations.TextAlign } = {
	left = "left",
	start = "left",
	center = "center",
	right = "right",
	["end"] = "right",
}

-- A theme text size, with the line height it brings or the one `/6` sets.
local function size(
	theme: Theme.Theme,
	name: string,
	modifier: string?
): Declarations?
	local found = theme.text[name]
	if found == nil then
		return nil
	end
	local leading = if modifier
		then Values.spacing(theme, modifier)
		else nil
	return {
		textSize = found.size,
		textSizeRatio = found.lineHeight / found.size,
		textLeading = if leading
			then { kind = "px", value = leading }
			else nil,
	}
end

local function text(
	candidate: Registry.Candidate,
	theme: Theme.Theme
): Declarations?
	local name = candidate.value
	if name == nil then
		return nil
	end
	local sized = size(theme, name, candidate.modifier)
	local inside = string.match(name, "^%[(.*)%]$")
	local arbitrary = if inside then Values.cssLength(inside) else nil
	local color = Values.color(theme, name, candidate.modifier)
	if sized then
		return sized
	elseif ALIGN[name] then
		return { textAlign = ALIGN[name] }
	elseif arbitrary then
		return { textSize = arbitrary }
	end
	return if color then { textColor = color } else nil
end

local function font(
	candidate: Registry.Candidate,
	theme: Theme.Theme
): Declarations?
	local weight = if candidate.value
		then theme.fontWeight[candidate.value]
		else nil
	return if weight then { textWeight = weight } else nil
end

local function leading(
	candidate: Registry.Candidate,
	theme: Theme.Theme
): Declarations?
	local name = candidate.value
	if name == nil then
		return nil
	end
	local ratio = if name == "none" then 1 else theme.leading[name]
	local px = Values.spacing(theme, name)
	if ratio then
		return { textLeading = { kind = "ratio", value = ratio } }
	end
	return if px then { textLeading = { kind = "px", value = px } } else nil
end

local group: Registry.Group = {
	static = {
		["font-sans"] = { textFamily = "sans" },
		["font-mono"] = { textFamily = "mono" },
		capitalize = { textCasing = "capitalize" },
		uppercase = { textCasing = "uppercase" },
		lowercase = { textCasing = "lowercase" },
		["normal-case"] = { textCasing = "none" },
		["whitespace-nowrap"] = { textWrap = false },
		["whitespace-normal"] = { textWrap = true },
		truncate = { textWrap = false, textTruncate = true },
	},
	functional = { text = text, font = font, leading = leading },
	noop = {
		["^tracking%-"] = "Roblox text has no letter spacing",
		["^underline$"] = "TextLabels draw no underline",
		["^no%-underline$"] = "TextLabels draw no underline",
		["^underline%-offset%-"] = "TextLabels draw no underline",
		["^text%-balance$"] = "a line-breaking hint",
		["^text%-pretty$"] = "a line-breaking hint",
		["^break%-words$"] = "Roblox breaks long words already",
		["^antialiased$"] = "Roblox smooths text itself",
		["^subpixel%-antialiased$"] = "Roblox smooths text itself",
		["^tabular%-nums$"] = "Inter on Roblox has no numeric variants",
	},
}

return group
