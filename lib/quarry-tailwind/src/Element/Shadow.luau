--!strict
-- A box shadow (`shadow-lg`), drawn as CSS draws one: each of the theme's
-- layers is the element's box moved by its offset and grown by its spread,
-- its corners rounded as the element's are (grown by the spread too), under
-- a Gaussian blur of half its blur radius. The blur is a box blurred for a
-- 16 px radius (Assets.shadows), 9-sliced and scaled to the layer's blur,
-- which scales its corner as well; each layer takes the image whose scaled
-- corner comes nearest the box's without passing it. A shadow a state adds
-- or removes fades along the element's transition when it covers shadows.

local Assets = require("../Assets")
local Config = require("../Config")
local React = require("../../React")
local Theme = require("../Theme")
local Timing = require("../Motion/Timing")
local useTween = require("../Motion/useTween")

export type Props = {
	-- The shadow the element has now (`lg`), nil for none.
	name: string?,
	timing: Timing.Timing,
	-- The element's corner radius (math.huge for a pill), nil when square.
	radius: number?,
	-- The element's unscaled size.
	size: React.Binding<UDim2>,
}

-- The images' geometry (tools/make-shadow.py): each box starts MARGIN px
-- in, and its blur runs REFERENCE_BLUR outside the edge and INNER inside.
local REFERENCE_BLUR = 16
local MARGIN = 32
local INNER = 24
local CENTRE = 8
-- Roblox refuses a slice scale of 0; a blur this small draws a hard edge.
local MIN_SCALE = 0.01

local e = React.createElement

-- The image for a layer drawn at `scale` under a box cornered `radius`:
-- the largest corner that, scaled, does not pass it.
local function pick(scale: number, radius: number): Assets.Shadow
	local chosen = Assets.shadows[1]
	for _, image in Assets.shadows do
		if image.corner * scale <= radius then
			chosen = image
		end
	end
	return chosen
end

local function slice(image: Assets.Shadow): Rect
	local inset = MARGIN + image.corner + INNER
	return Rect.new(inset, inset, inset + CENTRE, inset + CENTRE)
end

local function layer(
	props: Props,
	shown: React.Binding<number>,
	shadow: Theme.ShadowLayer
): React.ReactNode
	local scale = math.max(shadow.blur / REFERENCE_BLUR, MIN_SCALE)
	local reach = MARGIN * scale + shadow.spread
	local chosen = props.size:map(function(size: UDim2): Assets.Shadow
		local short = math.min(size.X.Offset, size.Y.Offset)
		local half = math.max(0, short / 2 + shadow.spread)
		local grown = math.max(0, (props.radius or 0) + shadow.spread)
		return pick(scale, math.min(grown, half))
	end)
	local color = shadow.color
	return e("ImageLabel", {
		BackgroundTransparency = 1,
		Image = chosen:map(function(image: Assets.Shadow): string
			return image.image
		end),
		ImageColor3 = Color3.fromRGB(color.r, color.g, color.b),
		ImageTransparency = shown:map(function(alpha: number): number
			return 1 - color.a * alpha
		end),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = chosen:map(slice),
		SliceScale = scale,
		Size = UDim2.new(1, 2 * reach, 1, 2 * reach),
		Position = UDim2.fromOffset(shadow.x - reach, shadow.y - reach),
		ZIndex = 0,
	})
end

local function Shadow(props: Props): React.ReactNode
	local last = React.useRef(props.name)
	if props.name then
		last.current = props.name
	end
	local shown = useTween(if props.name then 1 else 0, props.timing)
	local name = last.current
	local layers = if name then Config.get().theme.shadow[name] else nil
	if layers == nil then
		return nil
	end
	local images: { [string]: React.ReactNode } = {}
	for index, shadow in layers do
		images[`Layer{index}`] = layer(props, shown, shadow)
	end
	return e(React.Fragment, nil, images)
end

return Shadow
