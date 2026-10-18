--!strict
-- What a styled element tells its children: how they sit in it, whether its
-- width is definite (fixed, or stretched from a definite parent; text wraps
-- only within one, as in CSS), the content width of the nearest definite
-- ancestor (where text in a shrink-to-fit element wraps), the ink their
-- text and icons take, the size of a centring grid cell (Center), the scale
-- the element is drawn at (its ancestors' scales multiplied, Transform) and
-- the position a component child was given, for the first element it
-- renders (Children).

local Config = require("../Config")
local Ink = require("../Style/Ink")
local Placement = require("../Style/Rules/Placement")
local React = require("../../React")
local Text = require("../Compiler/Text")

export type Ink = { tag: string, style: Text.Style }
export type Value = {
	placement: Placement.Placement,
	definite: boolean,
	available: number,
	ink: Ink,
	cell: React.Binding<Vector2>?,
	scale: React.Binding<number>,
	order: number?,
}

local SCREEN: Placement.Placement = {
	flow = "root",
	stretch = true,
	centered = false,
	inline = false,
	definite = true,
}

local none: Value? = nil
local Context = React.createContext(none)
local root: Value? = nil

-- The value at the top of a screen: the body's text, unscaled.
local function rootValue(): Value
	local existing = root
	if existing then
		return existing
	end
	local body = Text.body(Config.get().textColor)
	local created: Value = {
		placement = SCREEN,
		definite = true,
		available = math.huge,
		ink = { tag = Ink.get(nil, body), style = body },
		scale = (React.createBinding(1)),
	}
	root = created
	return created
end

local function use(): Value
	return React.useContext(Context) or rootValue()
end

return { Provider = Context.Provider, use = use, root = rootValue }
