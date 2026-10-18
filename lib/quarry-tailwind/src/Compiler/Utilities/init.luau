--!strict
-- Every utility the compiler knows, in one registry.

local Registry = require("./Registry")

return Registry.new({
	require("@self/Spacing"),
	require("@self/Sizing"),
	require("@self/Layout"),
	require("@self/Typography"),
	require("@self/Borders"),
	require("@self/Effects"),
	require("@self/Backgrounds"),
	require("@self/Transitions"),
	require("@self/Position"),
})
