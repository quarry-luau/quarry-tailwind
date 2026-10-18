--!strict
-- Transitions, transforms and animations: `transition-colors`,
-- `transition-[opacity,transform]`, `duration-200`, `delay-75`,
-- `ease-out`, `scale-95`, `animate-spin`, `animate-pulse`. The enter and
-- exit classes of tailwindcss-animate (`animate-in fade-in-0 zoom-in-95`)
-- compile to nothing: Presence draws what they describe.

local Declarations = require("../Declarations")
local Registry = require("../Registry")
local Theme = require("../../Theme")

type Declarations = Declarations.Declarations
type Covers = Declarations.Covers

local function covers(
	colors: boolean,
	opacity: boolean,
	transform: boolean,
	shadow: boolean,
	size: boolean
): Covers
	return {
		colors = colors,
		opacity = opacity,
		transform = transform,
		shadow = shadow,
		size = size,
	}
end

-- What each CSS property in a `transition-[...]` list belongs to.
local LISTED: { { property: string, kind: string } } = {
	{ property = "color", kind = "colors" },
	{ property = "opacity", kind = "opacity" },
	{ property = "scale", kind = "transform" },
	{ property = "transform", kind = "transform" },
	{ property = "translate", kind = "transform" },
	{ property = "shadow", kind = "shadow" },
}

-- The kinds a `transition-[...]` list names; all when it names none.
local function listed(list: string): Covers
	local named: { [string]: boolean } = {}
	for _, entry in LISTED do
		if string.find(list, entry.property, 1, true) then
			named[entry.kind] = true
		end
	end
	if next(named) == nil then
		return covers(true, true, true, true, true)
	end
	return covers(
		named.colors == true,
		named.opacity == true,
		named.transform == true,
		named.shadow == true,
		false
	)
end

-- `transition` alone covers everything a state changes but the size.
local DEFAULT = covers(true, true, true, true, false)
local NAMED: { [string]: Covers } = {
	all = covers(true, true, true, true, true),
	colors = covers(true, false, false, false, false),
	opacity = covers(false, true, false, false, false),
	transform = covers(false, false, true, false, false),
	shadow = covers(false, false, false, true, false),
	none = covers(false, false, false, false, false),
}

local function transition(
	candidate: Registry.Candidate,
	_: Theme.Theme
): Declarations?
	local value = candidate.value
	local list = if value then string.match(value, "^%[(.*)%]$") else nil
	local covered = if value == nil
		then DEFAULT
		elseif list then listed(list)
		else NAMED[value]
	local found: Declarations = { transition = covered }
	return if covered then found else nil
end

-- A number of milliseconds, as seconds, set by `set`.
local function millis(set: (number) -> Declarations): Registry.Functional
	return function(candidate: Registry.Candidate, _: Theme.Theme)
		local value = if candidate.value
			then tonumber(candidate.value)
			else nil
		return if value then set(value / 1000) else nil
	end
end

local LINEAR = { 0, 0, 1, 1 }

local function ease(
	candidate: Registry.Candidate,
	theme: Theme.Theme
): Declarations?
	local name = candidate.value
	local curve = if name == "linear"
		then LINEAR
		elseif name then theme.ease[name]
		else nil
	local found: Declarations = { ease = curve }
	return if curve then found else nil
end

local function scale(
	candidate: Registry.Candidate,
	_: Theme.Theme
): Declarations?
	local value = if candidate.value then tonumber(candidate.value) else nil
	local found: Declarations =
		{ scale = if value then value / 100 else nil }
	return if value then found else nil
end

local ANIMATIONS: { [string]: Declarations.Animation } =
	{ none = "none", spin = "spin", pulse = "pulse" }

local function animate(
	candidate: Registry.Candidate,
	_: Theme.Theme
): Declarations?
	local name: Declarations.Animation? = if candidate.value
		then ANIMATIONS[candidate.value]
		else nil
	local found: Declarations = { animation = name }
	return if name then found else nil
end

local PRESENCE = "tailwindcss-animate's enter and exit; Presence draws them"

local group: Registry.Group = {
	functional = {
		transition = transition,
		duration = millis(function(seconds)
			return { duration = seconds }
		end),
		delay = millis(function(seconds)
			return { delay = seconds }
		end),
		ease = ease,
		scale = scale,
		animate = animate,
	},
	noop = {
		["^animate%-in$"] = PRESENCE,
		["^animate%-out$"] = PRESENCE,
		["^fade%-in"] = PRESENCE,
		["^fade%-out"] = PRESENCE,
		["^zoom%-in"] = PRESENCE,
		["^zoom%-out"] = PRESENCE,
		["^slide%-in%-from%-"] = PRESENCE,
		["^slide%-out%-to%-"] = PRESENCE,
		["^origin%-"] = "an element scales about its centre",
	},
}

return group
