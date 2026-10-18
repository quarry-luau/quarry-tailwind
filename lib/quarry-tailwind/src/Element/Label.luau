--!strict
-- A run of text in the current ink. Its font, size and line height come
-- from the inherited text style, the size calibrated so it is about as wide
-- as Chrome draws it and the line box exactly the CSS line height. It wraps
-- to its container's width when that width is definite and the text may
-- wrap; otherwise it sits on one line at its natural width. Its colour
-- comes from the ink's style rules, so states and transitions reach it.
-- Under a scale (a pressed button's `active:scale-98`, a zoom) it keeps
-- its size and shrinks with the scale, as the box around it does.

local Context = require("./Context")
local Properties = require("./Properties")
local React = require("../../React")
local Text = require("../Compiler/Text")
local Typeface = require("./Typeface")

export type Props = { text: string, layoutOrder: number? }

local MIN_LINE_HEIGHT, MAX_LINE_HEIGHT = 1, 3
local MAX_TEXT_SIZE = 100
-- Float error in a size over a scale (14 / 0.7 is 20.000000000000004).
local ROUNDING = 1e-6

local ALIGN: { [string]: Enum.TextXAlignment } = {
	left = Enum.TextXAlignment.Left,
	center = Enum.TextXAlignment.Center,
	right = Enum.TextXAlignment.Right,
}

-- What keeps a block or column from stretching text at its natural width.
local START = { ItemLineAlignment = Enum.ItemLineAlignment.Start }

local e = React.createElement

local function cased(text: string, casing: string): string
	if casing == "uppercase" then
		return string.upper(text)
	elseif casing == "lowercase" then
		return string.lower(text)
	elseif casing == "capitalize" then
		return (string.gsub(text, "%f[%a](%a)", string.upper))
	end
	return text
end

-- Roblox draws text under a scale at its TextSize times the scale rounded
-- down to a whole size: 14 under 0.98 draws as 13, about 7% smaller than
-- the scale. The TextSize that rounds back down to `textSize` draws it at
-- its own size, scaled exactly. Measured in Studio, October 2026.
local function scaledTextSize(textSize: number, scale: number): number
	if scale <= 0 or scale == 1 then
		return textSize
	end
	local size = math.ceil(textSize / scale - ROUNDING)
	return math.min(size, MAX_TEXT_SIZE)
end

type Shape = { fills: boolean, wraps: boolean, size: Typeface.Typeface }

-- The label's helpers: its UIScale past TextSize's limit; padding that
-- gives a wrapped lone line CSS's line box (Roblox makes it TextSize tall);
-- and, at its natural width, what keeps a block from stretching it and
-- caps it at the space available.
local function helpers(
	shape: Shape,
	context: Context.Value
): { [string]: React.ReactNode }
	local size, flow = shape.size, context.placement.flow
	local leading = math.max(0, math.round(size.lineHeight - size.textSize))
	local top = math.floor(leading / 2)
	local natural = not shape.fills and flow ~= "row"
	local capped = shape.wraps and not shape.fills
	local width = context.available / size.scale
	return {
		Scale = if size.scale ~= 1
			then e("UIScale", { Scale = size.scale })
			else nil,
		Leading = if shape.wraps and leading > 0
			then e("UIPadding", {
				PaddingTop = UDim.new(0, top),
				PaddingBottom = UDim.new(0, leading - top),
			})
			else nil,
		Natural = if natural then e("UIFlexItem", START) else nil,
		Available = if capped
			then e("UISizeConstraint", {
				MaxSize = Vector2.new(width, math.huge),
			})
			else nil,
	}
end

-- The label's Size and AutomaticSize: across a definite block, or at its
-- natural width.
local function sizeOf(shape: Shape): (UDim2, Enum.AutomaticSize)
	local size, wraps = shape.size, shape.wraps
	if shape.fills and wraps then
		return UDim2.fromScale(1 / size.scale, 0), Enum.AutomaticSize.Y
	elseif wraps then
		return UDim2.new(), Enum.AutomaticSize.XY
	end
	return UDim2.fromOffset(0, size.lineHeight), Enum.AutomaticSize.X
end

-- In a definite block or column text fills the width and wraps there;
-- elsewhere it takes its natural width, up to the space available.
local function shapeOf(context: Context.Value, style: Text.Style): Shape
	local flow = context.placement.flow
	local fills = context.definite
		and (flow == "root" or flow == "block" or flow == "column")
	return {
		fills = fills,
		wraps = style.wrap and (fills or context.available < math.huge),
		size = Typeface.resolve(style),
	}
end

local function Label(props: Props): React.ReactNode
	local context = Context.use()
	local style = context.ink.style
	local shape = shapeOf(context, style)
	local size = shape.size
	local text = cased(props.text, style.casing)
	local boxSize, automatic = sizeOf(shape)
	-- Text past TextSize's limit has a UIScale of its own (Typeface).
	local textSize = if size.scale == 1
		then context.scale:map(function(scale: number): number
			return scaledTextSize(size.textSize, scale)
		end)
		else size.textSize
	local height = size.lineHeight / size.textSize
	local properties: Properties.Properties = {
		[React.Tag] = context.ink.tag,
		BackgroundTransparency = 1,
		FontFace = size.font,
		TextSize = textSize,
		Text = text,
		TextWrapped = shape.wraps,
		TextTruncate = if style.truncate
			then Enum.TextTruncate.AtEnd
			else Enum.TextTruncate.None,
		TextXAlignment = ALIGN[style.align] or Enum.TextXAlignment.Left,
		TextYAlignment = if shape.wraps
			then Enum.TextYAlignment.Top
			else Enum.TextYAlignment.Center,
		LineHeight = if shape.wraps
			then math.clamp(
				height,
				MIN_LINE_HEIGHT,
				MAX_LINE_HEIGHT
			)
			else 1,
		Size = boxSize,
		AutomaticSize = automatic,
		LayoutOrder = props.layoutOrder,
	}
	return e("TextLabel", properties, helpers(shape, context))
end

return Label
