--!strict
-- Compiles a class string against a theme into declarations per condition,
-- ordered as Tailwind orders its CSS (Variants). Within a condition a later
-- class overwrites an earlier one, as `cn()` with tailwind-merge does. A
-- rule with a transition takes the theme's duration and curve where no
-- class sets them, as Tailwind's `var(--tw-duration, ...)` falls back. A
-- class that cannot be translated is listed in `unsupported`, one whose
-- variant targets nothing Roblox has in `inert`.

local Declarations = require("@self/Declarations")
local Parse = require("@self/Parse")
local Registry = require("@self/Registry")
local Theme = require("./Theme")
local Utilities = require("@self/Utilities")
local Variants = require("@self/Variants")

type Declarations = Declarations.Declarations
export type Condition = Variants.Condition
export type Rule = { conditions: { Condition }, declarations: Declarations }
export type Compiled = {
	rules: { Rule },
	unsupported: { string },
	inert: { string },
}
export type Compiler = {
	theme: Theme.Theme,
	-- The rules of a class string, compiled once and cached.
	compile: (classes: string) -> Compiled,
}

type Builder = {
	rules: { [string]: Rule },
	order: { string },
	unsupported: { string },
	inert: { string },
}

-- The conditions of a class's variants, or why it has none.
local function conditionsOf(token: Parse.Token): ({ Condition }?, string?)
	local conditions = {}
	for _, variant in token.variants do
		local reading = Variants.read(variant)
		if reading.kind ~= "condition" then
			return nil, reading.kind
		end
		table.insert(conditions, reading.condition)
	end
	return conditions, nil
end

-- Merges `declarations` into the rule for `conditions`.
local function declare(
	builder: Builder,
	conditions: { Condition },
	declarations: Declarations
)
	local key = table.concat(conditions, "&")
	local rule = builder.rules[key]
	if rule == nil then
		table.insert(builder.order, key)
	end
	local base = if rule then rule.declarations else {}
	builder.rules[key] = {
		conditions = conditions,
		declarations = Declarations.merge(base, declarations),
	}
end

-- Adds one class to the rules being built.
local function add(builder: Builder, theme: Theme.Theme, class: string)
	local token = Parse.parse(class)
	local conditions, problem = conditionsOf(token)
	local outcome = if conditions
		then Registry.lookup(
			Utilities,
			theme,
			token.utility,
			token.modifier
		)
		else nil
	if problem == "inert" then
		table.insert(builder.inert, class)
	elseif
		conditions == nil
		or outcome == nil
		or outcome.kind == "unknown"
	then
		table.insert(builder.unsupported, class)
	elseif outcome.kind == "set" then
		declare(builder, conditions, outcome.declarations)
	end
end

-- `rule` with the theme's transition timing filled in where it is unset.
local function timed(rule: Rule, theme: Theme.Theme): Rule
	local declared = rule.declarations
	if declared.transition == nil then
		return rule
	end
	local filled = Declarations.merge(declared, {
		duration = declared.duration
			or theme.defaultTransition.duration,
		ease = declared.ease or theme.defaultTransition.ease,
	})
	return { conditions = rule.conditions, declarations = filled }
end

local function before(a: Rule, b: Rule): boolean
	local rankA, rankB =
		Variants.rank(a.conditions), Variants.rank(b.conditions)
	if rankA ~= rankB then
		return rankA < rankB
	end
	return #a.conditions < #b.conditions
end

local function compile(theme: Theme.Theme, classes: string): Compiled
	local builder: Builder =
		{ rules = {}, order = {}, unsupported = {}, inert = {} }
	for _, class in Parse.classes(classes) do
		add(builder, theme, class)
	end
	local rules: { Rule } = {}
	for _, key in builder.order do
		table.insert(rules, timed(builder.rules[key], theme))
	end
	table.sort(rules, before)
	return {
		rules = rules,
		unsupported = builder.unsupported,
		inert = builder.inert,
	}
end

-- A compiler for `theme`, caching what it compiles.
local function new(theme: Theme.Theme): Compiler
	local cache: { [string]: Compiled } = {}
	return {
		theme = theme,
		compile = function(classes: string): Compiled
			local compiled = cache[classes]
				or compile(theme, classes)
			cache[classes] = compiled
			return compiled
		end,
	}
end

-- Whether every condition of `rule` holds in `active`.
local function holds(rule: Rule, active: { [Condition]: boolean }): boolean
	for _, condition in rule.conditions do
		if not active[condition] then
			return false
		end
	end
	return true
end

-- The declarations that hold when exactly the conditions in `active` are
-- true: each matching rule in order, later ones winning, as the browser
-- cascades them. With nothing active, the base state.
local function resolve(
	compiled: Compiled,
	active: { [Condition]: boolean }
): Declarations
	local result: Declarations = {}
	for _, rule in compiled.rules do
		if holds(rule, active) then
			result = Declarations.merge(result, rule.declarations)
		end
	end
	return result
end

local NONE: { [Condition]: boolean } = {}

-- The declarations of the base state.
local function base(compiled: Compiled): Declarations
	return resolve(compiled, NONE)
end

return { new = new, resolve = resolve, base = base }
