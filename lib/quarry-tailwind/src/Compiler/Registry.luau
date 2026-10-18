--!strict
-- The utilities the compiler knows, registered as Tailwind registers its
-- own (utilities.ts): a static utility is a whole class name (`flex`); a
-- functional one is a root and a value (`bg` with `red-500`), found by
-- trying the longest root first; a no-op is a class that compiles to
-- nothing on purpose, with the reason. Anything else is unknown, which the
-- compiler reports.

local Declarations = require("./Declarations")
local Theme = require("../Theme")

type Declarations = Declarations.Declarations

-- What a functional utility is given: the value after its root (nil for
-- the bare root, as in `border`), the modifier after `/`, and whether the
-- class was negated (`-mt-2`).
export type Candidate = {
	value: string?,
	modifier: string?,
	negative: boolean,
}
export type Functional = (Candidate, Theme.Theme) -> Declarations?
export type Outcome =
	{ kind: "set", declarations: Declarations }
	| { kind: "noop" }
	| { kind: "unknown" }

export type Group = {
	static: { [string]: Declarations }?,
	functional: { [string]: Functional }?,
	-- Functional roots that take a leading `-` (`-mt-2`).
	negative: { string }?,
	-- Lua patterns of no-ops, each with why nothing is drawn.
	noop: { [string]: string }?,
}

export type Registry = {
	static: { [string]: Declarations },
	functional: { [string]: Functional },
	negative: { [string]: boolean },
	noop: { [string]: string },
}

local UNKNOWN: Outcome = { kind = "unknown" }
local NOOP: Outcome = { kind = "noop" }

local function into<T>(from: { [string]: T }?, to: { [string]: T })
	if from == nil then
		return
	end
	for key, value in from do
		assert(to[key] == nil, `{key} is registered twice`)
		to[key] = value
	end
end

-- One registry from the groups of utilities.
local function new(groups: { Group }): Registry
	local registry: Registry =
		{ static = {}, functional = {}, negative = {}, noop = {} }
	for _, group in groups do
		into(group.static, registry.static)
		into(group.functional, registry.functional)
		into(group.noop, registry.noop)
		local negative: { string } = group.negative or {}
		for _, root in negative do
			registry.negative[root] = true
		end
	end
	return registry
end

local function isNoop(registry: Registry, utility: string): boolean
	for pattern in registry.noop do
		if string.find(utility, pattern) then
			return true
		end
	end
	return false
end

-- Calls the handler of `root`, when it has one that takes the candidate.
local function try(
	registry: Registry,
	theme: Theme.Theme,
	root: string,
	candidate: Candidate
): Declarations?
	local handler = registry.functional[root]
	if
		handler == nil
		or (candidate.negative and not registry.negative[root])
	then
		return nil
	end
	return handler(candidate, theme)
end

-- Tries `body` as a bare root, then each root it could start with, longest
-- first, with the rest as the value.
local function functional(
	registry: Registry,
	theme: Theme.Theme,
	body: string,
	candidate: Candidate
): Declarations?
	local bare = try(registry, theme, body, candidate)
	if bare then
		return bare
	end
	for index = #body - 1, 2, -1 do
		local split = {
			value = string.sub(body, index + 1),
			modifier = candidate.modifier,
			negative = candidate.negative,
		}
		local root = string.sub(body, 1, index - 1)
		local found = if string.sub(body, index, index)
				== "-"
			then try(registry, theme, root, split)
			else nil
		if found then
			return found
		end
	end
	return nil
end

-- What `utility` (with `modifier`) compiles to.
local function lookup(
	registry: Registry,
	theme: Theme.Theme,
	utility: string,
	modifier: string?
): Outcome
	local static = registry.static[utility]
	if static then
		return { kind = "set", declarations = static }
	elseif isNoop(registry, utility) then
		return NOOP
	end
	local negative = string.sub(utility, 1, 1) == "-"
	local body = if negative then string.sub(utility, 2) else utility
	local candidate =
		{ value = nil, modifier = modifier, negative = negative }
	local found = functional(registry, theme, body, candidate)
	return if found then { kind = "set", declarations = found } else UNKNOWN
end

return { new = new, lookup = lookup }
