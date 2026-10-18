--!strict
-- The theme and base styles class strings compile against. `configure`
-- sets them, once, before the first element renders, as Tailwind reads its
-- config when it builds; Tailwind 4's defaults hold otherwise. The base
-- styles are what a page's base layer sets on every element: the text
-- colour at the root (black, as CSS has it) and the colour a border or ring
-- takes when no class names one (the text colour, as in Tailwind 4).

local Color = require("./Compiler/Color")
local Compiler = require("./Compiler")
local Theme = require("./Theme")
local Values = require("./Compiler/Values")

type Rgba = Color.Rgba

export type Options = {
	-- Tokens laid over Tailwind's theme, a namespace at a time.
	theme: Theme.Extension?,
	-- Colours as a class would name them: "foreground", "gray-200",
	-- "[#e5e7eb]".
	textColor: string?,
	borderColor: string?,
	ringColor: string?,
}

export type Config = {
	theme: Theme.Theme,
	compiler: Compiler.Compiler,
	textColor: Rgba,
	-- nil: the element's text colour.
	borderColor: Rgba?,
	ringColor: Rgba?,
}

local TOO_LATE = "configure Tailwind before the first element renders"
local BLACK: Rgba = { r = 0, g = 0, b = 0, a = 1 }
local DEFAULTS: Options = {}

local options: Options = DEFAULTS
local built: Config? = nil
local used = false

local function color(theme: Theme.Theme, field: string, name: string?): Rgba?
	if name == nil then
		return nil
	end
	local found = Values.color(theme, name, nil)
	if found == nil then
		error(`Tailwind.configure: {field} "{name}" is not a colour`, 3)
	end
	return found
end

local function build(given: Options): Config
	local theme = if given.theme
		then Theme.extend(Theme.default, given.theme)
		else Theme.default
	return {
		theme = theme,
		compiler = Compiler.new(theme),
		textColor = color(theme, "textColor", given.textColor) or BLACK,
		borderColor = color(theme, "borderColor", given.borderColor),
		ringColor = color(theme, "ringColor", given.ringColor),
	}
end

local Config = {}

-- Sets the theme and base styles. Calling it again with the same table does
-- nothing; with another, once anything has rendered, is an error, since
-- what rendered was styled with the old ones.
function Config.configure(given: Options)
	if given == options then
		return
	elseif used then
		error(TOO_LATE, 2)
	end
	built = build(given)
	options = given
end

-- The configuration, fixed from the first call on.
function Config.get(): Config
	local config = built or build(options)
	built, used = config, true
	return config
end

return Config
