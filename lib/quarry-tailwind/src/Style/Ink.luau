--!strict
-- Text takes its colour from the nearest ancestor that styles text or sets
-- an opacity, its scope; the rules of the scope's ink colour the labels and
-- icons tagged with it, in each of the scope's states, with the scope's
-- opacity folded into the alpha as CSS opacity would fade them. A label in
-- a state's colour sits under `.tw12.s-hover >> TextLabel.ink4`, which is
-- how `hover:text-*` on a button recolours its label.

local Compiler = require("../Compiler")
local Declarations = require("../Compiler/Declarations")
local Hosts = require("./Hosts")
local Sheet = require("./Sheet")
local Text = require("../Compiler/Text")
local Transitions = require("./Transitions")

type Declarations = Declarations.Declarations

local inks: { [string]: string } = {}
local parents: { [string]: Text.Style } = {}

local Ink = {}

-- The text and image rules colouring what is inked `tag`, for the scope
-- style `style` over `parent`, inside what `prefix` selects (everywhere
-- when nil).
function Ink.rules(
	tag: string,
	prefix: string?,
	parent: Text.Style,
	style: Declarations
): (StyleRule, StyleRule)
	local resolved = Text.resolve(parent, style).color
	local alpha = resolved.a * Declarations.opacity(style)
	local color = Color3.fromRGB(resolved.r, resolved.g, resolved.b)
	local function target(class: string): string
		return if prefix
			then `{prefix} >> {class}.{tag}`
			else `{class}.{tag}`
	end
	local text = Sheet.rule(
		target("TextLabel"),
		{ TextColor3 = color, TextTransparency = 1 - alpha }
	)
	local image = Sheet.rule(
		target("ImageLabel"),
		{ ImageColor3 = color, ImageTransparency = 1 - alpha }
	)
	return text, image
end

local function colorsText(style: Declarations): boolean
	return style.textColor ~= nil
		or style.opacity ~= nil
		or style.invisible ~= nil
end

-- The states of `scope` that change its text's colour, the base first.
local function statesOf(scope: Hosts.Host?): { { string } }
	local states: { { string } } = { {} }
	if scope == nil then
		return states
	end
	for _, rule in scope.compiled.rules do
		if #rule.conditions > 0 and colorsText(rule.declarations) then
			table.insert(states, rule.conditions)
		end
	end
	return states
end

local function build(tag: string, scope: Hosts.Host?, parent: Text.Style)
	for index, conditions in statesOf(scope) do
		local prefix = if index == 1
				or scope == nil
			then nil
			else Sheet.selector(scope.tag, conditions)
		local style = if scope
			then Compiler.resolve(
				scope.compiled,
				Hosts.set(conditions)
			)
			else {}
		if index == 1 then
			local text, image = Ink.rules(tag, nil, parent, style)
			Transitions.ink(style, text, image)
		elseif prefix then
			Ink.rules(tag, prefix, parent, style)
		end
	end
end

-- The ink tag for text whose nearest text-styling ancestor is `scope` (nil
-- at the root), inheriting `parent`.
function Ink.get(scope: Hosts.Host?, parent: Text.Style): string
	local color = parent.color
	local key = `{if scope then scope.tag else "root"}|`
		.. `{color.r},{color.g},{color.b},{color.a}`
	local existing = inks[key]
	if existing then
		return existing
	end
	local tag = Sheet.tag("ink")
	build(tag, scope, parent)
	inks[key] = tag
	parents[tag] = parent
	return tag
end

-- The style the text inked `tag` inherits from outside its scope.
function Ink.parent(tag: string): Text.Style?
	return parents[tag]
end

return Ink
