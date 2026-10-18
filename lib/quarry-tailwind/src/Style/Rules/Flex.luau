--!strict
-- The UIFlexItem: growing (`flex-1`, which also shrinks unless `shrink-0`,
-- as Roblox's Fill does both), shrinking where Placement.shrinks says, and
-- an inline element in block flow keeping its own width.

local Box = require("./Box")
local Declarations = require("../../Compiler/Declarations")
local Placement = require("./Placement")

type Properties = Box.Properties

local function build(
	style: Declarations.Declarations,
	placement: Placement.Placement
): Properties?
	local item: Properties = {}
	if style.grow then
		item.FlexMode = if style.shrink == 0
			then Enum.UIFlexMode.Grow
			else Enum.UIFlexMode.Fill
		item.GrowRatio = style.grow
	elseif Placement.shrinks(style, placement) then
		item.FlexMode = Enum.UIFlexMode.Shrink
	end
	if placement.inline and placement.flow == "block" then
		item.ItemLineAlignment = Enum.ItemLineAlignment.Start
	end
	return if next(item) ~= nil then item else nil
end

return { build = build }
