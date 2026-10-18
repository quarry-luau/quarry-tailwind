--!strict
-- How text style inherits down a tree, as CSS does: colour, size, weight,
-- family, alignment, casing and wrapping pass to children. Line height
-- passes as a ratio of the font size when it was set unitless (a text
-- size's own, named leading) and in px when set as a length (`leading-4`);
-- a `leading-*` class beats the line height a text size brings.

local Declarations = require("./Declarations")

type Rgba = Declarations.Rgba
type Leading = Declarations.Leading

export type Style = {
	color: Rgba,
	size: number,
	weight: number,
	family: Declarations.Family,
	leading: Leading,
	align: Declarations.TextAlign,
	casing: Declarations.Casing,
	wrap: boolean,
	truncate: boolean,
}

-- The page's own text in `color`: 16 px, regular, line height 1.5
-- (Tailwind's preflight).
local function body(color: Rgba): Style
	return {
		color = color,
		size = 16,
		weight = 400,
		family = "sans",
		leading = { kind = "ratio", value = 1.5 },
		align = "left",
		casing = "none",
		wrap = true,
		truncate = false,
	}
end

local function leadingOf(own: Declarations.Declarations, parent: Style): Leading
	if own.textLeading then
		return own.textLeading
	elseif own.textSizeRatio then
		return { kind = "ratio", value = own.textSizeRatio }
	end
	return parent.leading
end

-- The style of an element declaring `own`, inside `parent`.
local function resolve(parent: Style, own: Declarations.Declarations): Style
	return {
		color = own.textColor or parent.color,
		size = own.textSize or parent.size,
		weight = own.textWeight or parent.weight,
		family = own.textFamily or parent.family,
		leading = leadingOf(own, parent),
		align = own.textAlign or parent.align,
		casing = own.textCasing or parent.casing,
		wrap = if own.textWrap ~= nil
			then own.textWrap
			else parent.wrap,
		truncate = if own.textTruncate ~= nil
			then own.textTruncate
			else parent.truncate,
	}
end

-- The line height in px.
local function lineHeight(style: Style): number
	local leading = style.leading
	return if leading.kind == "px"
		then leading.value
		else leading.value * style.size
end

-- Whether `own` sets anything text inherits, or an opacity that fades it.
local function styles(own: Declarations.Declarations): boolean
	return own.textColor ~= nil
		or own.textSize ~= nil
		or own.textWeight ~= nil
		or own.textFamily ~= nil
		or own.textLeading ~= nil
		or own.textSizeRatio ~= nil
		or own.textAlign ~= nil
		or own.textCasing ~= nil
		or own.textWrap ~= nil
		or own.textTruncate ~= nil
		or own.opacity ~= nil
		or own.invisible ~= nil
end

return {
	body = body,
	resolve = resolve,
	lineHeight = lineHeight,
	styles = styles,
}
