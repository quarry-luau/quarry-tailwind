--!strict
-- The style sheet every Tailwind-styled interface links to, and the
-- primitives the rules are built with. An element's class string has a tag
-- (`tw12`); each state it is in is a further tag (`s-hover`,
-- `s-data-state-checked`, `s-min-width-1024`), so a rule for a state
-- selects both.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Box = require("./Rules/Box")
local Variants = require("../Compiler/Variants")

local NAME = "TailwindStyles"

local sheet: StyleSheet? = nil
local count = 0

local Sheet = {}

-- The style sheet, created the first time it is asked for.
function Sheet.get(): StyleSheet
	local existing = sheet
	if existing then
		return existing
	end
	local created = Instance.new("StyleSheet")
	created.Name = NAME
	created.Parent = ReplicatedStorage
	sheet = created
	return created
end

-- A tag no other host or ink has: `tw1`, `ink2`.
function Sheet.tag(prefix: string): string
	count += 1
	return `{prefix}{count}`
end

-- The tag a state puts on an element.
function Sheet.stateTag(condition: Variants.Condition): string
	return "s-" .. string.gsub(condition, "[^%w]+", "-")
end

-- The selector for the element tagged `tag` in all of `conditions`, nil
-- when one selects children instead.
function Sheet.selector(
	tag: string,
	conditions: { Variants.Condition }
): string?
	local parts = { `.{tag}` }
	for _, condition in conditions do
		if Variants.isSelector(condition) then
			return nil
		end
		table.insert(parts, `.{Sheet.stateTag(condition)}`)
	end
	return table.concat(parts)
end

-- A rule in the sheet setting `properties` on what `selector` selects.
function Sheet.rule(selector: string, properties: Box.Properties): StyleRule
	local rule = Instance.new("StyleRule")
	rule.Selector = selector
	rule:SetProperties(properties)
	rule.Parent = Sheet.get()
	return rule
end

return Sheet
