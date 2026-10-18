# Coding style

This repository follows the [Linux kernel coding style](https://docs.kernel.org/process/coding-style.html),
read for Luau, with Luau's own guidance on [typed classes](https://luau.org/types/object-oriented-programs)
and [performance](https://luau.org/performance), and the [Roblox Lua style
guide](https://roblox.github.io/lua-style-guide/) where the kernel says nothing. `lune run check`
enforces what can be checked: StyLua lays the code out, `lune run style` checks the rest.

## Layout

- Indent with tabs, eight columns wide. Lines are at most 80 columns.
- A block opens at most three levels into its function. Deeper nesting is a function to split.
- Functions are short and do one thing: at most 50 lines, and about 5 to 10 locals. A long flat
  sequence is fine; a short function three levels deep is not.
- Never break a message string to fit: shorten the words instead, so the message can be searched
  for.
- One statement per line; double quotes; no semicolons.

## Names

- Exported functions and module-level names say what they are; locals are short (`i`, `query`).
- camelCase for functions and locals, PascalCase for classes and types, LOUD_SNAKE_CASE for
  constants. Private fields and methods start with `_`.
- A name never encodes its type.
- A command does work and raises on failure; a predicate (`isStale`, `matches`) returns a boolean
  and does nothing else.

## Comments

- A comment says what a function does, at its head, never how. A body that needs comments is a
  function to split.
- A field of a type or of a data table may have its own comment.
- Every module starts with `--!strict`, then a comment saying what it is, and for a port, which
  TanStack file it ports.

## Types

- Strict mode everywhere, and no `any` without a comment directly above it, starting
  `-- Invariant:`, that says why it is safe.
- A value of unknown type is `unknown`, read through `Unknown.fields` or `Unknown.callable`.
- No cast to make a literal fit: declare the table with its type (`local data: QueryData = {...}`).

## Classes

As Luau's documentation shows: data on the instance, methods on the class, `self` typed.

```luau
local Query = {}
Query.__index = Query

type QueryData = { state: State, _retryer: Retryer? }
export type Query = typeof(setmetatable({} :: QueryData, Query))

function Query.new(): Query
	local data: QueryData = { state = initialState(), _retryer = nil }
	return setmetatable(data, Query)
end

function Query.invalidate(self: Query)
	...
end
```

Call methods with `:`. Give an instance all its fields in the one table literal, so every instance
has the same shape. Keep closures for callbacks, not for methods.

## Files

In order: `--!strict`, the module's comment, services, requires (sorted), types, constants, local
functions, the module table, its functions, `return`. One module per file, named after what it
returns.
