--!strict
-- One element styled by Tailwind classes, the Roblox counterpart of a DOM
-- element with a className (Kind says which instance). Its class string is
-- a tag with rules (Style.Hosts) and each state it is in a further tag
-- (States). It tells its children how they sit in it (Flow), passes on its
-- text ink, and, when its width is definite, the width its content has, so
-- text in shrink-to-fit children wraps there as in CSS. Place supplies the
-- frames that hold its place when it is transformed, shadowed or has a
-- margin, and the frame over it for its absolute and fixed children.

local Animator = require("../Motion/Animator")
local Attributes = require("./Attributes")
local Children = require("./Children")
local Combine = require("../Style/Combine")
local Compiler = require("../Compiler")
local Config = require("../Config")
local Context = require("./Context")
local Declarations = require("../Compiler/Declarations")
local Edges = require("./Edges")
local Flow = require("./Flow")
local Hosts = require("../Style/Hosts")
local Ink = require("../Style/Ink")
local Kind = require("./Kind")
local Padding = require("../Style/Rules/Padding")
local Place = require("./Place")
local Placement = require("../Style/Rules/Placement")
local Properties = require("./Properties")
local React = require("../../React")
local Shadow = require("./Shadow")
local Sheet = require("../Style/Sheet")
local Text = require("../Compiler/Text")
local TextBox = require("./TextBox")
local Timing = require("../Motion/Timing")
local Transform = require("./Transform")
local useCentre = require("./Center")
local useStates = require("./States")

type Declarations = Declarations.Declarations
type Properties = Properties.Properties

export type Props = {
	kind: Kind.Kind,
	attributes: Attributes.Attributes,
	children: React.ReactNode?,
	-- Called with the element whenever its drawn size changes.
	onSize: ((GuiObject) -> ())?,
}

-- What the element lays out with: the context its children see, and what
-- records its measured sizes.
type Layout = {
	value: Context.Value,
	definite: boolean,
	centred: useCentre.Centred,
	centring: boolean,
	setWidth: (number) -> (),
	setCell: (Vector2) -> (),
}

-- The frames around the element (Place) and what goes in and over it.
type Frame = {
	holdsPlace: boolean,
	free: boolean,
	shadow: boolean,
	rect: React.Binding<Rect>,
	setRect: (Rect) -> (),
	flowing: Children.Slots,
	apart: Children.Slots,
	edges: React.ReactNode,
}

type Element = {
	host: Hosts.Host,
	placement: Placement.Placement,
	states: useStates.States,
	base: Declarations,
	current: Declarations,
	transform: Transform.Transform,
	ink: Context.Ink,
	layout: Layout,
	frame: Frame,
	className: string,
	clickable: boolean,
}

local e = React.createElement

-- Declared here so the children of an element can tell elements of this
-- package apart (Children); defined at the end.
local Host: (props: Props) -> React.ReactNode

local function shadowName(style: Declarations): string?
	local name = style.shadow
	return if name and name ~= "none" then name else nil
end

-- Whether any state gives the element a shadow.
local function shadowed(compiled: Compiler.Compiled): boolean
	for _, rule in compiled.rules do
		if shadowName(rule.declarations) then
			return true
		end
	end
	return false
end

-- Whether a child with `className` is taken out of flow.
local function floats(className: string): boolean
	local compiled = Config.get().compiler.compile(className)
	return Declarations.positioned(Compiler.base(compiled))
end

-- The ink the element gives its text: its own when it styles text, or its
-- parent's.
local function inkFor(host: Hosts.Host, base: Declarations, parent: Context.Ink)
	local styles = false
	for _, rule in host.compiled.rules do
		styles = styles or Text.styles(rule.declarations)
	end
	if not styles then
		return parent
	end
	local style = Text.resolve(parent.style, base)
	local color = style.color
	local alpha = color.a * Declarations.opacity(base)
	local faded = table.clone(style)
	faded.color = { r = color.r, g = color.g, b = color.b, a = alpha }
	return { tag = Ink.get(host, parent.style), style = faded }
end

-- The context for absolute and fixed children: on a frame over the
-- element, with no layout.
local function overlayContext(value: Context.Value): Context.Value
	local overlay = table.clone(value)
	overlay.placement = {
		flow = "stack",
		stretch = false,
		centered = false,
		inline = false,
		definite = value.definite,
	}
	overlay.cell = nil
	return overlay
end

local function useLayout(
	base: Declarations,
	placement: Placement.Placement,
	context: Context.Value,
	ink: Context.Ink,
	scale: React.Binding<number>
): Layout
	local definite = Flow.definite(base, placement, context.definite)
	local width, setWidth = React.useState(context.available)
	local cell, setCell = React.useBinding(Vector2.zero)
	local centred = useCentre(context.cell)
	local inside = Flow.children(base, definite)
	local centring = inside.flow == "stack" and inside.centered
	return {
		value = {
			placement = inside,
			definite = definite,
			available = if definite
				then width
				else context.available,
			ink = ink,
			cell = if centring then cell else nil,
			scale = scale,
		},
		definite = definite,
		centred = centred,
		centring = centring,
		setWidth = setWidth,
		setCell = setCell,
	}
end

-- A growing element is placed by its parent's layout, so it scales where
-- it is, without a shadow. A positioned one sits in a frame filling its
-- parent and translates by its anchor.
local function useFrame(
	props: Props,
	host: Hosts.Host,
	current: Declarations,
	layout: Layout,
	inherited: Declarations.Rgba
): Frame
	local base = Compiler.base(host.compiled)
	local rect, setRect = React.useBinding(Rect.new(0, 0, 0, 0))
	local flowing, apart = Children.slots(props.children, {
		value = layout.value,
		host = Host,
		floats = floats,
	})
	local color = current.borderColor
		or Config.get().borderColor
		or current.textColor
		or inherited
	local edges =
		Edges.render(current, color, Declarations.opacity(current))
	local shadow = shadowed(host.compiled)
	local overlay = next(apart) ~= nil or edges ~= nil
	local positioned = Declarations.positioned(base)
	local transformed = Transform.transforms(host.compiled)
	return {
		holdsPlace = (transformed or shadow or overlay)
			and base.grow == nil
			and not positioned,
		free = positioned and (shadow or overlay),
		shadow = shadow,
		rect = rect,
		setRect = setRect,
		flowing = flowing,
		apart = apart,
		edges = edges,
	}
end

local function placementOf(
	props: Props,
	context: Context.Value
): Placement.Placement
	local parent = context.placement
	return {
		flow = parent.flow,
		stretch = parent.stretch,
		centered = parent.centered,
		inline = Kind.isInline(props.kind),
		definite = context.definite,
	}
end

local function useElement(props: Props, context: Context.Value): Element
	local placement = placementOf(props, context)
	local color = context.ink.style.color
	local attributes = props.attributes
	local host = Hosts.get(attributes.className or "", placement, color)
	local clickable = props.kind == "button" or attributes.onClick ~= nil
	local tracks = host.interactive or clickable
	local states = useStates(attributes, tracks)
	local animation: { boolean } = { host.animated, states.reducedMotion }
	React.useEffect(function(): (() -> ())?
		local animates = host.animated and not states.reducedMotion
		return if animates then Animator.use(Sheet.get()) else nil
	end, animation)
	local base = Compiler.base(host.compiled)
	local current = Compiler.resolve(host.compiled, states.active)
	local transform =
		Transform.use(host.compiled, states.active, context.scale)
	local ink = inkFor(host, base, context.ink)
	local layout = useLayout(base, placement, context, ink, transform.drawn)
	return {
		host = host,
		placement = placement,
		states = states,
		base = base,
		current = current,
		transform = transform,
		ink = ink,
		layout = layout,
		frame = useFrame(props, host, current, layout, color),
		className = Kind.className(props.kind, clickable, base),
		clickable = clickable,
	}
end

-- Records where a positioned element sits in the frame filling its parent.
local function measureRect(instance: GuiObject, setRect: (Rect) -> ())
	local parent = instance.Parent
	local origin = if parent and parent:IsA("GuiObject")
		then parent.AbsolutePosition
		else Vector2.zero
	local min = instance.AbsolutePosition - origin
	setRect(Rect.new(min, min + instance.AbsoluteSize))
end

-- What the element does when its drawn size changes. Whole pixels: a
-- sub-pixel change while a layout settles would re-render for nothing.
local function measurer(props: Props, element: Element): (GuiObject) -> ()
	local layout, frame = element.layout, element.frame
	local inset = Padding.insetX(element.base)
	return function(instance: GuiObject)
		local size = instance.AbsoluteSize
		if layout.definite then
			layout.setWidth(math.max(0, math.floor(size.X - inset)))
		end
		if layout.centring then
			layout.setCell(size)
		end
		if frame.holdsPlace then
			element.transform.measure(instance)
		end
		if frame.free then
			measureRect(instance, frame.setRect)
		end
		layout.centred.measure(instance)
		if props.onSize then
			props.onSize(instance)
		end
	end
end

local function tagsOf(element: Element): string
	local tags = { element.host.tag }
	for _, tag in Hosts.stateTags(element.host, element.states.active) do
		table.insert(tags, tag)
	end
	return table.concat(tags, " ")
end

local function propertiesOf(props: Props, element: Element): Properties
	local states = element.states
	local kind = Kind.properties(
		element.className,
		props.attributes.image,
		props.attributes.disabled == true,
		states.onActivated
	)
	local properties: Properties = Place.merge(states.events, kind)
	properties[React.Tag] = tagsOf(element)
	properties.Name = props.attributes.name
	properties[React.Change.AbsoluteSize] = measurer(props, element)
	if element.frame.free then
		properties[React.Change.AbsolutePosition] = function(
			instance: GuiObject
		)
			measureRect(instance, element.frame.setRect)
		end
	end
	if element.base.animation == "spin" then
		properties.Rotation = if states.reducedMotion
			then 0
			else Animator.spin
	end
	if props.kind == "input" then
		local box = TextBox.properties(
			props.attributes,
			element.ink.style,
			element.host.compiled,
			states.setFocused
		)
		properties = Place.merge(properties, box)
	end
	return properties
end

local function shadowOf(element: Element): React.ReactNode
	local frame = element.frame
	if not frame.shadow or not (frame.holdsPlace or frame.free) then
		return nil
	end
	return e(Shadow, {
		name = shadowName(element.current),
		timing = Timing.transition(element.base, "shadow"),
		radius = Declarations.radius(element.current),
		size = if frame.free
			then frame.rect:map(function(rect: Rect): UDim2
				return UDim2.fromOffset(rect.Width, rect.Height)
			end)
			else element.transform.box,
	})
end

local function overlayOf(element: Element): React.ReactNode
	local frame = element.frame
	if next(frame.apart) == nil and frame.edges == nil then
		return nil
	end
	return e(React.Fragment, nil, {
		Edges = frame.edges,
		Floating = e(
			Context.Provider,
			{ value = overlayContext(element.layout.value) },
			frame.apart
		),
	})
end

local function optionsOf(
	props: Props,
	element: Element,
	context: Context.Value
): Place.Options
	local frame, base = element.frame, element.base
	return {
		layoutOrder = props.attributes.layoutOrder or context.order,
		position = element.layout.centred.position,
		box = if frame.holdsPlace then element.transform.box else nil,
		centre = element.transform.position,
		shadow = shadowOf(element),
		overlay = overlayOf(element),
		z = base.z,
		free = if frame.free then frame.rect else nil,
		margins = Flow.margins(element.host.compiled, element.current),
		filling = Flow.widthFromParent(base, element.placement),
		stacked = element.placement.flow == "block"
			or element.placement.flow == "column",
		shrinks = Placement.shrinks(base, element.placement),
	}
end

function Host(props: Props): React.ReactNode
	Kind.check(props.kind, props.attributes)
	local context = Context.use()
	local element = useElement(props, context)
	local inkTag = element.ink.tag
	Combine(
		element.host,
		element.states.active,
		if inkTag ~= context.ink.tag then inkTag else nil
	)
	local transform = element.transform
	return Place.wrap(element.className, propertiesOf(props, element), {
		Content = e(
			Context.Provider,
			{ value = element.layout.value },
			element.frame.flowing
		),
		Scale = if transform.active
			then e("UIScale", { Scale = transform.own })
			else nil,
	}, optionsOf(props, element, context))
end

return Host
