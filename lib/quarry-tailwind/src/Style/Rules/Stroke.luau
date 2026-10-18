--!strict
-- The UIStroke: the border, or a ring (`ring-2`) drawn outside the box in
-- its place, since Roblox draws one stroke per element. A ring's offset is
-- not drawn. A border or ring that names no colour takes the base style's,
-- or the element's text colour (currentColor) when that is unset.

local Box = require("./Box")
local Declarations = require("../../Compiler/Declarations")

type Declarations = Declarations.Declarations
type Rgba = Declarations.Rgba
type Properties = Box.Properties

-- The base styles' border and ring colours, and the text colour the
-- element inherits.
export type Colors = { border: Rgba?, ring: Rgba?, inherited: Rgba }

local OFF: Properties = { Enabled = false }

local function stroke(
	width: number,
	color: Rgba,
	opacity: number,
	position: Enum.BorderStrokePosition
): Properties
	return {
		Enabled = width > 0,
		Thickness = width,
		Color = Box.color3(color),
		Transparency = 1 - color.a * opacity,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = position,
	}
end

local function build(style: Declarations, colors: Colors): Properties?
	local opacity = Declarations.opacity(style)
	local ring, border = style.ringWidth, style.borderWidth
	local current = style.textColor or colors.inherited
	if ring and ring > 0 then
		local color = style.ringColor or colors.ring or current
		return stroke(
			ring,
			color,
			opacity,
			Enum.BorderStrokePosition.Outer
		)
	elseif border then
		local color = style.borderColor or colors.border or current
		return stroke(
			border,
			color,
			opacity,
			Enum.BorderStrokePosition.Inner
		)
	end
	-- A state that removes a ring (`ring-0`) turns off the stroke it drew.
	return if ring then OFF else nil
end

return { build = build }
