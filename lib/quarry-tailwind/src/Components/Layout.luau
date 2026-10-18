--!strict
-- Lays its children out as a row or a stack where no element of this
-- package holds them: a layer a component draws itself (a button's swapping
-- faces), or content in a Portal anchored somewhere (a tooltip). Its
-- children size to themselves there, keeping the text style around them.

local Context = require("../Element/Context")
local React = require("../../React")

export type Props = {
	flow: "row" | "stack",
	children: React.ReactNode?,
}

local function Layout(props: Props): React.ReactNode
	local context = Context.use()
	local value = table.clone(context)
	value.placement = {
		flow = props.flow,
		stretch = false,
		centered = false,
		inline = false,
		definite = false,
	}
	value.definite = false
	value.cell = nil
	value.order = nil
	return React.createElement(
		Context.Provider,
		{ value = value },
		props.children
	)
end

return Layout
