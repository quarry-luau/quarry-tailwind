--!strict
-- A run of text in the current ink. Its font, size and line height come
-- from the inherited text style, the size calibrated so it is about as wide
-- as Chrome draws it and the line box exactly the CSS line height. It wraps
-- to its container's width when that width is definite and the text may
-- wrap; otherwise it sits on one line at its natural width. Its colour
-- comes from the ink's style rules, so states and transitions reach it.
-- Under a scale (a pressed button's `active:scale-98`) Roblox draws text at
-- the nearest whole size below, narrower than the scale alone would make
-- it, so a label at its natural width keeps its full-size width there and
-- the box around it scales smoothly.

local TextService = game:GetService("TextService")

local Context = require("./Context")
local Properties = require("./Properties")
local React = require("../../React")
local Text = require("../Compiler/Text")
local Typeface = require("./Typeface")

export type Props = { text: string, layoutOrder: number? }

local MIN_LINE_HEIGHT, MAX_LINE_HEIGHT = 1, 3

local ALIGN: { [string]: Enum.TextXAlignment } = {
	left = Enum.TextXAlignment.Left,
	center = Enum.TextXAlignment.Center,
	right = Enum.TextXAlignment.Right,
}

-- What keeps a block or column from stretching text at its natural width.
local START = { ItemLineAlignment = Enum.ItemLineAlignment.Start }

local e = React.createElement

-- Full-size widths TextService measured, by text, font and size.
local measured: { [string]: number } = {}

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

local function textKey(text: string, size: Typeface.Typeface): string
	local font = size.font
	return `{text}\0{font.Family}\0{font.Weight.Name}\0{font.Style.Name}\0`
		.. `{size.textSize}`
end

-- Measures `text` at full size into `measured`; yields. On a failure the
-- label sizes itself.
local function measureText(key: string, text: string, size: Typeface.Typeface)
	local params = Instance.new("GetTextBoundsParams")
	params.Text = text
	params.Font = size.font
	params.Size = size.textSize
	local ok, bounds =
		pcall(TextService.GetTextBoundsAsync, TextService, params)
	if ok then
		measured[key] = bounds.X
	end
end

-- The label's full-size width, held while it is drawn scaled; nil while it
-- sizes itself. It is measured as drawn at full size, or by TextService
-- when it appears, or its text changes, while scaled.
local function useHeldWidth(
	scale: React.Binding<number>,
	text: string,
	size: Typeface.Typeface
): (React.Binding<number?>, (TextLabel) -> ())
	local natural, setNatural = React.useBinding(0)
	local key = textKey(text, size)
	local latest = React.useRef(key)
	latest.current = key
	React.useLayoutEffect(function()
		if scale:getValue() == 1 then
			return
		elseif measured[key] then
			setNatural(measured[key] * size.scale)
			return
		end
		task.spawn(function()
			measureText(key, text, size)
			if measured[key] and latest.current == key then
				setNatural(measured[key] * size.scale)
			end
		end)
	end, { key })
	local held = React.joinBindings({ natural = natural, scale = scale })
		:map(
			function(
				values: { natural: number, scale: number }
			): number?
				local scaled = values.scale ~= 1
					and values.natural > 0
				return if scaled then values.natural else nil
			end
		)
	local function measure(label: TextLabel)
		if scale:getValue() == 1 then
			setNatural(label.AbsoluteSize.X)
		end
	end
	return held, measure
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

type Sized<T> = T | React.Binding<T>

-- The label's Size and AutomaticSize: across a definite block, or at its
-- held width.
local function sizeOf(
	shape: Shape,
	held: React.Binding<number?>
): (Sized<UDim2>, Sized<Enum.AutomaticSize>)
	local size, wraps = shape.size, shape.wraps
	if shape.fills and wraps then
		return UDim2.fromScale(1 / size.scale, 0), Enum.AutomaticSize.Y
	end
	return held:map(function(width: number?): UDim2
		local x = if width then width / size.scale else 0
		return UDim2.fromOffset(x, if wraps then 0 else size.lineHeight)
	end),
		held:map(function(width: number?): Enum.AutomaticSize
			if wraps then
				return if width
					then Enum.AutomaticSize.Y
					else Enum.AutomaticSize.XY
			end
			return if width
				then Enum.AutomaticSize.None
				else Enum.AutomaticSize.X
		end)
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
	local held, measure = useHeldWidth(context.scale, text, size)
	local boxSize, automatic = sizeOf(shape, held)
	local height = size.lineHeight / size.textSize
	local properties: Properties.Properties = {
		[React.Tag] = context.ink.tag,
		BackgroundTransparency = 1,
		FontFace = size.font,
		TextSize = size.textSize,
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
		[React.Change.AbsoluteSize] = measure,
		LayoutOrder = props.layoutOrder,
	}
	return e("TextLabel", properties, helpers(shape, context))
end

return Label
