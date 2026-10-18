--!strict
-- The style of one class string on an element placed one way: its tag and
-- its rules, one per state, holding every property resolved for that state
-- (the base plus each matching rule, cascaded as the browser would), in
-- Tailwind's order, since the engine applies the later of two matching
-- rules. A string compiles once per placement; one whose border or ring
-- falls back on the text colour (currentColor) once per inherited colour
-- too.

local Animator = require("../Motion/Animator")
local Compiler = require("../Compiler")
local Config = require("../Config")
local Declarations = require("../Compiler/Declarations")
local Placement = require("./Rules/Placement")
local Rules = require("./Rules")
local Sheet = require("./Sheet")
local Transitions = require("./Transitions")
local warnOnce = require("../Warn")

type Rgba = Declarations.Rgba

export type Host = {
	tag: string,
	compiled: Compiler.Compiled,
	-- The conditions its rules name: the only states it needs tags for.
	conditions: { [string]: boolean },
	-- Whether a rule depends on hover, press or focus, so the element must
	-- track them.
	interactive: boolean,
	-- Whether it pulses or spins, so the animation loop must run.
	animated: boolean,
	placement: Placement.Placement,
	tokens: Rules.Tokens,
	colors: Rules.Colors,
}

local INPUT: { [string]: boolean } =
	{ hover = true, press = true, focus = true }

local hosts: { [string]: Host } = {}

local function named(compiled: Compiler.Compiled): { [string]: boolean }
	local conditions: { [string]: boolean } = {}
	for _, rule in compiled.rules do
		for _, condition in rule.conditions do
			conditions[condition] = true
		end
	end
	return conditions
end

local function tracksInput(conditions: { [string]: boolean }): boolean
	for condition in conditions do
		if INPUT[condition] then
			return true
		end
	end
	return false
end

-- Whether a border or ring of `compiled` may fall back on the text colour.
local function usesCurrentColor(
	compiled: Compiler.Compiled,
	config: Config.Config
): boolean
	for _, rule in compiled.rules do
		local style = rule.declarations
		local bordered = style.borderWidth ~= nil
			or Declarations.hasEdges(style)
		if
			(bordered and config.borderColor == nil)
			or (style.ringWidth ~= nil and config.ringColor == nil)
		then
			return true
		end
	end
	return false
end

-- `conditions` as the set Compiler.resolve takes.
local function set(conditions: { string }): { [string]: boolean }
	local active: { [string]: boolean } = {}
	for _, condition in conditions do
		active[condition] = true
	end
	return active
end

-- The conditions of each state `host` has a rule for, the base first.
local function statesOf(host: Host): { { string } }
	local states: { { string } } = { {} }
	for _, rule in host.compiled.rules do
		if #rule.conditions > 0 then
			table.insert(states, rule.conditions)
		end
	end
	return states
end

-- Adds the rules of every state of `host`, then its base transition.
local function addRules(host: Host)
	local base: { [string]: StyleRule } = {}
	for index, conditions in statesOf(host) do
		local selector = Sheet.selector(host.tag, conditions)
		if selector == nil then
			continue
		end
		local style = Compiler.resolve(host.compiled, set(conditions))
		local targets = Rules.build(
			style,
			host.placement,
			host.tokens,
			host.colors
		)
		for target, properties in targets do
			local text = if target == ""
				then selector
				else `{selector}::{target}`
			local rule = Sheet.rule(text, properties)
			if index == 1 then
				base[target] = rule
			end
		end
	end
	Transitions.host(Compiler.base(host.compiled), base)
end

local Hosts = { set = set }

local function create(
	compiled: Compiler.Compiled,
	placement: Placement.Placement,
	inherited: Rgba
): Host
	local config = Config.get()
	local conditions = named(compiled)
	local host: Host
	host = {
		tag = Sheet.tag("tw"),
		compiled = compiled,
		conditions = conditions,
		interactive = tracksInput(conditions),
		animated = Compiler.base(compiled).animation == "spin",
		placement = placement,
		tokens = {
			pulse = function(alpha: number): string
				host.animated = true
				return Animator.pulseToken(Sheet.get(), alpha)
			end,
		},
		colors = {
			border = config.borderColor,
			ring = config.ringColor,
			inherited = inherited,
		},
	}
	addRules(host)
	return host
end

local function colorKey(color: Rgba): string
	return `{color.r},{color.g},{color.b},{color.a}`
end

-- The style of `classes` on an element placed as `placement` whose parent
-- gives its text `inherited`, built the first time it is asked for.
function Hosts.get(
	classes: string,
	placement: Placement.Placement,
	inherited: Rgba
): Host
	local config = Config.get()
	local compiled = config.compiler.compile(classes)
	local ink = if usesCurrentColor(compiled, config)
		then colorKey(inherited)
		else ""
	local key = `{classes}|{Placement.key(placement)}|{ink}`
	local found = hosts[key]
	if found then
		return found
	elseif #compiled.unsupported > 0 then
		local unknown = table.concat(compiled.unsupported, ", ")
		warnOnce(`no Roblox translation for {unknown} (in "{classes}")`)
	end
	local host = create(compiled, placement, inherited)
	hosts[key] = host
	return host
end

-- The tags for the states of `active` that a rule of `host` reads.
function Hosts.stateTags(host: Host, active: { [string]: boolean }): { string }
	local tags = {}
	for condition, on in active do
		if on and host.conditions[condition] then
			table.insert(tags, Sheet.stateTag(condition))
		end
	end
	table.sort(tags)
	return tags
end

return Hosts
