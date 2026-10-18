--!strict
-- The design tokens class names resolve against, as Tailwind's `@theme`
-- holds them: colours, text sizes, radii, shadows, easing curves and the
-- rest, in px, seconds and sRGB. `default` is Tailwind 4's own theme; `extend`
-- lays a theme's tokens over another's, a token at a time, as a second
-- `@theme` block does.

local Color = require("./Compiler/Color")
local Default = require("@self/Default")

export type Rgba = Color.Rgba
export type Curve = { number }
export type TextSize = { size: number, lineHeight: number }
export type ShadowLayer = {
	x: number,
	y: number,
	blur: number,
	spread: number,
	color: Rgba,
}
export type Transition = { duration: number, ease: Curve }

export type Theme = {
	color: { [string]: Rgba },
	text: { [string]: TextSize },
	radius: { [string]: number },
	container: { [string]: number },
	fontWeight: { [string]: number },
	leading: { [string]: number },
	tracking: { [string]: number },
	blur: { [string]: number },
	shadow: { [string]: { ShadowLayer } },
	ease: { [string]: Curve },
	-- Numeric custom properties a class may name: `rounded-(--radius)`.
	vars: { [string]: number },
	-- The px in one spacing step (`p-1`).
	spacing: number,
	defaultTransition: Transition,
}

-- Tokens to add or replace; a namespace left out keeps every token.
export type Extension = {
	color: { [string]: Rgba }?,
	text: { [string]: TextSize }?,
	radius: { [string]: number }?,
	container: { [string]: number }?,
	fontWeight: { [string]: number }?,
	leading: { [string]: number }?,
	tracking: { [string]: number }?,
	blur: { [string]: number }?,
	shadow: { [string]: { ShadowLayer } }?,
	ease: { [string]: Curve }?,
	vars: { [string]: number }?,
	spacing: number?,
	defaultTransition: Transition?,
}

local function over<T>(base: { [string]: T }, tokens: { [string]: T }?)
	if tokens == nil then
		return base
	end
	local merged = table.clone(base)
	for name, value in tokens do
		merged[name] = value
	end
	return merged
end

local function extend(base: Theme, extension: Extension): Theme
	return {
		color = over(base.color, extension.color),
		text = over(base.text, extension.text),
		radius = over(base.radius, extension.radius),
		container = over(base.container, extension.container),
		fontWeight = over(base.fontWeight, extension.fontWeight),
		leading = over(base.leading, extension.leading),
		tracking = over(base.tracking, extension.tracking),
		blur = over(base.blur, extension.blur),
		shadow = over(base.shadow, extension.shadow),
		ease = over(base.ease, extension.ease),
		vars = over(base.vars, extension.vars),
		spacing = extension.spacing or base.spacing,
		defaultTransition = extension.defaultTransition
			or base.defaultTransition,
	}
end

local default: Theme = Default

return { default = default, extend = extend }
