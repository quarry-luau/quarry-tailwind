--!strict
-- What a class string declares in one state, one typed field per property:
-- each utility sets some fields, the compiler merges them per state with
-- later classes winning, and the style sheet and the element read them. A
-- field left nil is unset, so the inherited value or Roblox's default holds.

local Color = require("./Color")

export type Rgba = Color.Rgba
export type Curve = { number }
-- A length on one axis: pixels, a fraction of the parent (plus pixels, for
-- `calc(100% - 32px)`), or sized by content.
export type Length =
	{ kind: "px", value: number }
	| { kind: "fraction", value: number, offset: number? }
	| { kind: "auto" }
-- Line height as a multiple of the font size, or in px.
export type Leading =
	{ kind: "ratio", value: number }
	| { kind: "px", value: number }
export type Margin = number | "auto"
export type Align = "start" | "center" | "end" | "stretch"
export type Justify =
	"start"
	| "center"
	| "end"
	| "between"
	| "around"
	| "evenly"
export type Family = "sans" | "mono"
export type TextAlign = "left" | "center" | "right"
export type Casing = "none" | "uppercase" | "lowercase" | "capitalize"
export type Position = "relative" | "absolute" | "fixed" | "sticky"
export type Animation = "none" | "spin" | "pulse"
-- The kinds of property a transition covers; `size` only for
-- `transition-all`.
export type Covers = {
	colors: boolean,
	opacity: boolean,
	transform: boolean,
	shadow: boolean,
	size: boolean,
}

export type Declarations = {
	fillColor: Rgba?,

	textColor: Rgba?,
	textSize: number?,
	-- The line height a text size brings, as a ratio of the size.
	textSizeRatio: number?,
	-- A `leading-*` or `text-sm/6` line height, which beats the size's.
	textLeading: Leading?,
	textWeight: number?,
	textFamily: Family?,
	textAlign: TextAlign?,
	textCasing: Casing?,
	textWrap: boolean?,
	textTruncate: boolean?,

	width: Length?,
	height: Length?,
	minWidth: Length?,
	minHeight: Length?,
	maxWidth: Length?,
	maxHeight: Length?,

	paddingTop: number?,
	paddingRight: number?,
	paddingBottom: number?,
	paddingLeft: number?,
	marginTop: Margin?,
	marginRight: Margin?,
	marginBottom: Margin?,
	marginLeft: Margin?,

	layout: ("flex" | "grid")?,
	direction: ("row" | "column")?,
	alignItems: Align?,
	justify: Justify?,
	gapX: number?,
	gapY: number?,
	flexWrap: boolean?,
	grow: number?,
	shrink: number?,
	-- `hidden` sets it; a display utility (`flex`, `block`) clears it.
	hidden: boolean?,
	-- visibility: hidden, which keeps the box.
	invisible: boolean?,

	radius: number?,
	cornerTopLeft: number?,
	cornerTopRight: number?,
	cornerBottomRight: number?,
	cornerBottomLeft: number?,

	borderWidth: number?,
	borderColor: Rgba?,
	borderStyle: ("solid" | "dashed" | "dotted")?,
	-- One-sided borders (`border-b`), each side's width.
	borderTop: number?,
	borderRight: number?,
	borderBottom: number?,
	borderLeft: number?,
	ringWidth: number?,
	ringColor: Rgba?,

	opacity: number?,
	-- A theme shadow's name, or "none".
	shadow: string?,
	aspect: number?,
	clips: boolean?,
	scrolls: boolean?,

	scale: number?,
	translateX: Length?,
	translateY: Length?,
	position: Position?,
	z: number?,
	insetTop: Length?,
	insetRight: Length?,
	insetBottom: Length?,
	insetLeft: Length?,

	transition: Covers?,
	duration: number?,
	delay: number?,
	ease: Curve?,
	animation: Animation?,

	gradientFrom: Rgba?,
	gradientTo: Rgba?,
	-- Where the first colour stops, 0 to 1 (`from-80%`).
	gradientFromStop: number?,
	-- 0 runs left to right, 90 top to bottom.
	gradientAngle: number?,
}

local Declarations = {}

-- `over` where it is set, `base` otherwise; a later `false` still wins.
local function pick<T>(over: T?, base: T?): T?
	if over == nil then
		return base
	end
	return over
end

local function mergeFill(into: Declarations, over: Declarations)
	into.fillColor = pick(over.fillColor, into.fillColor)
end

local function mergeText(into: Declarations, over: Declarations)
	into.textColor = pick(over.textColor, into.textColor)
	into.textSize = pick(over.textSize, into.textSize)
	into.textSizeRatio = pick(over.textSizeRatio, into.textSizeRatio)
	into.textLeading = pick(over.textLeading, into.textLeading)
	into.textWeight = pick(over.textWeight, into.textWeight)
	into.textFamily = pick(over.textFamily, into.textFamily)
	into.textAlign = pick(over.textAlign, into.textAlign)
	into.textCasing = pick(over.textCasing, into.textCasing)
	into.textWrap = pick(over.textWrap, into.textWrap)
	into.textTruncate = pick(over.textTruncate, into.textTruncate)
end

local function mergeSize(into: Declarations, over: Declarations)
	into.width = pick(over.width, into.width)
	into.height = pick(over.height, into.height)
	into.minWidth = pick(over.minWidth, into.minWidth)
	into.minHeight = pick(over.minHeight, into.minHeight)
	into.maxWidth = pick(over.maxWidth, into.maxWidth)
	into.maxHeight = pick(over.maxHeight, into.maxHeight)
end

local function mergeSpacing(into: Declarations, over: Declarations)
	into.paddingTop = pick(over.paddingTop, into.paddingTop)
	into.paddingRight = pick(over.paddingRight, into.paddingRight)
	into.paddingBottom = pick(over.paddingBottom, into.paddingBottom)
	into.paddingLeft = pick(over.paddingLeft, into.paddingLeft)
	into.marginTop = pick(over.marginTop, into.marginTop)
	into.marginRight = pick(over.marginRight, into.marginRight)
	into.marginBottom = pick(over.marginBottom, into.marginBottom)
	into.marginLeft = pick(over.marginLeft, into.marginLeft)
end

local function mergeLayout(into: Declarations, over: Declarations)
	into.layout = pick(over.layout, into.layout)
	into.direction = pick(over.direction, into.direction)
	into.alignItems = pick(over.alignItems, into.alignItems)
	into.justify = pick(over.justify, into.justify)
	into.gapX = pick(over.gapX, into.gapX)
	into.gapY = pick(over.gapY, into.gapY)
	into.flexWrap = pick(over.flexWrap, into.flexWrap)
	into.grow = pick(over.grow, into.grow)
	into.shrink = pick(over.shrink, into.shrink)
	into.hidden = pick(over.hidden, into.hidden)
	into.invisible = pick(over.invisible, into.invisible)
end

local function mergeCorners(into: Declarations, over: Declarations)
	into.radius = pick(over.radius, into.radius)
	into.cornerTopLeft = pick(over.cornerTopLeft, into.cornerTopLeft)
	into.cornerTopRight = pick(over.cornerTopRight, into.cornerTopRight)
	into.cornerBottomRight =
		pick(over.cornerBottomRight, into.cornerBottomRight)
	into.cornerBottomLeft =
		pick(over.cornerBottomLeft, into.cornerBottomLeft)
end

local function mergeBorder(into: Declarations, over: Declarations)
	into.borderWidth = pick(over.borderWidth, into.borderWidth)
	into.borderColor = pick(over.borderColor, into.borderColor)
	into.borderStyle = pick(over.borderStyle, into.borderStyle)
	into.borderTop = pick(over.borderTop, into.borderTop)
	into.borderRight = pick(over.borderRight, into.borderRight)
	into.borderBottom = pick(over.borderBottom, into.borderBottom)
	into.borderLeft = pick(over.borderLeft, into.borderLeft)
	into.ringWidth = pick(over.ringWidth, into.ringWidth)
	into.ringColor = pick(over.ringColor, into.ringColor)
end

local function mergeEffects(into: Declarations, over: Declarations)
	into.opacity = pick(over.opacity, into.opacity)
	into.shadow = pick(over.shadow, into.shadow)
	into.aspect = pick(over.aspect, into.aspect)
	into.clips = pick(over.clips, into.clips)
	into.scrolls = pick(over.scrolls, into.scrolls)
end

local function mergePosition(into: Declarations, over: Declarations)
	into.scale = pick(over.scale, into.scale)
	into.translateX = pick(over.translateX, into.translateX)
	into.translateY = pick(over.translateY, into.translateY)
	into.position = pick(over.position, into.position)
	into.z = pick(over.z, into.z)
	into.insetTop = pick(over.insetTop, into.insetTop)
	into.insetRight = pick(over.insetRight, into.insetRight)
	into.insetBottom = pick(over.insetBottom, into.insetBottom)
	into.insetLeft = pick(over.insetLeft, into.insetLeft)
end

local function mergeMotion(into: Declarations, over: Declarations)
	into.transition = pick(over.transition, into.transition)
	into.duration = pick(over.duration, into.duration)
	into.delay = pick(over.delay, into.delay)
	into.ease = pick(over.ease, into.ease)
	into.animation = pick(over.animation, into.animation)
end

local function mergeGradient(into: Declarations, over: Declarations)
	into.gradientFrom = pick(over.gradientFrom, into.gradientFrom)
	into.gradientTo = pick(over.gradientTo, into.gradientTo)
	into.gradientFromStop =
		pick(over.gradientFromStop, into.gradientFromStop)
	into.gradientAngle = pick(over.gradientAngle, into.gradientAngle)
end

-- `base` with every field `over` sets replacing its own. Each field is
-- merged by name, so a field added to the type must be added here too; the
-- tests check that none is missing.
function Declarations.merge(
	base: Declarations,
	over: Declarations
): Declarations
	local merged = table.clone(base)
	mergeFill(merged, over)
	mergeText(merged, over)
	mergeSize(merged, over)
	mergeSpacing(merged, over)
	mergeLayout(merged, over)
	mergeCorners(merged, over)
	mergeBorder(merged, over)
	mergeEffects(merged, over)
	mergePosition(merged, over)
	mergeMotion(merged, over)
	mergeGradient(merged, over)
	return merged
end

-- The element's CSS opacity, 0 when it is `invisible`.
function Declarations.opacity(style: Declarations): number
	return if style.invisible then 0 else style.opacity or 1
end

-- Whether the element is taken out of flow (`fixed`, `absolute`).
function Declarations.positioned(style: Declarations): boolean
	return style.position == "fixed" or style.position == "absolute"
end

local function larger(a: number?, b: number?): number?
	if a and b then
		return math.max(a, b)
	end
	return a or b
end

-- The corner radius in px (math.huge for a pill), nil when square. A
-- UICorner rounds all four corners, so per-corner radii (`rounded-b-lg`)
-- round them all by the largest.
function Declarations.radius(style: Declarations): number?
	if style.radius then
		return style.radius
	end
	return larger(
		larger(style.cornerTopLeft, style.cornerTopRight),
		larger(style.cornerBottomRight, style.cornerBottomLeft)
	)
end

-- Whether any one-sided border is set.
function Declarations.hasEdges(style: Declarations): boolean
	return style.borderTop ~= nil
		or style.borderRight ~= nil
		or style.borderBottom ~= nil
		or style.borderLeft ~= nil
end

return Declarations
