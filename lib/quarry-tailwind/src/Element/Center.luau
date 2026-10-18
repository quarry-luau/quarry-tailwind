--!strict
-- Centres an element in a grid cell that centres its children
-- (place-items-center). Roblox's AutomaticSize counts a child anchored at
-- its centre as half its size, so the cell would shrink; the child sits at
-- the cell's corner instead, where the cell sizes to its largest child, and
-- moves by half the difference between the two measured sizes. Under a
-- scaled ancestor the offset is off by that scale, a fraction of a pixel
-- for a press.

local React = require("../../React")

export type Centred = {
	-- The element's Position, nil outside a centring cell.
	position: React.Binding<UDim2>?,
	-- Records the element's drawn size; connect it to AbsoluteSize.
	measure: (GuiObject) -> (),
}

local function useCentre(cell: React.Binding<Vector2>?): Centred
	local size, setSize = React.useBinding(Vector2.zero)
	local function measure(instance: GuiObject)
		setSize(instance.AbsoluteSize)
	end
	if cell == nil then
		return { position = nil, measure = measure }
	end
	local position = React.joinBindings({ cell = cell, size = size }):map(
		function(values: { cell: Vector2, size: Vector2 }): UDim2
			local offset = (values.cell - values.size) / 2
			return UDim2.fromOffset(
				math.max(0, offset.X),
				math.max(0, offset.Y)
			)
		end
	)
	return { position = position, measure = measure }
end

return useCentre
