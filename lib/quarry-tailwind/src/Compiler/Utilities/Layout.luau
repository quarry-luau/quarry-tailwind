--!strict
-- Display, flex and grid: `flex`, `flex-col`, `items-center`,
-- `justify-between`, `flex-1`, `shrink-0`, `hidden`, `invisible`. A display
-- utility shows the element again, as `display: flex` overrides
-- `display: none`.

local Declarations = require("../Declarations")
local Registry = require("../Registry")
local Theme = require("../../Theme")

type Align = Declarations.Align
type Justify = Declarations.Justify

-- `baseline` aligns as `center` does: Roblox has no baseline alignment.
local ALIGN: { [string]: Align } = {
	start = "start",
	center = "center",
	["end"] = "end",
	stretch = "stretch",
	baseline = "center",
}
local JUSTIFY: { [string]: Justify } = {
	start = "start",
	center = "center",
	["end"] = "end",
	between = "between",
	around = "around",
	evenly = "evenly",
}

local function items(
	candidate: Registry.Candidate,
	_: Theme.Theme
): Declarations.Declarations?
	local align: Align? = if candidate.value
		then ALIGN[candidate.value]
		else nil
	local found: Declarations.Declarations = { alignItems = align }
	return if align then found else nil
end

local function justify(
	candidate: Registry.Candidate,
	_: Theme.Theme
): Declarations.Declarations?
	local spread: Justify? = if candidate.value
		then JUSTIFY[candidate.value]
		else nil
	local found: Declarations.Declarations = { justify = spread }
	return if spread then found else nil
end

local SHARED_CELL = "a centring grid's children share its cell"

local SHOWN: Declarations.Declarations = { hidden = false }
local FLEX: Declarations.Declarations = { layout = "flex", hidden = false }
local GRID: Declarations.Declarations = { layout = "grid", hidden = false }
local HIDDEN: Declarations.Declarations = { hidden = true }
local GROW: Declarations.Declarations = { grow = 1 }

local group: Registry.Group = {
	static = {
		flex = FLEX,
		["inline-flex"] = FLEX,
		grid = GRID,
		["inline-grid"] = GRID,
		block = SHOWN,
		["inline-block"] = SHOWN,
		inline = SHOWN,
		hidden = HIDDEN,
		["sr-only"] = HIDDEN,
		invisible = { invisible = true },
		visible = { invisible = false },
		["flex-row"] = { direction = "row" },
		["flex-col"] = { direction = "column" },
		["flex-wrap"] = { flexWrap = true },
		["flex-1"] = GROW,
		grow = GROW,
		["shrink-0"] = { shrink = 0 },
		["place-items-center"] = {
			alignItems = "center",
			justify = "center",
		},
	},
	functional = { items = items, justify = justify },
	noop = {
		["^shrink$"] = "flex items shrink by default",
		["^box%-border$"] = "boxes are border-box already",
		["^isolate$"] = "Roblox has no stacking contexts to create",
		["^col%-start%-1$"] = SHARED_CELL,
		["^row%-start%-1$"] = SHARED_CELL,
	},
}

return group
