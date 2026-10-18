--!strict
-- Runs every *.test.luau under lib/ in Lune, without Studio. A suite (see
-- testing.luau) gets test(name, body) and the assertions. Exits 1 when any
-- case fails. Usage: lune run test [filter]

local fs = require("@lune/fs")
local process = require("@lune/process")

local Unknown = require("./unknown")
local expect = require("./expect")
local load = require("./load")

local filter = process.args[1]

local function findTests(directory: string, found: { string })
	for _, name in fs.readDir(directory) do
		local path = `{directory}/{name}`
		if fs.isDir(path) then
			findTests(path, found)
		elseif
			string.match(name, "%.test%.luau$")
			and (
				filter == nil
				or string.find(path, filter, 1, true)
			)
		then
			table.insert(found, path)
		end
	end
end

local files: { string } = {}
findTests("lib", files)
table.sort(files)

local passed, failures = 0, {}
for _, path in files do
	local suite =
		Unknown.callable(load(`../{string.gsub(path, "%.luau$", "")}`))
	if not suite then
		error(`{path} must return a test suite function`)
	end
	suite(function(name: string, body: () -> ())
		local failure: string? = nil
		xpcall(body, function(message: unknown)
			failure = tostring(message)
		end)
		if failure then
			table.insert(failures, `{path} > {name}: {failure}`)
		else
			passed += 1
		end
	end, expect)
end

for _, failure in failures do
	print(`FAIL {failure}`)
end
print(`{passed} passed, {#failures} failed, {#files} files`)
if #failures > 0 then
	process.exit(1)
end
