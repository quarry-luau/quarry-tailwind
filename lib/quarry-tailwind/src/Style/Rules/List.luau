--!strict
-- The UIListLayout of a flex, block or grid container; none for a grid
-- that stacks its children in one cell. Columns and block flow stretch
-- their children across (CSS's default); rows align them with
-- VerticalAlignment alone, which puts their content where CSS does.

local Box = require("./Box")
local Declarations = require("../../Compiler/Declarations")
local Placement = require("./Placement")

type Declarations = Declarations.Declarations
type Properties = Box.Properties

local LINE: { [string]: Enum.ItemLineAlignment } = {
	start = Enum.ItemLineAlignment.Start,
	center = Enum.ItemLineAlignment.Center,
	["end"] = Enum.ItemLineAlignment.End,
	stretch = Enum.ItemLineAlignment.Stretch,
}
local ALIGN_Y: { [string]: Enum.VerticalAlignment } = {
	start = Enum.VerticalAlignment.Top,
	center = Enum.VerticalAlignment.Center,
	["end"] = Enum.VerticalAlignment.Bottom,
}
local ALIGN_X: { [string]: Enum.HorizontalAlignment } = {
	start = Enum.HorizontalAlignment.Left,
	center = Enum.HorizontalAlignment.Center,
	["end"] = Enum.HorizontalAlignment.Right,
}
local SPREAD: { [string]: Enum.UIFlexAlignment } = {
	between = Enum.UIFlexAlignment.SpaceBetween,
	around = Enum.UIFlexAlignment.SpaceAround,
	evenly = Enum.UIFlexAlignment.SpaceEvenly,
}

local function row(align: string, justify: string): Properties
	return {
		VerticalAlignment = ALIGN_Y[align]
			or Enum.VerticalAlignment.Top,
		HorizontalAlignment = ALIGN_X[justify]
			or Enum.HorizontalAlignment.Left,
		HorizontalFlex = SPREAD[justify] or Enum.UIFlexAlignment.None,
	}
end

local function column(align: string, justify: string): Properties
	return {
		ItemLineAlignment = LINE[align]
			or Enum.ItemLineAlignment.Stretch,
		HorizontalAlignment = ALIGN_X[align]
			or Enum.HorizontalAlignment.Left,
		VerticalAlignment = ALIGN_Y[justify]
			or Enum.VerticalAlignment.Top,
		VerticalFlex = SPREAD[justify] or Enum.UIFlexAlignment.None,
	}
end

local function build(style: Declarations): Properties?
	if Placement.stacks(style) then
		return nil
	end
	local horizontal = style.layout == "flex"
		and style.direction ~= "column"
	local align, justify =
		style.alignItems or "stretch", style.justify or "start"
	local gap = (if horizontal then style.gapX else style.gapY) or 0
	local properties = if horizontal
		then row(align, justify)
		else column(align, justify)
	properties.FillDirection = if horizontal
		then Enum.FillDirection.Horizontal
		else Enum.FillDirection.Vertical
	properties.SortOrder = Enum.SortOrder.LayoutOrder
	properties.Padding = UDim.new(0, gap)
	properties.Wraps = style.flexWrap == true
	return properties
end

return { build = build }
