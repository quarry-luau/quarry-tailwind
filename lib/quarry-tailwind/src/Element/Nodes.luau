--!strict
-- Views of React children by what React takes them for. React-Lua types a
-- child only as React.ReactNode, a union no table of children can be read
-- through, so this is where the package crosses into its types, checked
-- with React's own isValidElement.

local Attributes = require("./Attributes")
local React = require("../../React")

-- Any function component, whatever props it takes.
export type Component = (props: never) -> React.ReactNode
-- An element, compared by its type; one of this package's is read for its
-- attributes.
export type Element = React.ReactElement<
	{ attributes: Attributes.Attributes? },
	string | Component
>
-- Children keyed by position or by React key.
export type List = { [string | number]: React.ReactNode }

-- Invariant: each caller below checks what React takes `node` for first
-- (an element, by isValidElement's $$typeof check, or a table that is not
-- one, which React renders as a list of children), and only reads it as
-- that, or, for an element, gives cloneElement props to merge over its own.
local function view<T>(node: React.ReactNode): T
	return node :: any
end

local function isElement(node: React.ReactNode): boolean
	return type(node) == "table" and React.isValidElement(view(node))
end

-- The node as a list of children, when React takes it for one.
local function list(node: React.ReactNode): List?
	if type(node) ~= "table" or isElement(node) then
		return nil
	end
	return view(node)
end

-- The node as an element, when it is one.
local function element(node: React.ReactNode): Element?
	return if isElement(node) then view(node) else nil
end

-- Whether `node` is an element of a Roblox instance (`"Frame"`).
local function isInstance(node: Element): boolean
	return type(node.type) == "string"
end

-- Whether `node` is an element of `component`.
local function isOf(node: Element, component: Component): boolean
	return node.type == component
end

type Ordered<P> = React.ReactElement<P, string | Component>

-- `node` with its place `index` among its siblings: an instance's
-- LayoutOrder, the layoutOrder attribute of an element of `host`, or a
-- component's layoutOrder prop.
local function ordered(
	node: Element,
	index: number,
	host: Component
): React.ReactNode
	if isInstance(node) then
		local instance: Ordered<{ LayoutOrder: number? }> = view(node)
		return React.cloneElement(instance, { LayoutOrder = index })
	elseif isOf(node, host) then
		local props = node.props
		local given = if props then props.attributes else nil
		local attributes: Attributes.Attributes =
			table.clone(given or {})
		attributes.layoutOrder = index
		return React.cloneElement(node, { attributes = attributes })
	end
	local component: Ordered<{ layoutOrder: number? }> = view(node)
	return React.cloneElement(component, { layoutOrder = index })
end

return {
	list = list,
	element = element,
	isInstance = isInstance,
	isOf = isOf,
	ordered = ordered,
}
