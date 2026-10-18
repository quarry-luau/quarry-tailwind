--!strict
-- An `input`'s TextBox: its text, the hint it shows while empty (in the
-- `placeholder:` colour), its typeface and alignment in its text style, and
-- what it calls as the text changes and when Enter is pressed.

local Attributes = require("./Attributes")
local Compiler = require("../Compiler")
local Properties = require("./Properties")
local React = require("../../React")
local Text = require("../Compiler/Text")
local Typeface = require("./Typeface")

type Properties = Properties.Properties

local ALIGN: { [string]: Enum.TextXAlignment } = {
	left = Enum.TextXAlignment.Left,
	center = Enum.TextXAlignment.Center,
	right = Enum.TextXAlignment.Right,
}

local function rgb(color: Text.Style): Color3
	return Color3.fromRGB(color.color.r, color.color.g, color.color.b)
end

-- Handlers for the text changing, and for focus, which marks the box
-- focused with `setFocused` and submits on Enter.
local function handlers(
	input: Attributes.Attributes,
	setFocused: (focused: boolean) -> ()
): Properties
	return {
		[React.Change.Text] = function(box: TextBox)
			if input.onChange and box.Text ~= input.value then
				input.onChange(box.Text)
			end
		end,
		[React.Event.Focused] = function()
			setFocused(true)
		end,
		[React.Event.FocusLost] = function(
			box: TextBox,
			enter: boolean
		)
			setFocused(false)
			if enter and input.onSubmit then
				input.onSubmit(box.Text)
			end
		end,
	}
end

-- The TextBox's properties for `input` in `style`, the placeholder in the
-- style `compiled` gives under `placeholder:`.
local function properties(
	input: Attributes.Attributes,
	style: Text.Style,
	compiled: Compiler.Compiled,
	setFocused: (focused: boolean) -> ()
): Properties
	local typeface = Typeface.resolve(style)
	local placeholder = Compiler.resolve(compiled, { placeholder = true })
	local hint = Text.resolve(style, placeholder)
	local found = handlers(input, setFocused)
	found.Text = input.value or ""
	found.PlaceholderText = input.placeholder or ""
	found.ClearTextOnFocus = false
	found.FontFace = typeface.font
	found.TextSize = typeface.textSize
	found.TextColor3 = rgb(style)
	found.TextTransparency = 1 - style.color.a
	found.PlaceholderColor3 = rgb(hint)
	found.TextXAlignment = ALIGN[style.align] or Enum.TextXAlignment.Left
	found.Interactable = not input.disabled
	return found
end

return { properties = properties }
