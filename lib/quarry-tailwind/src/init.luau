--!strict
-- Tailwind CSS for Roblox. `Tailwind.h(kind, props, ...children)` is a DOM
-- element with a className: `<button className="...">Save</button>` is
-- `Tailwind.h("button", { className = "..." }, "Save")`. The classes compile
-- into Roblox's style engine; render `Tailwind.Styles` once inside each
-- ScreenGui to apply them there. `cva` and `cn` are shadcn's variant
-- helpers; `configure` sets the theme before the first element renders.

local Attributes = require("@self/Element/Attributes")
local Bezier = require("@self/Motion/Bezier")
local Config = require("@self/Config")
local Context = require("@self/Element/Context")
local Cva = require("@self/Cva")
local Host = require("@self/Element/Host")
local Kind = require("@self/Element/Kind")
local Label = require("@self/Element/Label")
local Placement = require("@self/Style/Rules/Placement")
local Presence = require("@self/Components/Presence")
local React = require("./React")
local Sheet = require("@self/Style/Sheet")
local Text = require("@self/Compiler/Text")
local Timing = require("@self/Motion/Timing")
local warnOnce = require("@self/Warn")

export type Kind = Kind.Kind
export type Choice = Cva.Choice
export type Variants = Cva.Config
export type Preset = Presence.Preset
export type From = Presence.From
export type Options = Config.Options
export type Timing = Timing.Timing
export type Easing = Bezier.Easing
export type TextStyle = Text.Style

export type Props = Attributes.Attributes

-- The text style around a component, and its line height in px.
export type TextAround = { style: TextStyle, lineHeight: number }
-- How a component's own root sits in the element around it.
export type Slot = { fills: boolean, order: number? }

local KNOWN: { [string]: boolean } = {
	className = true,
	layoutOrder = true,
	disabled = true,
	data = true,
	pressed = true,
	onClick = true,
	name = true,
	image = true,
	value = true,
	placeholder = true,
	onChange = true,
	onSubmit = true,
}

-- Luau accepts unknown names in a table literal, so a misspelt prop
-- (`classname`) is warned of here.
local function checkNames(kind: Kind, props: Props)
	for name in props do
		if type(name) == "string" and not KNOWN[name] then
			warnOnce(`{kind} has no prop "{name}"; it is ignored`)
		end
	end
end

local function h(
	kind: Kind,
	props: Props?,
	...: React.ReactNode
): React.ReactNode
	local given: Props = props or {}
	checkNames(kind, given)
	local count = select("#", ...)
	return React.createElement(Host, {
		kind = kind,
		attributes = given,
		children = if count == 1
			then (...)
			elseif count > 1 then { ... }
			else nil,
	})
end

-- The StyleLink that applies the styles to the ScreenGui it renders in.
local function Styles(): React.ReactNode
	return React.createElement("StyleLink", { StyleSheet = Sheet.get() })
end

local function useText(): TextAround
	local style = Context.use().ink.style
	return { style = style, lineHeight = Text.lineHeight(style) }
end

local function useSlot(): Slot
	local context = Context.use()
	return {
		fills = Placement.fills(context.placement),
		order = context.order,
	}
end

return {
	configure = Config.configure,
	h = h,
	Styles = Styles,
	cn = Cva.cn,
	cva = Cva.cva,
	Text = Label,
	Glyph = require("@self/Element/Glyph"),
	Layout = require("@self/Components/Layout"),
	Presence = Presence.Presence,
	presets = Presence.presets,
	Fade = require("@self/Components/Fade"),
	AutoHeight = require("@self/Components/AutoHeight"),
	Portal = require("@self/Components/Portal"),
	useText = useText,
	useSlot = useSlot,
	useViewport = require("@self/Components/useViewport"),
	useReducedMotion = require("@self/Motion/useReducedMotion"),
	useTween = require("@self/Motion/useTween"),
	frame = require("@self/Motion/Frame"),
	bezier = Bezier.new,
	linear = require("@self/Motion/Linear").new,
	spring = require("@self/Motion/Spring").critical,
	color = require("@self/Compiler/Color").of,
}
