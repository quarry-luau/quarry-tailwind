--!strict
-- Requires a file chosen at run time, its path relative to .lune. The checker
-- cannot follow such a require, so the result is unknown and callers check
-- its shape.

-- Invariant: require accepts any path to a Luau file; only the type of what
-- it returns is unknown.
local requirePath = (require :: any) :: (path: string) -> unknown

return function(path: string): unknown
	return requirePath(path)
end
