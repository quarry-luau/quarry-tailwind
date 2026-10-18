--!strict
-- CSS `scale` and `translate` (`active:scale-98`,
-- `data-[state=checked]:translate-x-4`), which leave the layout box alone.
-- A UIScale shrinks the box toward its corner and a list layout overrides
-- Position, so a transformed element is drawn centred in a frame that keeps
-- its unscaled size in the layout, moved from the centre by its translate,
-- both tweened along its transition. `drawn` is the scale it is drawn at,
-- its own times its ancestors', which turns a measured size back into its
-- parent's units.

local Compiler = require("../Compiler")
local Declarations = require("../Compiler/Declarations")
local React = require("../../React")
local Timing = require("../Motion/Timing")
local useTween = require("../Motion/useTween")

export type Transform = {
	-- Whether any state scales or translates the element.
	active: boolean,
	own: React.Binding<number>,
	drawn: React.Binding<number>,
	-- Where the element sits in its frame: the centre, moved by its
	-- translate.
	position: React.Binding<UDim2>,
	-- The element's unscaled size in its parent's units, for its frame.
	box: React.Binding<UDim2>,
	-- Records the element's drawn size; connect it to AbsoluteSize.
	measure: (GuiObject) -> (),
}

-- How finely an unscaled size is kept, in steps per pixel.
local PRECISION = 1000

type Moved = {
	fractionX: number,
	pixelsX: number,
	fractionY: number,
	pixelsY: number,
}

-- Whether any state of `compiled` scales or translates the element.
local function transforms(compiled: Compiler.Compiled): boolean
	for _, rule in compiled.rules do
		local style = rule.declarations
		if style.scale or style.translateX or style.translateY then
			return true
		end
	end
	return false
end

-- A translate as a fraction of the element's size and pixels.
local function split(value: Declarations.Length?): (number, number)
	if value and value.kind == "fraction" then
		return value.value, 0
	elseif value and value.kind == "px" then
		return 0, value.value
	end
	return 0, 0
end

local function useMoved(style: Declarations.Declarations, motion: Timing.Timing)
	local fractionX, pixelsX = split(style.translateX)
	local fractionY, pixelsY = split(style.translateY)
	local moved = {
		fractionX = useTween(fractionX, motion),
		pixelsX = useTween(pixelsX, motion),
		fractionY = useTween(fractionY, motion),
		pixelsY = useTween(pixelsY, motion),
	}
	return React.joinBindings(moved):map(function(values: Moved): UDim2
		return UDim2.new(
			0.5 + values.fractionX,
			values.pixelsX,
			0.5 + values.fractionY,
			values.pixelsY
		)
	end)
end

-- Size over scale lands a hair under the true size (35.9999 for 36), which
-- the layout floors, so the float error is rounded off.
local function unscaled(size: Vector2, drawn: number): UDim2
	if drawn <= 0 then
		return UDim2.new()
	end
	local function axis(measured: number): number
		return math.round(measured / drawn * PRECISION) / PRECISION
	end
	return UDim2.fromOffset(axis(size.X), axis(size.Y))
end

local function useTransform(
	compiled: Compiler.Compiled,
	active: { [string]: boolean },
	parent: React.Binding<number>
): Transform
	local style = Compiler.resolve(compiled, active)
	local motion = Timing.transition(Compiler.base(compiled), "transform")
	local own = useTween(style.scale or 1, motion)
	local position = useMoved(style, motion)
	local size, setSize = React.useBinding(Vector2.zero)
	local drawn = React.joinBindings({ own = own, parent = parent }):map(
		function(values: { own: number, parent: number }): number
			return values.own * values.parent
		end
	)
	local box = React.joinBindings({ size = size, drawn = drawn }):map(
		function(values: { size: Vector2, drawn: number }): UDim2
			return unscaled(values.size, values.drawn)
		end
	)
	return {
		active = transforms(compiled),
		own = own,
		drawn = drawn,
		position = position,
		box = box,
		measure = function(instance: GuiObject)
			setSize(instance.AbsoluteSize)
		end,
	}
end

return { use = useTransform, transforms = transforms }
