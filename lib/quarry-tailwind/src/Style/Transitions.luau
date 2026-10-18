--!strict
-- Puts an element's CSS transition on its base rules, as tweens the style
-- engine runs when a state changes a property: colours, opacity, and the
-- size for `transition-all` on an element given a width (a content-sized
-- one would replay the tween on every state change). The text and icon
-- colours of its ink tween along with them.

local Declarations = require("../Compiler/Declarations")
local Easing = require("../Motion/Easing")

type Declarations = Declarations.Declarations

local FILL = { "BackgroundColor3", "BackgroundTransparency" }
local STROKE = { "Color", "Transparency" }
local TEXT = { "TextColor3", "TextTransparency" }
local IMAGE = { "ImageColor3", "ImageTransparency" }

local Transitions = {}

local function info(base: Declarations, delayed: boolean): TweenInfo?
	local covers, duration, curve =
		base.transition, base.duration, base.ease
	if covers == nil or duration == nil or curve == nil then
		return nil
	end
	return Easing.tweenInfo(
		duration,
		curve,
		if delayed then base.delay or 0 else 0
	)
end

local function tween(rule: StyleRule?, properties: { string }, with: TweenInfo)
	if rule == nil then
		return
	end
	for _, property in properties do
		rule:SetPropertyTransition(property, with)
	end
end

-- Sets the transitions of `base` on the base rules, by target.
function Transitions.host(base: Declarations, rules: { [string]: StyleRule })
	local with = info(base, true)
	local covers = base.transition
	if with == nil or covers == nil then
		return
	end
	local width = base.width
	if covers.colors then
		tween(rules[""], FILL, with)
		tween(rules.UIStroke, STROKE, with)
	end
	if covers.opacity then
		tween(rules[""], { "BackgroundTransparency" }, with)
		tween(rules.UIStroke, { "Transparency" }, with)
	end
	if covers.size and width and width.kind ~= "auto" then
		tween(rules[""], { "Size" }, with)
	end
end

-- Sets the transition of the scope `base` on its ink's text and image
-- rules.
function Transitions.ink(base: Declarations, text: StyleRule, image: StyleRule)
	local with = info(base, false)
	local covers = base.transition
	if with and covers and (covers.colors or covers.opacity) then
		tween(text, TEXT, with)
		tween(image, IMAGE, with)
	end
end

return Transitions
