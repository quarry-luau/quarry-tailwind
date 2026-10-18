--!strict
-- The states an element is in, as the conditions the compiler names: hover,
-- press and focus from input (tracked only when `tracks`; a text box sets
-- its own focus), disabled, aria-pressed and data-* from props, Reduced
-- Motion, a touch-first device (`pointer-coarse:`) and breakpoints from the
-- screen's width. Returns them with the input events that drive them.

local UserInputService = game:GetService("UserInputService")

local Attributes = require("./Attributes")
local Properties = require("./Properties")
local React = require("../../React")
local useReducedMotion = require("../Motion/useReducedMotion")
local useViewport = require("../Components/useViewport")

export type States = {
	active: { [string]: boolean },
	reducedMotion: boolean,
	-- Events for the element, when it tracks input.
	events: Properties.Properties,
	onActivated: () -> (),
	setFocused: (focused: boolean) -> (),
}

local BREAKPOINTS = { 640, 768, 1024, 1280 }

type Flags = { hovered: boolean, pressed: boolean, focused: boolean }

local function isPress(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function activeStates(
	input: Attributes.Attributes,
	flags: Flags,
	width: number,
	reduced: boolean
): { [string]: boolean }
	local active: { [string]: boolean } = {
		hover = flags.hovered and not input.disabled,
		press = flags.pressed and not input.disabled,
		focus = flags.focused,
		disabled = input.disabled == true,
		["aria-pressed"] = input.pressed == true,
		["reduced-motion"] = reduced,
		touch = UserInputService.TouchEnabled
			and not UserInputService.MouseEnabled,
	}
	local data: { [string]: string } = input.data or {}
	for key, value in data do
		active[`data-{key}={value}`] = true
	end
	for _, breakpoint in BREAKPOINTS do
		active[`min-width:{breakpoint}`] = width >= breakpoint
	end
	return active
end

type Setters = {
	hover: (boolean) -> (),
	press: (boolean) -> (),
	focus: (boolean) -> (),
}

local function pointerEvents(set: Setters): Properties.Properties
	return {
		[React.Event.MouseEnter] = function()
			set.hover(true)
		end,
		[React.Event.MouseLeave] = function()
			set.hover(false)
			set.press(false)
		end,
		[React.Event.InputBegan] = function(
			_: GuiObject,
			event: InputObject
		)
			if isPress(event) then
				set.press(true)
			end
		end,
		[React.Event.InputEnded] = function(
			_: GuiObject,
			event: InputObject
		)
			if isPress(event) then
				set.press(false)
			end
		end,
		[React.Event.SelectionGained] = function()
			set.focus(true)
		end,
		[React.Event.SelectionLost] = function()
			set.focus(false)
		end,
	}
end

local function useStates(input: Attributes.Attributes, tracks: boolean): States
	local hovered, setHovered = React.useState(false)
	local pressed, setPressed = React.useState(false)
	local focused, setFocused = React.useState(false)
	local width = useViewport().X
	local reduced = useReducedMotion()
	local set =
		{ hover = setHovered, press = setPressed, focus = setFocused }
	local flags =
		{ hovered = hovered, pressed = pressed, focused = focused }
	return {
		active = activeStates(input, flags, width, reduced),
		reducedMotion = reduced,
		events = if tracks then pointerEvents(set) else {},
		onActivated = function()
			if not input.disabled and input.onClick then
				input.onClick()
			end
		end,
		setFocused = setFocused,
	}
end

return useStates
