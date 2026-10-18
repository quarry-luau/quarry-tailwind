--!strict
-- Splits a class into its variants and utility, as Tailwind reads a
-- candidate: `hover:bg-primary/80` is variants {"hover"}, utility
-- "bg-primary" and modifier "80". Brackets and parentheses stay whole, so
-- `data-[state=checked]:` and `rounded-(--card-radius)` survive, and `!`
-- (important) is noted.

export type Token = {
	raw: string,
	variants: { string },
	utility: string,
	-- What follows an unbracketed `/`: an opacity ("80") or a line height.
	modifier: string?,
	important: boolean,
}

-- Utilities whose value is a length, where `n/m` is a fraction (`w-1/2`),
-- not an opacity as in `bg-red-500/50`.
local FRACTIONS: { [string]: boolean } = {}
for _, root in
	{
		"w",
		"h",
		"size",
		"basis",
		"min-w",
		"max-w",
		"min-h",
		"max-h",
		"top",
		"right",
		"bottom",
		"left",
		"inset",
		"inset-x",
		"inset-y",
		"translate-x",
		"translate-y",
	}
do
	FRACTIONS[root] = true
end

-- The parts of `text` split at `separator`, ignoring separators inside []
-- or ().
local function split(text: string, separator: string): { string }
	local parts, current, depth = {}, {}, 0
	for index = 1, #text do
		local character = string.sub(text, index, index)
		if character == "[" or character == "(" then
			depth += 1
		elseif character == "]" or character == ")" then
			depth -= 1
		end
		if character == separator and depth == 0 then
			table.insert(parts, table.concat(current))
			current = {}
		else
			table.insert(current, character)
		end
	end
	table.insert(parts, table.concat(current))
	return parts
end

local function isFraction(utility: string, modifier: string): boolean
	local root = string.match(utility, "^%-?(.-)%-%d+$")
	return string.match(modifier, "^%d+$") ~= nil
		and root ~= nil
		and FRACTIONS[root] == true
end

-- `text` without a leading or trailing `!`, and whether it had one.
local function unbang(text: string): (string, boolean)
	if string.sub(text, 1, 1) == "!" then
		return string.sub(text, 2), true
	elseif string.sub(text, -1) == "!" then
		return string.sub(text, 1, -2), true
	end
	return text, false
end

local function parse(raw: string): Token
	local variants = split(raw, ":")
	local utility, important = unbang(table.remove(variants) or "")
	local pieces = split(utility, "/")
	local modifier: string? = pieces[2]
	utility = pieces[1]
	if modifier and isFraction(utility, modifier) then
		utility = `{utility}/{modifier}`
		modifier = nil
	end
	return {
		raw = raw,
		variants = variants,
		utility = utility,
		modifier = modifier,
		important = important,
	}
end

-- The classes of a class string, in order.
local function classes(text: string): { string }
	local found = {}
	for class in string.gmatch(text, "%S+") do
		table.insert(found, class)
	end
	return found
end

return { parse = parse, classes = classes }
