--!strict
-- What each variant stands for, as a condition the element's state can
-- meet: `hover`, `active` (a press), `disabled`, `focus`, `placeholder`,
-- `aria-pressed`, `data-[state=open]`, the `[&>svg]` and `[&_p]` child
-- selectors, breakpoints (`md:`), `motion-reduce`, `pointer-coarse` and
-- `dark`. Conditions are strings so they can name a tag: "data-state=open",
-- "min-width:768", "child:svg". Rules sort in Tailwind's order (base,
-- hover, focus, active, disabled, aria and data states, child selectors,
-- breakpoints), since the style engine lets the later of two rules win
-- where CSS would also weigh specificity.

export type Condition = string
-- A variant's condition, or why it has none: it targets something Roblox
-- never has (`inert`), or it is not known.
export type Reading =
	{ kind: "condition", condition: Condition }
	| { kind: "inert" }
	| { kind: "unknown" }

local NAMED: { [string]: Condition } = {
	hover = "hover",
	active = "press",
	disabled = "disabled",
	focus = "focus",
	["focus-visible"] = "focus",
	placeholder = "placeholder",
	["aria-pressed"] = "aria-pressed",
	["data-open"] = "data-state=open",
	["data-closed"] = "data-state=closed",
	["motion-reduce"] = "reduced-motion",
	["pointer-coarse"] = "touch",
	dark = "dark",
	sm = "min-width:640",
	md = "min-width:768",
	lg = "min-width:1024",
	xl = "min-width:1280",
}

-- A file input's button, a web component's ::part, a sibling selector.
local INERT = { "^file$", "^%[&::part%(", "^%[&>[%w]+[%+~]" }

local RANK: { [Condition]: number } = {
	hover = 1,
	focus = 2,
	press = 3,
	disabled = 4,
	placeholder = 5,
	["aria-pressed"] = 6,
}
local DATA_RANK = 7
local CHILD_RANK = 8
local OTHER_RANK = 9
local BREAKPOINT_RANK = 10

local INERT_READING: Reading = { kind = "inert" }
local UNKNOWN_READING: Reading = { kind = "unknown" }

local function isInert(variant: string): boolean
	for _, pattern in INERT do
		if string.find(variant, pattern) then
			return true
		end
	end
	return false
end

local function matched(variant: string): Condition?
	local key, value =
		string.match(variant, "^data%-%[([%w%-]+)=([%w%-]+)%]$")
	local child = string.match(variant, "^%[&>(%a+)%]$")
	local descendant = string.match(variant, "^%[&_(%a+)%]$")
	if key and value then
		return `data-{key}={value}`
	elseif child then
		return `child:{child}`
	end
	return if descendant then `descendant:{descendant}` else nil
end

local function read(variant: string): Reading
	local condition = NAMED[variant] or matched(variant)
	if condition then
		return { kind = "condition", condition = condition }
	end
	return if isInert(variant) then INERT_READING else UNKNOWN_READING
end

-- Whether a condition selects children rather than the element.
local function isSelector(condition: Condition): boolean
	return string.find(condition, "^child:") ~= nil
		or string.find(condition, "^descendant:") ~= nil
end

local function rankOf(condition: Condition): number
	local width = string.match(condition, "^min%-width:(%d+)$")
	if RANK[condition] then
		return RANK[condition]
	elseif string.find(condition, "^data%-") then
		return DATA_RANK
	elseif isSelector(condition) then
		return CHILD_RANK
	end
	return if width
		then BREAKPOINT_RANK + (tonumber(width) or 0) / 10000
		else OTHER_RANK
end

-- Where a rule with `conditions` sorts: the rank of its last-ranked one.
local function rank(conditions: { Condition }): number
	local highest = 0
	for _, condition in conditions do
		highest = math.max(highest, rankOf(condition))
	end
	return highest
end

return { read = read, rank = rank, isSelector = isSelector }
