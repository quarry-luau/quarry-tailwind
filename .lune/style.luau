--!strict
-- Checks what StyLua cannot, after the Linux kernel's coding style: every
-- file is strict; no line is wider than 80 columns (tabs 8 wide); no block
-- opens more than three levels into its function; no function is longer than
-- 50 lines (a test suite's outer function excepted, as only a list of cases).
-- Lists every problem and exits 1 if there are any.
-- Usage: lune run style

local fs = require("@lune/fs")
local process = require("@lune/process")

local MAX_COLUMNS = 80
local TAB_WIDTH = 8
local MAX_DEPTH = 3
local MAX_FUNCTION_LINES = 50
local ROOTS = { "lib", ".lune" }

type Frame = { indent: number, line: number, exempt: boolean }

local problems: { string } = {}

local function report(path: string, line: number, message: string)
	table.insert(problems, `{path}:{line}: {message}`)
end

local function indentOf(text: string): number
	local tabs = string.match(text, "^\t*") or ""
	return #tabs
end

local function width(text: string): number
	local tabs = indentOf(text)
	return tabs * TAB_WIDTH + #text - tabs
end

local function opensFunction(text: string): boolean
	return string.find(text, "function%s*[%w_.:]*%s*%(") ~= nil
		and string.find(text, "%f[%w]end%f[%W]") == nil
end

local function opensBlock(text: string): boolean
	local code = string.match(text, "^\t*(.*)$") or ""
	return string.match(code, "^if%s") ~= nil
		or string.match(code, "^for%s") ~= nil
		or string.match(code, "^while%s") ~= nil
		or code == "repeat"
		or code == "do"
end

local function closes(text: string, frame: Frame): boolean
	return indentOf(text) == frame.indent
		and string.match(text, "^\t*end[%),]*$") ~= nil
end

local function checkLine(path: string, n: number, text: string, top: Frame?)
	if width(text) > MAX_COLUMNS then
		report(path, n, `{width(text)} columns, at most {MAX_COLUMNS}`)
	end
	if
		top
		and opensBlock(text)
		and indentOf(text) - top.indent > MAX_DEPTH
	then
		report(
			path,
			n,
			`a block {indentOf(text) - top.indent} levels deep`
		)
	end
end

local function checkFile(path: string)
	local lines = string.split(fs.readFile(path), "\n")
	if lines[1] ~= "--!strict" then
		report(path, 1, "does not start with --!strict")
	end
	local stack: { Frame } = {}
	for n, text in lines do
		checkLine(path, n, text, stack[#stack])
		local top = stack[#stack]
		if top and closes(text, top) then
			table.remove(stack)
			if
				not top.exempt
				and n - top.line > MAX_FUNCTION_LINES
			then
				report(
					path,
					top.line,
					`a function of {n - top.line} lines`
				)
			end
		elseif opensFunction(text) then
			local exempt = string.find(
				text,
				"Testing.Suite",
				1,
				true
			) ~= nil
			table.insert(stack, {
				indent = indentOf(text),
				line = n,
				exempt = exempt,
			})
		end
	end
end

local function walk(directory: string)
	for _, name in fs.readDir(directory) do
		local path = `{directory}/{name}`
		if fs.isDir(path) then
			walk(path)
		elseif string.match(name, "%.luau$") then
			checkFile(path)
		end
	end
end

for _, root in ROOTS do
	walk(root)
end
for _, problem in problems do
	print(problem)
end
print(`{#problems} style problems`)
if #problems > 0 then
	process.exit(1)
end
