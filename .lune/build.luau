--!strict
-- Builds the package as a Roblox model (build/quarry-tailwind.rbxm), for
-- the release's download and for places without Wally. Usage: lune run build

local fs = require("@lune/fs")
local run = require("./run")

fs.writeDir("build")
run("rojo", {
	"build",
	"lib/quarry-tailwind",
	"--output",
	"build/quarry-tailwind.rbxm",
})
