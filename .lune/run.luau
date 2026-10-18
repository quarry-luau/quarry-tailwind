--!strict
-- Runs a command with the terminal attached and stops the script if it fails.

local process = require("@lune/process")

return function(program: string, args: { string }, cwd: string?)
	local result =
		process.exec(program, args, { stdio = "inherit", cwd = cwd })
	if not result.ok then
		local command = `{program} {table.concat(args, " ")}`
		print(`{command} failed with exit code {result.code}`)
		process.exit(
			if result.code >= 1
					and result.code <= 255
				then result.code
				else 1
		)
	end
end
