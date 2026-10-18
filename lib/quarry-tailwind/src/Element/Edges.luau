--!strict
-- One-sided borders (`border-b`, `border-x`): a UIStroke draws all four
-- sides, so each side is a line laid over the element's edge, in the
-- border's colour, solid or, for `border-dashed`, a tiled dash (3 px on,
-- 3 px off, about Chrome's dashes for a 1 px border). As in CSS's border
-- box, each side's width is also padding on that side (Rules.Padding).

local Assets = require("../Assets")
local Declarations = require("../Compiler/Declarations")
local React = require("../../React")

type Rgba = Declarations.Rgba
type Side = "top" | "right" | "bottom" | "left"

local DASH_PERIOD = 6

local e = React.createElement

-- Where a side's line sits on the element, how long it runs, and whether
-- it runs across.
local function line(side: Side, width: number): (UDim2, UDim2, boolean)
	if side == "top" then
		return UDim2.new(), UDim2.new(1, 0, 0, width), true
	elseif side == "bottom" then
		return UDim2.new(0, 0, 1, -width),
			UDim2.new(1, 0, 0, width),
			true
	elseif side == "left" then
		return UDim2.new(), UDim2.new(0, width, 1, 0), false
	end
	return UDim2.new(1, -width, 0, 0), UDim2.new(0, width, 1, 0), false
end

local function draw(
	side: Side,
	width: number,
	color: Rgba,
	alpha: number,
	dashed: boolean
)
	local position, size, across = line(side, width)
	local tint = Color3.fromRGB(color.r, color.g, color.b)
	return e("ImageLabel", {
		BackgroundTransparency = if dashed then 1 else 1 - alpha,
		BackgroundColor3 = tint,
		BorderSizePixel = 0,
		Image = if not dashed
			then ""
			elseif across then Assets.dashAcross
			else Assets.dashDown,
		ImageColor3 = tint,
		ImageTransparency = 1 - alpha,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = if across
			then UDim2.fromOffset(DASH_PERIOD, width)
			else UDim2.fromOffset(width, DASH_PERIOD),
		Position = position,
		Size = size,
	})
end

-- The lines of the one-sided borders in the state `style`, in `color` at
-- `opacity`, or nil when it has none.
local function render(
	style: Declarations.Declarations,
	color: Rgba,
	opacity: number
): React.ReactNode
	if not Declarations.hasEdges(style) then
		return nil
	end
	local alpha = color.a * opacity
	local dashed = style.borderStyle == "dashed"
	local function side(name: Side, width: number?): React.ReactNode
		if width == nil or width <= 0 then
			return nil
		end
		return draw(name, width, color, alpha, dashed)
	end
	local lines: { [string]: React.ReactNode } = {
		top = side("top", style.borderTop),
		right = side("right", style.borderRight),
		bottom = side("bottom", style.borderBottom),
		left = side("left", style.borderLeft),
	}
	return e(React.Fragment, nil, lines)
end

return { render = render }
