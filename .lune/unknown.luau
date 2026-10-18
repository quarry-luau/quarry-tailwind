--!strict
-- Views of a value whose type is not known, after a check of its kind at
-- run time. Each returns nil when the value is not of that kind.

export type Fields = { [unknown]: unknown }
export type Callable = (...unknown) -> ...unknown

local Unknown = {}

-- Invariant: each caller below checked the value's kind first; the view only
-- lets it read fields or make calls, with every result still unknown.
local function view<T>(value: unknown): T
	return value :: any
end

-- The value as a table of unknown fields, when it is a table.
function Unknown.fields(value: unknown): Fields?
	return if type(value) == "table" then view(value) else nil
end

-- The value as a function of unknown arguments, when it is a function.
function Unknown.callable(value: unknown): Callable?
	return if type(value) == "function" then view(value) else nil
end

return Unknown
