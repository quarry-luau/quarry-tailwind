--!strict
-- Type checks both packages and their tests with luau-lsp, against the
-- Roblox API, as the packages sit once Wally installs them (dev.project.json).
-- Usage: lune run analyze (after lune run install)

local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local run = require("./run")

local DEFINITIONS_URL = "https://luau-lsp.pages.dev/globalTypes.None.d.luau"
local DEFINITIONS_PATH = ".cache/globalTypes.d.luau"

if not fs.isFile(DEFINITIONS_PATH) then
	local response = net.request(DEFINITIONS_URL)
	if not response.ok then
		print(`No Roblox definitions: HTTP {response.statusCode}`)
		process.exit(1)
	end
	fs.writeDir(".cache")
	fs.writeFile(DEFINITIONS_PATH, response.body)
end

run("rojo", { "sourcemap", "dev.project.json", "--output", "sourcemap.json" })
run("luau-lsp", {
	"analyze",
	"--platform=roblox",
	"--sourcemap=sourcemap.json",
	`--definitions=@roblox={DEFINITIONS_PATH}`,
	"--settings=.vscode/settings.json",
	"--ignore=Packages/**",
	"lib",
})
