--!strict
-- The UIPadding: padding plus the border's width on each side. In CSS
-- (border-box) a border takes room inside the box; a Roblox UIStroke drawn
-- inside takes none, and a one-sided border is a line over the edge.

local Box = require("./Box")
local Declarations = require("../../Compiler/Declarations")

type Declarations = Declarations.Declarations
type Properties = Box.Properties

local function build(style: Declarations): Properties?
	local border = style.borderWidth or 0
	local top = (style.paddingTop or 0) + border + (style.borderTop or 0)
	local right = (style.paddingRight or 0)
		+ border
		+ (style.borderRight or 0)
	local bottom = (style.paddingBottom or 0)
		+ border
		+ (style.borderBottom or 0)
	local left = (style.paddingLeft or 0) + border + (style.borderLeft or 0)
	if top == 0 and right == 0 and bottom == 0 and left == 0 then
		return nil
	end
	local properties: Properties = {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom),
		PaddingLeft = UDim.new(0, left),
	}
	return properties
end

-- The width padding and border take inside the element's box.
local function insetX(style: Declarations): number
	return (style.paddingLeft or 0)
		+ (style.paddingRight or 0)
		+ 2 * (style.borderWidth or 0)
		+ (style.borderLeft or 0)
		+ (style.borderRight or 0)
end

return { build = build, insetX = insetX }
