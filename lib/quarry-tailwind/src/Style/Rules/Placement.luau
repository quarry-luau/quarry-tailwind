--!strict
-- Where an element sits in its parent, which decides an unset width: at the
-- top of a screen, in normal (block) flow, in a flex row or column, or
-- stacked in a shared grid cell. `stretch` is true when the parent
-- stretches it across the line, `centered` when a stacked cell centres it,
-- `inline` for inline elements (span, button), which block flow does not
-- stretch, and `definite` when the parent's width is definite.

local Declarations = require("../../Compiler/Declarations")

export type Flow = "root" | "block" | "row" | "column" | "stack"
export type Placement = {
	flow: Flow,
	stretch: boolean,
	centered: boolean,
	inline: boolean,
	definite: boolean,
}

local Placement = {}

-- Whether an element without a width of its own fills its parent's width:
-- at the root, or stretched (a block in block flow, a stretching column's
-- child) across a definite parent, as in CSS.
function Placement.fills(placement: Placement): boolean
	local flow = placement.flow
	local stretched = (flow == "block" and not placement.inline)
		or (flow == "column" and placement.stretch)
	return flow == "root" or (stretched and placement.definite)
end

-- Whether a grid stacks its children in one cell: one that centres its
-- items does; any other puts each child in its own row, as a grid without
-- columns does.
function Placement.stacks(style: Declarations.Declarations): boolean
	return style.layout == "grid" and style.alignItems == "center"
end

-- Whether a flex row shrinks the element to fit: CSS shrinks every item,
-- Roblox only those not sized by content, so a fraction width (`w-full`
-- tabs sharing a row) shrinks unless `shrink-0`.
function Placement.shrinks(
	style: Declarations.Declarations,
	placement: Placement
): boolean
	local width = style.width
	return placement.flow == "row"
		and style.grow == nil
		and style.shrink ~= 0
		and width ~= nil
		and width.kind == "fraction"
end

-- A key that tells placements apart, for caching what is built per one.
function Placement.key(placement: Placement): string
	return `{placement.flow}{placement.stretch}{placement.centered}`
		.. `{placement.inline}{placement.definite}`
end

return Placement
