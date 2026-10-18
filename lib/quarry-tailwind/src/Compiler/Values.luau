--!strict
-- Reads utility values against a theme: colours with an opacity modifier,
-- spacing steps, lengths, radii, arbitrary values in [] and custom
-- properties in (). Each returns nil when the text is not a value of that
-- kind, so a utility can try the next reading.

local Color = require("./Color")
local Declarations = require("./Declarations")
local Theme = require("../Theme")

type Theme = Theme.Theme
type Length = Declarations.Length
type Rgba = Color.Rgba

local REM = 16
-- A bare `rounded`: 0.25rem.
local BARE_RADIUS = 4
local TRANSPARENT: Rgba = { r = 0, g = 0, b = 0, a = 0 }

local Values = {}

local function arbitrary(text: string): string?
	return string.match(text, "^%[(.*)%]$")
end

local function custom(theme: Theme, text: string): number?
	local name = string.match(text, "^%((%-%-[%w%-]+)%)$")
	return if name then theme.vars[name] else nil
end

local function px(value: number): Length
	return { kind = "px", value = value }
end

local function fraction(value: number, offset: number?): Length
	return { kind = "fraction", value = value, offset = offset }
end

-- A CSS length in px: `10px`, `0.5rem`, or a bare number of px.
function Values.cssLength(text: string): number?
	local amount, unit = string.match(text, "^(-?[%d.]+)(%a*)$")
	local number = if amount then tonumber(amount) else nil
	if number == nil then
		return nil
	elseif unit == "rem" then
		return number * REM
	end
	return if unit == "px" or unit == "" then number else nil
end

-- An opacity modifier: `80` is 0.8, `2.5` is 0.025, `[0.35]` and `[35%]`
-- are 0.35; none is 1.
function Values.opacity(modifier: string?): number?
	if modifier == nil then
		return 1
	end
	local inside = arbitrary(modifier)
	local percent = if inside
		then string.match(inside, "^([%d.]+)%%$")
		else nil
	if percent then
		return (tonumber(percent) or 0) / 100
	elseif inside then
		return tonumber(inside)
	end
	local number = tonumber(modifier)
	return if number then number / 100 else nil
end

-- A theme colour (`red-500`), `transparent` or an arbitrary one
-- (`[#fb5c49]`), with the opacity modifier applied.
function Values.color(theme: Theme, name: string, modifier: string?): Rgba?
	local opacity = Values.opacity(modifier)
	local inside = arbitrary(name)
	local base = theme.color[name]
		or (if inside then Color.parse(inside) else nil)
		or (if name == "transparent" then TRANSPARENT else nil)
	return if base and opacity
		then Color.withOpacity(base, opacity)
		else nil
end

-- A spacing step (`3.5` is 14 px), `px` (1 px), an arbitrary length or a
-- custom property.
function Values.spacing(theme: Theme, text: string): number?
	if text == "px" then
		return 1
	end
	local step = tonumber(text)
	if step then
		return step * theme.spacing
	end
	local inside = arbitrary(text)
	if inside then
		return Values.cssLength(inside)
	end
	return custom(theme, text)
end

-- `[40%]` and `[calc(100% - 32px)]` as fractions, or nil.
local function percentage(inside: string): Length?
	local percent = string.match(inside, "^(-?[%d.]+)%%$")
	if percent then
		return fraction((tonumber(percent) or 0) / 100)
	end
	local share, sign, rest = string.match(
		inside,
		"^calc%((-?[%d.]+)%%%s*([%+%-])%s*([%d.]+%a*)%)$"
	)
	local offset = if rest then Values.cssLength(rest) else nil
	if share == nil or offset == nil then
		return nil
	end
	return fraction(
		(tonumber(share) or 0) / 100,
		if sign == "-" then -offset else offset
	)
end

local CONTENT: { [string]: boolean } =
	{ auto = true, fit = true, max = true, min = true }

-- A width or height: spacing, `full`, a fraction (`1/2`), content-sized
-- (`auto`, `fit`), a container size (`max-w-lg`) when `containers`, or
-- arbitrary.
function Values.length(theme: Theme, text: string, containers: boolean): Length?
	if text == "full" then
		return fraction(1)
	elseif CONTENT[text] then
		return { kind = "auto" }
	end
	local over, under = string.match(text, "^(%d+)/(%d+)$")
	if over and under then
		return fraction((tonumber(over) or 0) / (tonumber(under) or 1))
	end
	local container = if containers then theme.container[text] else nil
	local inside = arbitrary(text)
	local share = if inside then percentage(inside) else nil
	if container then
		return px(container)
	elseif share then
		return share
	end
	local spacing = Values.spacing(theme, text)
	return if spacing then px(spacing) else nil
end

-- A radius in px: `full` is a pill, `none` is 0, nil is a bare `rounded`.
function Values.radius(theme: Theme, text: string?): number?
	if text == nil then
		return BARE_RADIUS
	elseif text == "full" then
		return math.huge
	elseif text == "none" then
		return 0
	end
	local inside = arbitrary(text)
	return theme.radius[text]
		or (if inside then Values.cssLength(inside) else nil)
		or custom(theme, text)
end

return Values
