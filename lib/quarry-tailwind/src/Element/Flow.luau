--!strict
-- The CSS flow rules an element follows, from its base declarations: how
-- its children sit in it, whether its width is definite, whether its width
-- comes from its parent's, and its margins.

local Compiler = require("../Compiler")
local Declarations = require("../Compiler/Declarations")
local Placement = require("../Style/Rules/Placement")

type Declarations = Declarations.Declarations
type Placement = Placement.Placement

local Flow = {}

local function placement(
	flow: Placement.Flow,
	stretch: boolean,
	centered: boolean,
	definite: boolean
): Placement
	return {
		flow = flow,
		stretch = stretch,
		centered = centered,
		inline = false,
		definite = definite,
	}
end

-- How the children of an element with `style`, whose width is `definite`
-- or not, sit in it.
function Flow.children(style: Declarations, definite: boolean): Placement
	local stretches = style.alignItems == nil
		or style.alignItems == "stretch"
	if style.layout == "flex" then
		local column = style.direction == "column"
		return placement(
			if column then "column" else "row",
			column and stretches,
			false,
			definite
		)
	elseif Placement.stacks(style) then
		return placement("stack", false, true, definite)
	elseif style.layout == "grid" then
		return placement("column", stretches, false, definite)
	end
	return placement("block", true, false, definite)
end

-- Whether the element's width is definite: fixed, a fraction of a definite
-- parent, stretched from one, or growing in a definite row.
function Flow.definite(
	style: Declarations,
	placed: Placement,
	parentDefinite: boolean
): boolean
	local width, flow = style.width, placed.flow
	local stretched = (flow == "block" and not placed.inline)
		or (flow == "column" and placed.stretch)
		or (flow == "row" and style.grow ~= nil)
	if width and width.kind == "px" then
		return true
	elseif width and width.kind == "fraction" then
		return parentDefinite
	elseif Declarations.positioned(style) then
		return style.insetLeft ~= nil
			and style.insetRight ~= nil
			and parentDefinite
	end
	return flow == "root" or (stretched and parentDefinite)
end

-- Whether the element's width comes from its parent's: a fraction
-- (`w-full`), or none in a parent that stretches it across.
function Flow.widthFromParent(style: Declarations, placed: Placement): boolean
	local width = style.width
	if Declarations.positioned(style) then
		return false
	elseif width then
		return width.kind == "fraction"
	end
	return Placement.fills(placed)
end

local function px(margin: Declarations.Margin?): number
	return if type(margin) == "number" then margin else 0
end

local function hasMargin(style: Declarations): boolean
	return px(style.marginTop) ~= 0
		or px(style.marginRight) ~= 0
		or px(style.marginBottom) ~= 0
		or px(style.marginLeft) ~= 0
end

-- The margins (top, right, bottom, left) in the state `style`, nil when no
-- state of `compiled` has one, so no frame is needed to hold them; `auto`
-- counts as 0.
function Flow.margins(
	compiled: Compiler.Compiled,
	style: Declarations
): { number }?
	for _, rule in compiled.rules do
		if hasMargin(rule.declarations) then
			return {
				px(style.marginTop),
				px(style.marginRight),
				px(style.marginBottom),
				px(style.marginLeft),
			}
		end
	end
	return nil
end

return Flow
