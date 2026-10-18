--!strict
-- The element's own properties: its fill, size and automatic sizing,
-- visibility, clipping and z-index, and, for a positioned element, its
-- anchor and position. An inset from the right or bottom anchors that edge;
-- insets on both sides stretch the element between them. A translate moves
-- it by a fraction of its own size (the anchor) or by pixels.

local Declarations = require("../../Compiler/Declarations")
local Placement = require("./Placement")

type Declarations = Declarations.Declarations
type Length = Declarations.Length
type Rgba = Declarations.Rgba
-- Every value a rule sets is one of these.
export type Value =
	number
	| boolean
	| string
	| UDim
	| UDim2
	| Vector2
	| Color3
	| ColorSequence
	| NumberSequence
	| EnumItem
export type Properties = { [string]: Value }
-- Style tokens for animations (Animator), given the fill's alpha.
export type Tokens = { pulse: (alpha: number) -> string }

local FULL = UDim.new(1, 0)
local WHITE: Rgba = { r = 255, g = 255, b = 255, a = 1 }

local function color3(color: Rgba): Color3
	return Color3.fromRGB(color.r, color.g, color.b)
end

-- One axis as a UDim, and whether content sizes it.
local function axis(value: Length?, fill: boolean): (UDim, boolean)
	if value == nil then
		return if fill then FULL else UDim.new(), not fill
	elseif value.kind == "px" then
		return UDim.new(0, value.value), false
	elseif value.kind == "fraction" then
		return UDim.new(value.value, value.offset or 0), false
	end
	return UDim.new(), true
end

local function automatic(x: boolean, y: boolean): Enum.AutomaticSize
	if x and y then
		return Enum.AutomaticSize.XY
	elseif x then
		return Enum.AutomaticSize.X
	end
	return if y then Enum.AutomaticSize.Y else Enum.AutomaticSize.None
end

local function offset(value: Length?): UDim
	if value and value.kind == "px" then
		return UDim.new(0, value.value)
	elseif value and value.kind == "fraction" then
		return UDim.new(value.value, 0)
	end
	return UDim.new()
end

-- One axis of a positioned element: its anchor, its position, and the size
-- insets on both sides pin it to.
local function side(from: Length?, to: Length?): (number, UDim, UDim?)
	if from and to then
		local a, b = offset(from), offset(to)
		return 0,
			a,
			UDim.new(1 - a.Scale - b.Scale, -a.Offset - b.Offset)
	elseif to then
		local b = offset(to)
		return 1, UDim.new(1 - b.Scale, -b.Offset), nil
	end
	return 0, offset(from), nil
end

-- A translate as an anchor shift (a fraction of the element) and pixels.
local function translate(value: Length?): (number, number)
	if value and value.kind == "fraction" then
		return -value.value, 0
	elseif value and value.kind == "px" then
		return 0, value.value
	end
	return 0, 0
end

local function place(style: Declarations, size: UDim2, autoY: boolean)
	local anchorX, x, width = side(style.insetLeft, style.insetRight)
	local anchorY, y, height = side(style.insetTop, style.insetBottom)
	local shiftX, moveX = translate(style.translateX)
	local shiftY, moveY = translate(style.translateY)
	local placed: Properties = {
		AnchorPoint = Vector2.new(anchorX + shiftX, anchorY + shiftY),
		Position = UDim2.new(
			x + UDim.new(0, moveX),
			y + UDim.new(0, moveY)
		),
		Size = UDim2.new(width or size.X, height or size.Y),
	}
	if width then
		placed.AutomaticSize = automatic(false, autoY)
	end
	return placed
end

local function fill(style: Declarations): Rgba?
	local gradient = style.gradientFrom ~= nil or style.gradientTo ~= nil
	return if gradient then WHITE else style.fillColor
end

local function build(
	style: Declarations,
	placement: Placement.Placement,
	tokens: Tokens
): Properties
	local positioned = Declarations.positioned(style)
	local color = fill(style)
	local alpha = if color then color.a * Declarations.opacity(style) else 0
	local fills = Placement.fills(placement) and not positioned
	local width, autoX = axis(style.width, fills)
	local height, autoY = axis(style.height, false)
	local properties: Properties = {
		BorderSizePixel = 0,
		BackgroundColor3 = if color
			then color3(color)
			else Color3.new(1, 1, 1),
		BackgroundTransparency = if style.animation == "pulse"
				and color
			then tokens.pulse(alpha)
			else 1 - alpha,
		Size = UDim2.new(width, height),
		AutomaticSize = automatic(autoX, autoY),
		Visible = style.hidden ~= true,
		ClipsDescendants = style.clips == true,
	}
	if style.z then
		properties.ZIndex = style.z
	end
	if positioned then
		local size = UDim2.new(width, height)
		for key, value in place(style, size, autoY) do
			properties[key] = value
		end
	end
	return properties
end

return { build = build, color3 = color3 }
