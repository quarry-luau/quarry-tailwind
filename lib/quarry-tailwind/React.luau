--!strict
-- Stands in for the React link Wally installs: the package and the types
-- the package uses.
local React = require(script.Parent.Parent.Packages.React)

export type ReactNode = React.ReactNode
export type Binding<T> = React.Binding<T>
export type ReactElement<P, T> = React.ReactElement<P, T>

return React
