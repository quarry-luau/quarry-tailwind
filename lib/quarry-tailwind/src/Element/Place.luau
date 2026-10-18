--!strict
-- The frames that hold an element's place in its parent's layout when it
-- cannot hold it itself. A transformed or shadowed element sits in a frame
-- of its unscaled size (Transform), its shadow beneath it there, since a
-- child always draws above its parent. An element with a margin sits
-- offset in a frame that takes its place, since a list layout has no
-- margins. The outermost frame goes where the element would have gone. Its
-- absolute and fixed children (`overlay`) go on a frame over it, out of
-- its layout, as CSS takes them out of flow. A positioned element (`free`)
-- sits in a frame filling its parent instead, its shadow and overlay
-- following the rect it was measured at.

local Properties = require("./Properties")
local React = require("../../React")

type Properties = Properties.Properties
type Children = { [string]: React.ReactNode }

export type Options = {
	layoutOrder: number?,
	-- Where a centring cell puts the element (Center).
	position: React.Binding<UDim2>?,
	-- The element's unscaled size, when it is transformed or shadowed in
	-- place.
	box: React.Binding<UDim2>?,
	-- Where the element sits in that frame.
	centre: React.Binding<UDim2>?,
	-- Drawn beneath the element in its frame.
	shadow: React.ReactNode?,
	-- Top, right, bottom, left.
	margins: { number }?,
	-- Whether the element's width comes from its parent's (Flow).
	filling: boolean,
	-- Whether the parent stacks its children in a column, which would
	-- stretch a frame across.
	stacked: boolean,
	-- Whether the parent row shrinks the element; its frame shrinks then.
	shrinks: boolean,
	-- The element's absolute and fixed children, drawn over it.
	overlay: React.ReactNode?,
	-- The element's z-index, which its frame takes among its siblings.
	z: number?,
	-- For a positioned element: where it was measured in its parent.
	free: React.Binding<Rect>?,
}

-- Above the element in its frame, for its overlay.
local OVERLAY_Z_STEP = 1

local e = React.createElement

-- `base` with every property `over` sets.
local function merge(base: Properties, over: Properties): Properties
	local merged = table.clone(base)
	for key, value in over do
		merged[key] = value
	end
	return merged
end

local function marginFrame(
	node: React.ReactNode,
	options: Options
): React.ReactNode
	local margins = options.margins or { 0, 0, 0, 0 }
	local filling = options.filling
	local left = if filling then math.max(0, margins[4]) else 0
	return e("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = if filling
			then Enum.AutomaticSize.Y
			else Enum.AutomaticSize.XY,
		Size = if filling then UDim2.fromScale(1, 0) else UDim2.new(),
		LayoutOrder = options.layoutOrder,
	}, {
		Element = node,
		Margin = e("UIPadding", {
			PaddingLeft = UDim.new(0, left),
			PaddingRight = UDim.new(0, math.max(0, margins[2])),
			PaddingBottom = UDim.new(0, math.max(0, margins[3])),
		}),
	})
end

-- A frame covering `rect` in the frame's parent, holding `child`.
local function over(
	rect: React.Binding<Rect>,
	z: number,
	child: React.ReactNode
)
	return e("Frame", {
		BackgroundTransparency = 1,
		Position = rect:map(function(value: Rect): UDim2
			return UDim2.fromOffset(value.Min.X, value.Min.Y)
		end),
		Size = rect:map(function(value: Rect): UDim2
			return UDim2.fromOffset(value.Width, value.Height)
		end),
		ZIndex = z,
	}, { Content = child })
end

-- A positioned element in a frame filling its parent.
local function freeFrame(
	element: React.ReactNode,
	rect: React.Binding<Rect>,
	options: Options
)
	local z = options.z or 1
	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = z,
	}, {
		Shadow = if options.shadow
			then over(rect, 0, options.shadow)
			else nil,
		Element = element,
		Overlay = if options.overlay
			then over(rect, z + OVERLAY_Z_STEP, options.overlay)
			else nil,
	})
end

-- What keeps a seat frame on its line: not stretched across a column, and
-- shrinking where its parent row would shrink the element.
local function lineItem(options: Options): React.ReactNode
	if options.stacked then
		return e(
			"UIFlexItem",
			{ ItemLineAlignment = Enum.ItemLineAlignment.Start }
		)
	end
	return if options.shrinks
		then e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Shrink })
		else nil
end

-- The frame of an element's unscaled size, holding its shadow beneath it
-- and its overlay above.
local function seatFrame(
	element: React.ReactNode,
	box: React.Binding<UDim2>,
	options: Options
)
	local seat: Properties = {
		BackgroundTransparency = 1,
		Size = if options.filling
			then box:map(function(size: UDim2): UDim2
				return UDim2.new(1, 0, 0, size.Y.Offset)
			end)
			else box,
		ZIndex = options.z,
	}
	local overlay = if options.overlay
		then e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = (options.z or 1) + OVERLAY_Z_STEP,
		}, { Content = options.overlay })
		else nil
	return seat,
		{
			Shadow = options.shadow,
			Element = element,
			Overlay = overlay,
			Line = lineItem(options),
		}
end

-- Where the outermost frame sits: offset inside its margin frame, or where
-- the element would have.
local function seatProperties(options: Options): Properties
	local margins = options.margins
	if margins then
		local left = if options.filling then 0 else margins[4]
		return { Position = UDim2.fromOffset(left, margins[1]) }
	end
	return {
		Position = options.position,
		LayoutOrder = options.layoutOrder,
	}
end

-- The element `className` with `properties` and `children`, in whatever
-- frames hold its place.
local function wrap(
	className: string,
	properties: Properties,
	children: Children,
	options: Options
): React.ReactNode
	local box = options.box
	local placed = table.clone(properties)
	if box then
		placed.AnchorPoint = Vector2.new(0.5, 0.5)
		placed.Position = options.centre or UDim2.fromScale(0.5, 0.5)
	end
	if options.free then
		return freeFrame(
			e(className, placed, children),
			options.free,
			options
		)
	end
	local seat = seatProperties(options)
	local node: React.ReactNode
	if box then
		local frame, inside =
			seatFrame(e(className, placed, children), box, options)
		node = e("Frame", merge(frame, seat), inside)
	else
		node = e(className, merge(placed, seat), children)
	end
	return if options.margins then marginFrame(node, options) else node
end

return { wrap = wrap, merge = merge }
