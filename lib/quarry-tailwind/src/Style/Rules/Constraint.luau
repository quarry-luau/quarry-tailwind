--!strict
-- The UISizeConstraint of min and max sizes. CSS counts padding and border
-- inside them (border-box); Roblox constrains the content and adds padding
-- after, so the insets come off here.

local Box = require("./Box")
local Declarations = require("../../Compiler/Declarations")

type Declarations = Declarations.Declarations
type Length = Declarations.Length
type Properties = Box.Properties

local function pixels(value: Length?, inset: number, fallback: number): number
	return if value and value.kind == "px"
		then math.max(0, value.value - inset)
		else fallback
end

local function build(style: Declarations): Properties?
	local minWidth, minHeight = style.minWidth, style.minHeight
	local maxWidth, maxHeight = style.maxWidth, style.maxHeight
	if not (minWidth or minHeight or maxWidth or maxHeight) then
		return nil
	end
	local border = 2 * (style.borderWidth or 0)
	local x = (style.paddingLeft or 0) + (style.paddingRight or 0) + border
	local y = (style.paddingTop or 0) + (style.paddingBottom or 0) + border
	local properties: Properties = {
		MinSize = Vector2.new(
			pixels(minWidth, x, 0),
			pixels(minHeight, y, 0)
		),
		MaxSize = Vector2.new(
			pixels(maxWidth, x, math.huge),
			pixels(maxHeight, y, math.huge)
		),
	}
	return properties
end

return { build = build }
