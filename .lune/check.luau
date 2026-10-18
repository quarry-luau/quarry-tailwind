--!strict
-- Everything CI checks: the license copy, the generated theme, that merge
-- covers every declaration, format, style, lint, types, tests, and that the
-- package builds.
-- Usage: lune run check (after lune run install)

local fs = require("@lune/fs")
local process = require("@lune/process")
local run = require("./run")

-- MIT asks for the notice in every copy: the package carries the root LICENSE.
if fs.readFile("lib/quarry-tailwind/LICENSE") ~= fs.readFile("LICENSE") then
	print("lib/quarry-tailwind/LICENSE differs from LICENSE; copy it over")
	process.exit(1)
end

local DEFAULT_THEME = "lib/quarry-tailwind/src/Theme/Default.luau"
local generated = fs.readFile(DEFAULT_THEME)
run("lune", { "run", "theme" })
if fs.readFile(DEFAULT_THEME) ~= generated then
	print(`{DEFAULT_THEME} was out of date with theme/tailwind.css`)
	process.exit(1)
end

run("lune", { "run", "declarations" })
run("stylua", { "--check", "lib", ".lune" })
run("lune", { "run", "style" })
run("selene", { "lib" })
run("lune", { "run", "analyze" })
run("lune", { "run", "test" })
run("lune", { "run", "build" })
print("All checks passed")
