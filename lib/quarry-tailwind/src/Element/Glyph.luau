--!strict
-- An image drawn in the current text colour, as an SVG in currentColor is
-- on the web: `size` px square (16 by default), or filling its parent when
-- `fill` is true.

local Context = require("./Context")
local React = require("../../React")

export type Props = {
	image: string,
	size: number?,
	fill: boolean?,
	layoutOrder: number?,
}

local DEFAULT_SIZE = 16

local function Glyph(props: Props): React.ReactNode
	local context = Context.use()
	local size = props.size or DEFAULT_SIZE
	return React.createElement("ImageLabel", {
		[React.Tag] = context.ink.tag,
		BackgroundTransparency = 1,
		Image = props.image,
		ScaleType = Enum.ScaleType.Fit,
		Size = if props.fill
			then UDim2.fromScale(1, 1)
			else UDim2.fromOffset(size, size),
		LayoutOrder = props.layoutOrder,
	})
end

return Glyph
