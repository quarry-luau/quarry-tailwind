--!strict
-- The UIGradient of `bg-linear-to-r from-success from-80% to-info`, drawn
-- over a white fill. Roblox blends its stops in sRGB, Tailwind in OKLab.

local Box = require("./Box")
local Declarations = require("../../Compiler/Declarations")

type Declarations = Declarations.Declarations
type Rgba = Declarations.Rgba
type Properties = Box.Properties

-- Short of 1: a keypoint at 1 must be the last.
local MAX_STOP = 0.999
local DOWN = 90

local function clear(color: Rgba): Rgba
	return { r = color.r, g = color.g, b = color.b, a = 0 }
end

local function build(style: Declarations): Properties?
	local from, to = style.gradientFrom, style.gradientTo
	local first = from or (if to then clear(to) else nil)
	local last = to or (if first then clear(first) else nil)
	if first == nil or last == nil then
		return nil
	end
	local stop = math.clamp(style.gradientFromStop or 0, 0, MAX_STOP)
	local opacity = Declarations.opacity(style)
	local colors = { ColorSequenceKeypoint.new(0, Box.color3(first)) }
	local alphas = { NumberSequenceKeypoint.new(0, 1 - first.a * opacity) }
	if stop > 0 then
		table.insert(
			colors,
			ColorSequenceKeypoint.new(stop, Box.color3(first))
		)
		table.insert(
			alphas,
			NumberSequenceKeypoint.new(stop, 1 - first.a * opacity)
		)
	end
	table.insert(colors, ColorSequenceKeypoint.new(1, Box.color3(last)))
	table.insert(
		alphas,
		NumberSequenceKeypoint.new(1, 1 - last.a * opacity)
	)
	local properties: Properties = {
		Color = ColorSequence.new(colors),
		Transparency = NumberSequence.new(alphas),
		Rotation = style.gradientAngle or DOWN,
	}
	return properties
end

return { build = build }
