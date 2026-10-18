--!strict
-- Something that comes and goes with an animation, as tailwindcss-animate
-- (`animate-in fade-in-0 zoom-in-95`) and motion (`initial`, `exit`) do: it
-- enters from `from` (opacity, scale, offset) when `show` turns on and
-- leaves to it when `show` turns off, staying mounted until it has left.
-- While it moves its content fades as a whole (Fade), and it takes no input
-- while it leaves. Where its parent stretches a block across, its frames
-- fill the width as the block would; at the top of a screen (a dialog in a
-- Portal) they fill the screen and zoom about its centre.

local Bezier = require("../Motion/Bezier")
local Context = require("../Element/Context")
local Fade = require("./Fade")
local Placement = require("../Style/Rules/Placement")
local React = require("../../React")
local Timing = require("../Motion/Timing")
local useReducedMotion = require("../Motion/useReducedMotion")
local useTween = require("../Motion/useTween")

export type From = { opacity: number?, scale: number?, x: number?, y: number? }
export type Preset = { from: From, timing: Timing.Timing }
export type Props = {
	show: boolean,
	from: From,
	timing: Timing.Timing,
	-- How it leaves; the entering timing when nil.
	exit: Timing.Timing?,
	-- Whether it plays its entrance when it mounts shown (true when nil).
	appear: boolean?,
	layoutOrder: number?,
	-- Its order among siblings drawn over each other (a dialog over its
	-- overlay).
	zIndex: number?,
	children: React.ReactNode?,
}

-- Its frames' size, automatic size and origin where it sits.
type Box = {
	size: UDim2,
	automatic: Enum.AutomaticSize,
	origin: UDim2,
	screen: boolean,
}

local CENTRE = Vector2.new(0.5, 0.5)

local e = React.createElement

local function lerp(from: number, to: number, alpha: number): number
	return from + (to - from) * alpha
end

-- `context` for content drawn at `zoom` as well, so its text keeps its
-- full-size width (Label).
local function zoomed(context: Context.Value, zoom: React.Binding<number>)
	local value = table.clone(context)
	local both = { parent = context.scale, zoom = zoom }
	value.scale = React.joinBindings(both):map(
		function(values: { parent: number, zoom: number }): number
			return values.parent * values.zoom
		end
	)
	return value
end

-- Keeps it mounted until it has left, and notes when it has settled in.
local function useMounted(
	show: boolean,
	appear: boolean,
	duration: number
): (boolean, boolean)
	local reduced = useReducedMotion()
	local mounted, setMounted = React.useState(show)
	local settled, setSettled =
		React.useState(show and (reduced or not appear))
	React.useEffect(function(): (() -> ())?
		local instant = reduced or (show and not appear)
		if show then
			setMounted(true)
		else
			setSettled(false)
		end
		local thread = task.delay(
			if instant then 0 else duration,
			function()
				if show then
					setSettled(true)
				else
					setMounted(false)
				end
			end
		)
		return function()
			task.cancel(thread)
		end
	end, { show })
	return mounted or show, settled and show
end

local function boxOf(context: Context.Value): Box
	local screen = context.placement.flow == "root"
	local fills = Placement.fills(context.placement)
	return {
		size = if screen
			then UDim2.fromScale(1, 1)
			elseif fills then UDim2.fromScale(1, 0)
			else UDim2.new(),
		automatic = if screen
			then Enum.AutomaticSize.None
			elseif fills then Enum.AutomaticSize.Y
			else Enum.AutomaticSize.XY,
		origin = if screen
			then UDim2.fromScale(0.5, 0.5)
			else UDim2.new(),
		screen = screen,
	}
end

-- The bindings that move it: how far it has faded in, where it sits and
-- how large it is drawn, from `shown` (0 out, 1 in).
local function motion(shown: React.Binding<number>, from: From, origin: UDim2)
	local transparency = shown:map(function(alpha: number): number
		return 1 - lerp(from.opacity or 1, 1, alpha)
	end)
	local position = shown:map(function(alpha: number): UDim2
		local x = lerp(from.x or 0, 0, alpha)
		local y = lerp(from.y or 0, 0, alpha)
		return origin + UDim2.fromOffset(x, y)
	end)
	local zoom = if from.scale
		then shown:map(function(alpha: number): number
			return lerp(from.scale or 1, 1, alpha)
		end)
		else nil
	return transparency, position, zoom
end

local function Presence(props: Props): React.ReactNode
	local context = Context.use()
	local appear = props.appear ~= false
	local timing = if props.show
		then props.timing
		else props.exit or props.timing
	local goal = if props.show then 1 else 0
	local shown = useTween(goal, timing, if appear then 0 else nil)
	local mounted, settled = useMounted(props.show, appear, timing.duration)
	if not mounted then
		return nil
	end
	local box = boxOf(context)
	local transparency, position, zoom =
		motion(shown, props.from, box.origin)
	local content = if zoom
		then e(
			Context.Provider,
			{ value = zoomed(context, zoom) },
			props.children
		)
		else props.children
	return e("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = box.automatic,
		Size = box.size,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
	}, {
		Fade = e(Fade, {
			fading = not settled,
			transparency = transparency,
			size = box.size,
			automaticSize = box.automatic,
			anchorPoint = if box.screen
				then CENTRE
				else Vector2.zero,
			position = position,
			scale = zoom,
			interactable = props.show,
		}, content),
	})
end

-- CSS's `ease`.
local EASE = Bezier.new(0.25, 0.1, 0.25, 1)
-- motion's `easeOut`.
local EASE_OUT = Bezier.new(0, 0, 0.58, 1)

local presets: { pop: Preset, rise: Preset } = {
	-- Popovers, menus and dialogs: `animate-in fade-in-0 zoom-in-95`
	-- (tailwindcss-animate: 150 ms, CSS's `ease`).
	pop = {
		from = { opacity = 0, scale = 0.95 },
		timing = { duration = 0.15, ease = EASE },
	},
	-- Content arriving: motion's `initial={{ opacity: 0, y: 10 }}` over
	-- 0.2 s.
	rise = {
		from = { opacity = 0, y = 10 },
		timing = { duration = 0.2, ease = EASE_OUT },
	},
}

return { Presence = Presence, presets = presets }
