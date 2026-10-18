--!strict
-- An element's children as ordered slots: strings become Labels in the
-- inherited ink, and elements take the order they were written in, so the
-- parent's layout keeps it. A component child (anything but an instance or
-- an element of this package) also gets its order through Context, where
-- the first element it renders picks it up, so a component never passes
-- `layoutOrder` on. Children under string keys keep their key (React's
-- `key`) and bring their own order. An element written directly as a child
-- whose classes take it out of flow (`absolute right-4 top-4`) is set
-- apart, for its parent to draw over itself. Nested lists are flattened.

local Context = require("./Context")
local Flatten = require("./Flatten")
local Label = require("./Label")
local Nodes = require("./Nodes")
local React = require("../../React")

export type Slots = { [string]: React.ReactNode }
-- What the children are read against: the context they see, the element
-- component, and whether a class string takes its element out of flow.
export type Parent = {
	value: Context.Value,
	host: Nodes.Component,
	floats: (className: string) -> boolean,
}

type Element = Nodes.Element

-- `element` at `index`; a component also gets its order through Context,
-- for the first element it renders.
local function placed(
	element: Element,
	index: number,
	parent: Parent
): React.ReactNode
	local cloned = Nodes.ordered(element, index, parent.host)
	if Nodes.isInstance(element) or Nodes.isOf(element, parent.host) then
		return cloned
	end
	local ordered = table.clone(parent.value)
	ordered.order = index
	return React.createElement(
		Context.Provider,
		{ value = ordered },
		cloned
	)
end

local function floating(element: Element, parent: Parent): boolean
	local props = element.props
	local attributes = if Nodes.isOf(element, parent.host)
			and props
		then props.attributes
		else nil
	local className = if attributes then attributes.className else nil
	return className ~= nil and parent.floats(className)
end

local function listOf(children: React.ReactNode): Nodes.List
	local list = Nodes.list(children)
	return if list then Flatten(list) else { children }
end

-- One numbered child, into the slots in flow or apart.
local function slot(
	child: React.ReactNode,
	index: number,
	parent: Parent,
	flowing: Slots,
	apart: Slots
)
	local element = Nodes.element(child)
	if type(child) == "string" then
		flowing[`Text{index}`] = React.createElement(
			Label,
			{ text = child, layoutOrder = index }
		)
	elseif element and floating(element, parent) then
		apart[`Child{index}`] = element
	elseif element then
		flowing[`Child{index}`] = placed(element, index, parent)
	end
end

-- The children in flow, and apart from them those taken out of flow.
local function slots(children: React.ReactNode, parent: Parent): (Slots, Slots)
	local flowing: Slots, apart: Slots = {}, {}
	for key, child in listOf(children) do
		local element = Nodes.element(child)
		if type(key) == "number" then
			slot(child, key, parent, flowing, apart)
		elseif element then
			local into = if floating(element, parent)
				then apart
				else flowing
			into[key] = element
		end
	end
	return flowing, apart
end

return { slots = slots }
