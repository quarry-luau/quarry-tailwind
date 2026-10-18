--!strict
-- The HTML elements the package draws and what each becomes: a TextButton
-- for `button` (and anything given onClick, as a DOM element with a click
-- handler), a TextBox for `input`, an ImageLabel for `img`, a
-- ScrollingFrame for one that scrolls (`overflow-y-auto`), a Frame
-- otherwise. `span`, `button`, `a`, `label`, `img`, `strong` and `em` are
-- inline: they keep their content's width.

local Attributes = require("./Attributes")
local Declarations = require("../Compiler/Declarations")
local Properties = require("./Properties")
local React = require("../../React")
local warnOnce = require("../Warn")

export type Kind =
	"div"
	| "section"
	| "header"
	| "footer"
	| "nav"
	| "ul"
	| "li"
	| "p"
	| "h1"
	| "h2"
	| "h3"
	| "h4"
	| "h5"
	| "h6"
	| "span"
	| "a"
	| "label"
	| "strong"
	| "em"
	| "button"
	| "img"
	| "input"

type Properties = Properties.Properties

local INLINE: { [string]: boolean } = {
	span = true,
	button = true,
	a = true,
	label = true,
	img = true,
	strong = true,
	em = true,
}
local SCROLL_BAR = 4
local SCROLL_BAR_TRANSPARENCY = 0.6

local Kind = {}

function Kind.isInline(kind: Kind): boolean
	return INLINE[kind] == true
end

-- Warns of a prop set on a kind that does not use it.
function Kind.check(kind: Kind, props: Attributes.Attributes)
	local function only(name: string, given: boolean, owner: Kind)
		if given and kind ~= owner then
			local wrong =
				`{name} works only on {owner}, not on {kind}`
			warnOnce(`{wrong} (in "{props.className or ""}")`)
		end
	end
	only("image", props.image ~= nil, "img")
	only("value", props.value ~= nil, "input")
	only("placeholder", props.placeholder ~= nil, "input")
	only("onChange", props.onChange ~= nil, "input")
	only("onSubmit", props.onSubmit ~= nil, "input")
end

function Kind.className(
	kind: Kind,
	clickable: boolean,
	base: Declarations.Declarations
): string
	if clickable then
		return "TextButton"
	elseif kind == "input" then
		return "TextBox"
	elseif kind == "img" then
		return "ImageLabel"
	end
	return if base.scrolls then "ScrollingFrame" else "Frame"
end

-- The properties an instance of `className` needs for its kind:
-- `overflow-y-auto` scrolls its content once capped (max-h-*), an image
-- fills its box, a button draws no text of its own.
function Kind.properties(
	className: string,
	image: string?,
	disabled: boolean,
	onActivated: () -> ()
): Properties
	if className == "ScrollingFrame" then
		return {
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = SCROLL_BAR,
			ScrollBarImageTransparency = SCROLL_BAR_TRANSPARENCY,
			ScrollBarImageColor3 = Color3.new(0, 0, 0),
		}
	elseif className == "ImageLabel" then
		return { Image = image or "", ScaleType = Enum.ScaleType.Crop }
	elseif className == "TextButton" then
		return {
			Text = "",
			AutoButtonColor = false,
			Selectable = not disabled,
			Interactable = not disabled,
			[React.Event.Activated] = onActivated,
		}
	end
	return {}
end

return Kind
