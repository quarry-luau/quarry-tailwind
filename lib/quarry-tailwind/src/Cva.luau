--!strict
-- `cva` and `cn` as shadcn components use them (class-variance-authority,
-- clsx), so a component's variant table copies over unchanged:
-- `cva(base, { variants, defaultVariants })` returns a function from the
-- chosen variants to a class string. Conflicting classes resolve when the
-- string compiles, where a later class overrides an earlier one.

export type Config = {
	variants: { [string]: { [string]: string } },
	defaultVariants: { [string]: string }?,
}
export type Choice = { [string]: string? }

-- Joins the class strings given, skipping nil, false and "" (clsx).
local function cn(...: (string | false)?): string
	local parts = {}
	for index = 1, select("#", ...) do
		local part = select(index, ...)
		if type(part) == "string" and part ~= "" then
			table.insert(parts, part)
		end
	end
	return table.concat(parts, " ")
end

local function sortedNames(config: Config): { string }
	local names = {}
	for name in config.variants do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

local function cva(base: string, config: Config): (choice: Choice?) -> string
	local names = sortedNames(config)
	local defaults = config.defaultVariants or {}
	return function(choice: Choice?): string
		local classes = { base }
		for _, name in names do
			local picked = (if choice then choice[name] else nil)
				or defaults[name]
			local class = if picked
				then config.variants[name][picked]
				else nil
			if class and class ~= "" then
				table.insert(classes, class)
			end
		end
		return table.concat(classes, " ")
	end
end

return { cva = cva, cn = cn }
