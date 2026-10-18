--!strict
-- A box whose height follows its content with a tween (300 ms,
-- cubic-bezier(0.22, 1, 0.36, 1)): CSS cannot tween a height that is
-- `auto`, and neither can AutomaticSize. The first height is taken as it
-- is; later ones tween, clipped while the box is smaller than its content.
-- The content lays out as a column (`className` adds to it) filling the
-- box's width.

local Bezier = require("../Motion/Bezier")
local Frame = require("../Motion/Frame")
local Host = require("../Element/Host")
local React = require("../../React")
local useReducedMotion = require("../Motion/useReducedMotion")

export type Props = {
	className: string?,
	layoutOrder: number?,
	children: React.ReactNode?,
}

local DURATION = 0.3
local EASE = Bezier.new(0.22, 1, 0.36, 1)
local UNMEASURED = -1

local e = React.createElement

local function AutoHeight(props: Props): React.ReactNode
	local reduced = useReducedMotion()
	local height, setHeight = React.useBinding(UNMEASURED)
	local none: RBXScriptConnection? = nil
	local tween = React.useRef(none)
	local function stop()
		if tween.current then
			tween.current:Disconnect()
			tween.current = nil
		end
	end
	local function follow(content: GuiObject)
		local from, to = height:getValue(), content.AbsoluteSize.Y
		stop()
		if from == UNMEASURED or reduced or from == to then
			setHeight(to)
			return
		end
		local started = os.clock()
		tween.current = Frame:Connect(function()
			local progress =
				math.min((os.clock() - started) / DURATION, 1)
			setHeight(from + (to - from) * EASE(progress))
			if progress >= 1 then
				stop()
			end
		end)
	end
	React.useEffect(function()
		return stop
	end, {})
	local classes = "flex flex-col w-full " .. (props.className or "")
	return e("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = props.layoutOrder,
		Size = height:map(function(value: number): UDim2
			return UDim2.new(1, 0, 0, math.max(0, value))
		end),
		AutomaticSize = height:map(
			function(value: number): Enum.AutomaticSize
				return if value == UNMEASURED
					then Enum.AutomaticSize.Y
					else Enum.AutomaticSize.None
			end
		),
	}, {
		Content = e(Host, {
			kind = "div",
			attributes = { className = classes },
			onSize = follow,
			children = props.children,
		}),
	})
end

return AutoHeight
