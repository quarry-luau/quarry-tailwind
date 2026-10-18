--!strict
-- Writes src/Theme/Default.luau from Tailwind's own theme.css
-- (theme/tailwind.css), the way the browser resolves it: var() chains and
-- calc() are evaluated, rem is 16 px, durations are seconds and colours sRGB.
-- The output is formatted with StyLua, so regenerating an unchanged theme
-- changes nothing. Usage: lune run theme

local fs = require("@lune/fs")

local Color = require("../lib/quarry-tailwind/src/Compiler/Color")
local run = require("./run")

local SOURCE = "theme/tailwind.css"
local OUTPUT = "lib/quarry-tailwind/src/Theme/Default.luau"
local REM = 16
local MAX_VAR_DEPTH = 20

type Vars = { [string]: string }

-- The text inside the first block `opener` opens, braces matched, or nil.
local function block(css: string, opener: string): string?
	local start = string.find(css, opener, 1, true)
	local open = if start then string.find(css, "{", start, true) else nil
	if open == nil then
		return nil
	end
	local depth = 0
	for index = open, #css do
		local character = string.sub(css, index, index)
		depth += if character == "{"
			then 1
			elseif character == "}" then -1
			else 0
		if depth == 0 then
			return string.sub(css, open + 1, index - 1)
		end
	end
	return nil
end

-- Adds the custom property one top-level statement declares to `into`.
local function declare(statement: string, into: Vars)
	local name, value =
		string.match(statement, "%-%-([%w%-%._]+)%s*:%s*(.-)%s*$")
	if name and value then
		into[name] = (string.gsub(value, "%s+", " "))
	end
end

-- The custom properties declared at the top level of `body`; nested blocks
-- (@keyframes) are skipped.
local function declarations(body: string): Vars
	local vars: Vars = {}
	local depth = 0
	local statement = {}
	for index = 1, #body do
		local character = string.sub(body, index, index)
		if character == "{" or character == "}" then
			depth += if character == "{" then 1 else -1
			statement = {}
		elseif character == ";" and depth == 0 then
			declare(table.concat(statement), vars)
			statement = {}
		elseif depth == 0 then
			table.insert(statement, character)
		end
	end
	return vars
end

local css = string.gsub(fs.readFile(SOURCE), "/%*.-%*/", "")
local vars = declarations(
	block(css, "@theme default") or error(`no @theme default in {SOURCE}`)
)

-- The value with every var() replaced, using fallbacks for missing ones.
local function resolve(value: string, depth: number?): string
	local level = depth or 0
	if level > MAX_VAR_DEPTH then
		error(`var() cycle in {value}`)
	end
	local replaced = string.gsub(
		value,
		"var%((%-%-[^()]*)%)",
		function(inner: string): string
			local name = string.match(inner, "^%-%-([%w%-%._]+)")
				or ""
			local fallback = string.match(inner, ",%s*(.-)%s*$")
				or ""
			local found = vars[name]
			if found then
				return resolve(found, level + 1)
			end
			return if fallback ~= "" then fallback else "initial"
		end
	)
	return if string.find(replaced, "var%(")
		then resolve(replaced, level + 1)
		else replaced
end

-- `text` split at its last top-level + - * / operator, or nil.
local function splitOperator(text: string): (string?, string?, string?)
	local depth, found = 0, nil
	for index = 1, #text do
		local character = string.sub(text, index, index)
		depth += if character == "("
			then 1
			elseif character == ")" then -1
			else 0
		local spaced = string.sub(text, index - 1, index - 1) == " "
		if
			depth == 0
			and spaced
			and string.find(character, "[%+%-%*/]")
		then
			found = index
		end
	end
	if found == nil then
		return nil, nil, nil
	end
	return string.sub(text, 1, found - 2),
		string.sub(text, found, found),
		string.sub(text, found + 2)
end

local UNITS: { [string]: number } =
	{ rem = REM, px = 1, [""] = 1, s = 1, ms = 0.001 }

local function apply(a: number, operator: string, b: number): number
	return if operator == "+"
		then a + b
		elseif operator == "-" then a - b
		elseif operator == "*" then a * b
		else a / b
end

-- A length in px, a duration in seconds or a plain number, evaluating
-- calc() with + - * /.
local function measure(value: string): number?
	local text = string.gsub(resolve(value), "^%s*(.-)%s*$", "%1")
	local inner = string.match(text, "^calc(%b())$")
		or string.match(text, "^(%b())$")
	if inner then
		return measure(string.sub(inner, 2, -2))
	end
	local left, operator, right = splitOperator(text)
	if left and operator and right then
		local a, b = measure(left), measure(right)
		return if a and b then apply(a, operator, b) else nil
	end
	local amount, unit = string.match(text, "^(-?[%d.]+)(%a*)$")
	local number = if amount then tonumber(amount) else nil
	local scale = if unit then UNITS[unit] else nil
	return if number and scale then number * scale else nil
end

local function bezier(value: string): { number }?
	local found = string.match(resolve(value), "cubic%-bezier%(([^)]*)%)")
	if found == nil then
		return nil
	end
	local points = {}
	for point in string.gmatch(found, "[^,%s]+") do
		table.insert(points, tonumber(point) or 0)
	end
	return if #points == 4 then points else nil
end

local function sortedKeys<T>(map: { [string]: T }): { string }
	local keys = {}
	for key in map do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

local KEYWORDS: { [string]: boolean } = {}
local WORDS = "and break continue do else elseif end export false for "
	.. "function if in local nil not or repeat return then true type until "
	.. "while"
for _, word in string.split(WORDS, " ") do
	KEYWORDS[word] = true
end

local function luaKey(key: string): string
	return if string.match(key, "^[%a_][%w_]*$")
			and not KEYWORDS[key]
		then key
		else `["{key}"]`
end

local function number(value: number): string
	local rounded = math.round(value * 10000) / 10000
	return if rounded == math.floor(rounded)
		then string.format("%d", rounded)
		else tostring(rounded)
end

local function rgba(color: Color.Rgba): string
	return `\{ r = {color.r}, g = {color.g}, b = {color.b}, `
		.. `a = {number(color.a)} \}`
end

-- `{ key = value }` entries for every variable `prefix-key` that `read`
-- turns into Luau source.
local function entries(prefix: string, read: (string) -> string?): { string }
	local found = {}
	for _, name in sortedKeys(vars) do
		local key = string.match(name, `^{prefix}%-(.+)$`)
		local value = if key then read(vars[name]) else nil
		if key and value then
			table.insert(found, `{luaKey(key)} = {value},`)
		end
	end
	return found
end

local function length(value: string): string?
	local measured = measure(value)
	return if measured then number(measured) else nil
end

local function color(value: string): string?
	local parsed = Color.parse(resolve(value))
	return if parsed then rgba(parsed) else nil
end

local function textSize(name: string): string?
	local size = measure(vars[`text-{name}`])
	local ratio = vars[`text-{name}--line-height`]
	local lineHeight = if ratio then measure(ratio) else nil
	if size == nil or lineHeight == nil then
		return nil
	end
	local pixels = if lineHeight < 4 then lineHeight * size else lineHeight
	return `\{ size = {number(size)}, lineHeight = {number(pixels)} \}`
end

local function texts(): { string }
	local found = {}
	for _, name in sortedKeys(vars) do
		local key = string.match(name, "^text%-([%w]+)$")
		local value = if key then textSize(key) else nil
		if key and value then
			table.insert(found, `{luaKey(key)} = {value},`)
		end
	end
	return found
end

local function em(value: string): string?
	return string.match(value, "^(-?[%d.]+)em$")
end

local SHADOW = "^%s*(-?[%d.]+)p?x?%s+(-?[%d.]+)p?x?%s+(-?[%d.]+)p?x?%s+"

-- One box-shadow layer as Luau source, or nil.
local function layer(text: string): string?
	local x, y, blur, spread, tint =
		string.match(text, SHADOW .. "(-?[%d.]+)p?x?%s+(.+)$")
	if x == nil then
		x, y, blur, tint = string.match(text, SHADOW .. "(.+)$")
		spread = "0"
	end
	local parsed = if tint then Color.parse(tint) else nil
	if parsed == nil then
		return nil
	end
	return `\{ x = {x}, y = {y}, blur = {blur}, spread = {spread}, `
		.. `color = {rgba(parsed)} \}`
end

local function shadow(value: string): string?
	local layers = {}
	for text in string.gmatch(resolve(value) .. ",", "(.-%b())%s*,") do
		table.insert(layers, layer(text))
	end
	return if #layers > 0 then `\{ {table.concat(layers, ", ")} \}` else nil
end

local function curve(value: string): string?
	local points = bezier(value)
	return if points then `\{ {table.concat(points, ", ")} \}` else nil
end

-- Numeric variables a class may name directly: rounded-(--radius-lg).
local function custom(): { string }
	local found = {}
	for _, name in sortedKeys(vars) do
		local skipped = string.find(name, "^color%-")
			or string.find(name, "^text%-")
			or string.find(name, "^font%-weight")
		local value = if skipped then nil else measure(vars[name])
		if value then
			table.insert(found, `["--{name}"] = {number(value)},`)
		end
	end
	return found
end

local lines = {
	"--!strict",
	"-- Generated by `lune run theme` from Tailwind 4.1.18's theme.css",
	"-- (theme/tailwind.css); do not edit. Lengths are px, durations",
	"-- seconds, colours sRGB 0-255.",
	"",
	"return {",
}

local function section(name: string, found: { string })
	table.insert(lines, `\t{name} = \{`)
	for _, entry in found do
		table.insert(lines, `\t\t{entry}`)
	end
	table.insert(lines, "\t},")
end

local colors = entries("color", color)
section("color", colors)
section("text", texts())
section("radius", entries("radius", length))
section("container", entries("container", length))
section("fontWeight", entries("font%-weight", length))
section("leading", entries("leading", length))
section("tracking", entries("tracking", em))
section("blur", entries("blur", length))
section("shadow", entries("shadow", shadow))
section("ease", entries("ease", curve))
section("vars", custom())

local ease = bezier(vars["default-transition-timing-function"] or "")
	or { 0.4, 0, 0.2, 1 }
local duration = measure(vars["default-transition-duration"] or "") or 0.15
table.insert(lines, `\tspacing = {number(measure(vars.spacing) or 4)},`)
table.insert(
	lines,
	`\tdefaultTransition = \{ duration = {number(duration)}, `
		.. `ease = \{ {table.concat(ease, ", ")} \} \},`
)
table.insert(lines, "}")
table.insert(lines, "")
fs.writeFile(OUTPUT, table.concat(lines, "\n"))
run("stylua", { OUTPUT })
print(`{#colors} colours written to {OUTPUT}`)
