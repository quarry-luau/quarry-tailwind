--!strict
-- The Roblox font, TextSize and scale for a text style: Inter (or Roboto
-- Mono for `font-mono`) at the whole size calibrated to Chrome's widths
-- (FontSize), with a UIScale past TextSize's limit of 100.

local FontSize = require("../Compiler/FontSize")
local Text = require("../Compiler/Text")

local SANS = "rbxassetid://12187365364"
local MONO = "rbxasset://fonts/families/RobotoMono.json"

export type Typeface = {
	font: Font,
	textSize: number,
	-- The UIScale the text needs, 1 below TextSize's limit.
	scale: number,
	-- The CSS line height, in the text's own (unscaled) units.
	lineHeight: number,
}

local function resolve(style: Text.Style): Typeface
	local size = FontSize.resolve(style.family, style.weight, style.size)
	local weight = Enum.FontWeight:FromValue(style.weight)
		or Enum.FontWeight.Regular
	return {
		font = Font.new(
			if style.family == "mono" then MONO else SANS,
			weight
		),
		textSize = size.textSize,
		scale = size.scale,
		lineHeight = Text.lineHeight(style) / size.scale,
	}
end

return { resolve = resolve }
