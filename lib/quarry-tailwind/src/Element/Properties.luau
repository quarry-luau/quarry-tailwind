--!strict
-- The props of a Roblox instance element: property names and React's
-- markers (React.Tag, React.Event.Activated, React.Change.Text), mapped to
-- what each sets. React-Lua leaves its markers untyped, so a table keyed by
-- them has no precise key type; the package only builds these tables and
-- hands them to React, and never reads one back.

export type Properties = { [unknown]: unknown }

return {}
