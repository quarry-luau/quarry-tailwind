--!strict
-- Checks that Declarations.merge copies every field the Declarations type
-- declares: merge names each field, so a field added to the type and not to
-- merge would be dropped without a word. Usage: lune run declarations

local fs = require("@lune/fs")
local process = require("@lune/process")

local SOURCE = "lib/quarry-tailwind/src/Compiler/Declarations.luau"

local source = fs.readFile(SOURCE)
-- One space between tokens, none inside parentheses, so a line StyLua
-- wrapped reads as one.
local flat = string.gsub(string.gsub(source, "%s+", " "), "%( ", "(")
flat = string.gsub(flat, " %)", ")")
local start = string.find(source, "export type Declarations = {", 1, true)
local body = if start
	then string.match(string.sub(source, start), "^.-\n(.-)\n}")
	else nil
local fields, missing = 0, {}
for field in string.gmatch(body or "", "([%w]+): [^\n]-%?,") do
	fields += 1
	local line = `into.{field} = pick(over.{field}, into.{field})`
	if not string.find(flat, line, 1, true) then
		table.insert(missing, field)
	end
end
if fields == 0 or #missing > 0 then
	print(`{SOURCE}: merge does not copy {table.concat(missing, ", ")}`)
	process.exit(1)
end
print(`merge copies all {fields} fields`)
