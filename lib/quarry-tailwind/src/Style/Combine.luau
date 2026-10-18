--!strict
-- The engine has no specificity, so when two states with rules of their own
-- hold together (a checked switch that is disabled) neither rule has every
-- property right. The first time an element is in such a combination, a
-- rule for it is added, cascaded as the browser would, at a priority above
-- each alone, and the same for its ink.

local Compiler = require("../Compiler")
local Hosts = require("./Hosts")
local Ink = require("./Ink")
local Rules = require("./Rules")
local Sheet = require("./Sheet")
local Variants = require("../Compiler/Variants")

local done: { [string]: boolean } = {}

local function holds(
	rule: Compiler.Rule,
	active: { [string]: boolean }
): boolean
	if #rule.conditions == 0 then
		return false
	end
	for _, condition in rule.conditions do
		if not active[condition] or Variants.isSelector(condition) then
			return false
		end
	end
	return true
end

-- The conditions of every rule of `compiled` that holds in `active`,
-- merged and sorted, when more than one holds; nil otherwise.
local function together(
	compiled: Compiler.Compiled,
	active: { [string]: boolean }
): { string }?
	local merged: { [string]: boolean } = {}
	local holding = 0
	for _, rule in compiled.rules do
		if holds(rule, active) then
			holding += 1
			for _, condition in rule.conditions do
				merged[condition] = true
			end
		end
	end
	local list = {}
	for condition in merged do
		table.insert(list, condition)
	end
	table.sort(list)
	return if holding >= 2 then list else nil
end

local function addRules(
	host: Hosts.Host,
	selector: string,
	conditions: { string }
)
	local style = Compiler.resolve(host.compiled, Hosts.set(conditions))
	local targets =
		Rules.build(style, host.placement, host.tokens, host.colors)
	for target, properties in targets do
		local text = if target == ""
			then selector
			else `{selector}::{target}`
		Sheet.rule(text, properties).Priority = #conditions
	end
end

local function addInk(
	host: Hosts.Host,
	ink: string,
	selector: string,
	conditions: { string }
)
	local parent = Ink.parent(ink)
	if parent == nil then
		return
	end
	local style = Compiler.resolve(host.compiled, Hosts.set(conditions))
	local text, image = Ink.rules(ink, selector, parent, style)
	text.Priority = #conditions
	image.Priority = #conditions
end

-- Adds the rules for the states of `active` that hold together on an
-- element styled by `host`, and for its text when `ink` is the ink `host`
-- gives its text. Does nothing once they exist.
local function combine(
	host: Hosts.Host,
	active: { [string]: boolean },
	ink: string?
)
	local conditions = together(host.compiled, active)
	local selector = if conditions
		then Sheet.selector(host.tag, conditions)
		else nil
	local key =
		`{host.tag}|{ink or ""}|{table.concat(conditions or {}, "&")}`
	if conditions == nil or selector == nil or done[key] then
		return
	end
	done[key] = true
	addRules(host, selector, conditions)
	if ink then
		addInk(host, ink, selector, conditions)
	end
end

return combine
