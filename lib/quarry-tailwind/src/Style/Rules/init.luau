--!strict
-- Turns the declarations of one state into Roblox properties, per target:
-- the element itself ("") and the components a StyleRule creates under it
-- (`::UICorner`, `::UIPadding`, `::UIStroke`, `::UIListLayout`,
-- `::UISizeConstraint`, `::UIFlexItem`, `::UIAspectRatioConstraint`,
-- `::UIGradient`). CSS opacity is folded into the element's own fill and
-- stroke alpha; its text gets it through the ink rules (Style.Ink).

local Box = require("@self/Box")
local Constraint = require("@self/Constraint")
local Declarations = require("../Compiler/Declarations")
local Flex = require("@self/Flex")
local Gradient = require("@self/Gradient")
local List = require("@self/List")
local Padding = require("@self/Padding")
local Placement = require("@self/Placement")
local Stroke = require("@self/Stroke")

export type Properties = Box.Properties
export type Tokens = Box.Tokens
export type Colors = Stroke.Colors
export type Targets = { [string]: Properties }

local FULL = UDim.new(1, 0)

local function corner(style: Declarations.Declarations): Properties?
	local radius = Declarations.radius(style)
	if radius == nil or radius <= 0 then
		return nil
	end
	local properties: Properties = {
		CornerRadius = if radius == math.huge
			then FULL
			else UDim.new(0, radius),
	}
	return properties
end

local function aspect(style: Declarations.Declarations): Properties?
	local ratio = style.aspect
	if ratio == nil then
		return nil
	end
	local properties: Properties = { AspectRatio = ratio }
	return properties
end

-- Every target's properties for `style` on an element placed as
-- `placement`; `colors` are what a border or ring naming none takes.
local function build(
	style: Declarations.Declarations,
	placement: Placement.Placement,
	tokens: Tokens,
	colors: Colors
): Targets
	local targets: Targets = { [""] = Box.build(style, placement, tokens) }
	local function add(target: string, properties: Properties?)
		if properties then
			targets[target] = properties
		end
	end
	add("UICorner", corner(style))
	add("UIPadding", Padding.build(style))
	add("UIStroke", Stroke.build(style, colors))
	add("UIListLayout", List.build(style))
	add("UISizeConstraint", Constraint.build(style))
	add("UIGradient", Gradient.build(style))
	add("UIFlexItem", Flex.build(style, placement))
	add("UIAspectRatioConstraint", aspect(style))
	return targets
end

return { build = build }
