<p align="center">
  <p align="center">
    <img width="120" height="120" src="https://raw.githubusercontent.com/quarry-luau/.github/main/assets/logo.png" alt="Quarry logo">
  </p>
  <h1 align="center"><b>quarry-tailwind</b></h1>
  <p align="center">
    Tailwind CSS for Roblox: class names compiled into the native style engine, for React-Lua
    <br />
    <a href="https://wally.run/package/quarry-luau/quarry-tailwind"><strong>Wally package →</strong></a>
  </p>
</p>

<div align="center">

[![CI](https://img.shields.io/github/actions/workflow/status/quarry-luau/quarry-tailwind/ci.yml?style=for-the-badge&branch=main&logo=github&label=CI)](https://github.com/quarry-luau/quarry-tailwind/actions/workflows/ci.yml)
[![Wally](https://img.shields.io/badge/wally-quarry--luau%2Fquarry--tailwind-AD4646?style=for-the-badge)](https://wally.run/package/quarry-luau/quarry-tailwind)

</div>

quarry-tailwind lets you write Roblox interfaces the way the web writes them with
[Tailwind CSS](https://tailwindcss.com): elements with a `className`, styled by Tailwind 4's
utilities, with hover, press, focus, disabled and data states, breakpoints and transitions. It is
part of [Quarry](https://github.com/quarry-luau), open-source tools for Roblox.

The classes are not interpreted at run time. Each class string compiles once into Roblox's own
style engine (a StyleSheet of StyleRules, one rule per state), so a hover is a tag change the
engine restyles, and a transition is a tween the engine runs. Components from the web (shadcn/ui
and its `cva` variant tables) copy over with their class strings unchanged.

```lua
local e = React.createElement

Tailwind.h("div", { className = "flex items-center gap-2 rounded-lg border p-4 hover:bg-gray-50" },
	Tailwind.h("span", { className = "text-sm font-medium text-gray-900" }, "Paid"),
	e(Badge, { variant = "success" }, "New")
)
```

<details>
<summary><b>Table of Contents</b></summary>

- [At a glance](#at-a-glance)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Guides](#guides)
  - [States and variants](#states-and-variants)
  - [Components with `cva`](#components-with-cva)
  - [Your theme](#your-theme)
  - [Text](#text)
  - [Coming and going](#coming-and-going)
  - [Your own components](#your-own-components)
- [What compiles](#what-compiles)
- [Where Roblox differs](#where-roblox-differs)
- [API](#api)
- [Development](#development)
- [License](#license)

</details>

## At a glance

| Web | quarry-tailwind |
|---|---|
| `<div className="...">` | `Tailwind.h("div", { className = "..." }, ...children)` |
| `hover:`, `active:`, `focus-visible:`, `disabled:` | the same; the element tracks its own input |
| `data-[state=open]:`, `aria-pressed:` | the same, from `data = { state = "open" }` and `pressed = true` |
| `md:`, `lg:` | the same, from the screen's width |
| `transition-colors duration-200` | a tween the style engine runs |
| `cva`, `cn` | `Tailwind.cva`, `Tailwind.cn`, with the same semantics |
| `@theme` | `Tailwind.configure({ theme = ... })` |
| motion's `initial` / `exit` | `Tailwind.Presence` |
| `createPortal` | `Tailwind.Portal` |

Element names are typed, so `Tailwind.h("dvi", ...)` fails the type check. In Studio a misspelt prop
(`classname`) and a class the compiler cannot draw are each warned of once, as React warns in
development.

## Installation

```toml
# wally.toml
[dependencies]
Tailwind = "quarry-luau/quarry-tailwind@0.1.0"
React = "jsdotlua/react@17.2.1"
ReactRoblox = "jsdotlua/react-roblox@17.2.1"
```

> **Note:** the `quarry-luau` scope is waiting for Wally to approve it
> ([wally-index#131](https://github.com/UpliftGames/wally-index/pull/131)). Until then, take
> `quarry-tailwind.rbxm` from the [latest release](https://github.com/quarry-luau/quarry-tailwind/releases/latest)
> and put it next to `React` and `ReactRoblox` modules that return those packages.

## Quick start

Render `Tailwind.Styles` once inside each ScreenGui: it is the StyleLink that applies the styles
there. Give the ScreenGui `ZIndexBehavior = Sibling`, so `z-*` orders siblings as CSS does.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Tailwind = require(ReplicatedStorage.Packages.Tailwind)

local e = React.createElement
local h = Tailwind.h

local function Counter()
	local count, setCount = React.useState(0)
	return h("div", { className = "flex flex-col gap-3 rounded-xl bg-white p-6 shadow-lg" },
		h("p", { className = "text-sm text-gray-500" }, "Clicked"),
		h("p", { className = "text-3xl font-semibold" }, tostring(count)),
		h("button", {
			className = "rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white "
				.. "transition-colors hover:bg-blue-500 active:scale-95",
			onClick = function()
				setCount(count + 1)
			end,
		}, "Click me")
	)
end

local screen = Instance.new("ScreenGui")
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
ReactRoblox.createRoot(screen):render(e(React.Fragment, nil, {
	Styles = e(Tailwind.Styles),
	App = h("div", { className = "fixed top-6 left-6" }, e(Counter)),
}))
```

`span`, `button`, `a`, `label`, `img`, `strong` and `em` are inline (they keep their content's
width); `div`, `p`, `h1` to `h6`, `section` and the rest are blocks; `img` shows `image`; `input` is
a TextBox. Strings are text in the style around them. A component child needs no `layoutOrder`:
children keep the order they were written in.

## Guides

### States and variants

An element is in the states its props and input put it in, and its classes say what each state
looks like:

```lua
h("button", {
	className = "rounded-md border px-3 py-1.5 hover:bg-gray-100 disabled:opacity-50 "
		.. "data-[state=on]:bg-gray-900 data-[state=on]:text-white",
	data = { state = if on then "on" else "off" },
	disabled = locked,
	onClick = toggle,
}, "Bold")
```

When two states with rules of their own hold together (on and disabled), the compiler adds one
rule for both, cascaded as the browser would, the first time an element is in them. Breakpoints
(`sm:`, `md:`, `lg:`, `xl:`) follow the screen's width; `motion-reduce:` follows the player's
Reduced Motion setting and `pointer-coarse:` a touch-first device.

### Components with `cva`

`cva` and `cn` work as class-variance-authority and clsx do, so a shadcn component's variant table
copies over unchanged:

```lua
local button = Tailwind.cva("inline-flex items-center rounded-md text-sm font-medium transition-colors", {
	variants = {
		variant = {
			default = "bg-gray-900 text-white hover:bg-gray-800",
			outline = "border border-gray-200 bg-white hover:bg-gray-100",
		},
		size = { default = "h-9 px-4", sm = "h-8 px-3" },
	},
	defaultVariants = { variant = "default", size = "default" },
})

local function Button(props: { variant: string?, size: string?, children: React.ReactNode })
	local choice: Tailwind.Choice = { variant = props.variant, size = props.size }
	return h("button", { className = button(choice) }, props.children)
end
```

Within a state, a later class overrides an earlier one, so `cn(base, override)` behaves as with
tailwind-merge.

### Your theme

The default theme is Tailwind 4.1.18's. Call `configure` once, before anything renders, to add or
replace tokens and to set the base styles, as `@theme` and a base layer do:

```lua
Tailwind.configure({
	theme = {
		color = {
			primary = Tailwind.color("oklch(0.5076 0.2767 271.74)"),
			border = Tailwind.color("#e4e4e7"),
			foreground = Tailwind.color("#0a0a0a"),
		},
		radius = { lg = 10 },
	},
	textColor = "foreground", -- the body's text; black when unset
	borderColor = "border", -- a bare `border`; the text colour when unset, as in Tailwind 4
	ringColor = "foreground", -- a bare `ring`; the text colour when unset
})
```

A namespace you leave out keeps every default token. `Tailwind.color` reads any CSS colour
(`#hex`, `rgb()`, `oklch()`, `oklab()`). Tokens are px, seconds and sRGB 0 to 255.

### Text

Text inherits as in CSS: colour, size, weight, family, alignment, casing and wrapping pass to
children, and line height passes as a ratio or in px as it was set. Text is Inter (Roboto Mono for
`font-mono`), its TextSize calibrated per size and weight so lines come out about as wide as Chrome
draws them, with CSS's line box. It wraps when its container's width is definite and keeps its
natural width otherwise, as shrink-to-fit does.

### Coming and going

`Presence` keeps something mounted while it animates out, as motion's `exit` does:

```lua
e(Tailwind.Presence, { show = open, from = Tailwind.presets.pop.from, timing = Tailwind.presets.pop.timing },
	h("div", { className = "rounded-lg bg-white p-4 shadow-lg" }, "Saved")
)
```

`from` is any of `opacity`, `scale`, `x` and `y`. `presets.pop` is shadcn's
`animate-in fade-in-0 zoom-in-95` (150 ms, CSS `ease`) and `presets.rise` a fade and 10 px rise.
The content fades as a whole and is never remounted, so its text does not flicker. `AutoHeight`
tweens a box's height as its content changes; `Portal` draws its children on a screen of their own
above the interface.

### Your own components

A component that draws its own instances can still sit in the layout and the text style around it:

- `useText()` is the text style around the component and its line height in px.
- `Text` draws a run of text in that style; `Glyph` draws an image in its colour, as an SVG in
  `currentColor`.
- `useSlot()` says whether the component's root should fill its parent's width (`fills`) and the
  `order` it was given among its siblings.
- `Layout` lays its children out as a `row` or a `stack` where no element holds them, such as a
  layer a component draws itself.
- `useTween`, `bezier`, `linear`, `spring` and `frame` are the motion the package animates with.

## What compiles

| Area | Utilities |
|---|---|
| Spacing | `p-*`, `px-*`, `py-*`, `pt-*` and the rest, `m-*` (negative and `auto`), `gap-*`, `space-x-*`, `space-y-*` |
| Sizing | `w-*`, `h-*`, `size-*`, `min-w-*`, `min-h-*`, `max-w-*` (containers too), `max-h-*`, fractions, `full`, `fit`, `[40%]`, `[calc(100%-32px)]` |
| Layout | `flex`, `inline-flex`, `grid`, `flex-row`, `flex-col`, `flex-wrap`, `items-*`, `justify-*`, `place-items-center`, `flex-1`, `grow`, `shrink-0`, `hidden`, `invisible`, `block` |
| Typography | `text-*` sizes (with `/n` line heights), colours and alignment, `font-*` weights, `font-sans`, `font-mono`, `leading-*`, `uppercase` and the other casings, `whitespace-nowrap`, `truncate` |
| Borders | `border`, `border-*` widths and colours, `border-t` and the other sides, `border-dashed`, `rounded-*` (sides and corners), `ring`, `ring-*` |
| Effects | `bg-*`, `bg-linear-to-r`, `from-*`, `to-*`, `opacity-*`, `shadow-*`, `aspect-*`, `overflow-hidden`, `overflow-y-auto` |
| Position | `relative`, `absolute`, `fixed`, `inset-*`, `top-*` and the other sides (negative too), `z-*`, `translate-x-*`, `translate-y-*`, `scale-*` |
| Motion | `transition`, `transition-colors` and the other groups, `transition-[...]`, `duration-*`, `delay-*`, `ease-*`, `animate-spin`, `animate-pulse` |
| Variants | `hover`, `active`, `focus`, `focus-visible`, `disabled`, `placeholder`, `aria-pressed`, `data-[key=value]`, `data-open`, `data-closed`, `sm` to `xl`, `motion-reduce`, `pointer-coarse` |

Values can be arbitrary (`p-[10px]`, `bg-[#fb5c49]`) or a custom property of the theme
(`rounded-(--radius-lg)`). Classes that only make sense in a browser (`cursor-*`, `select-*`,
`outline-none`, `tracking-*` among them) compile to nothing on purpose, so web class strings work
unchanged; the enter and exit classes of tailwindcss-animate (`animate-in fade-in-0`) do too, since
`Presence` draws them.

## Where Roblox differs

| Difference | What the package does |
|---|---|
| No specificity, only rule order | Every state's rule carries every property resolved for that state, in Tailwind's order |
| No CSS inheritance | Text style resolved as it renders; an ancestor's states reach its text through descendant rules |
| No cubic-bezier easing in the style engine | The nearest Roblox easing per curve, within 4% for Tailwind's ease-out curves and 18% for its default ease-in-out |
| A stroke takes no room; CSS borders do | Border widths are added to the padding |
| A UIStroke draws all four sides | One-sided borders are lines over the element's edge; dashed ones a tiled dash |
| No box shadows | Each layer is a 9-sliced blurred box, spread and offset as CSS does |
| UIScale shrinks toward a corner, list layouts ignore Position | A scaled or translated element sits in a frame of its unscaled size |
| No margins in list layouts | A frame takes the element's place and offsets it |
| A UICorner rounds all four corners | Per-corner radii round all four by the largest |
| CSS opacity fades a subtree | Folded into the element's fill, stroke and text alpha; `Fade` and `Presence` fade a whole subtree only while it moves |
| Roblox draws Inter narrower than Chrome | TextSize calibrated per size and weight |
| Under a UIScale, text draws at TextSize times the scale rounded down to a whole size | A label under a scale takes the TextSize that rounds back to its own size, so a pressed `active:scale-98` button's text shrinks by 2%, not 7% |
| No letter spacing, no backdrop blur | `tracking-*` and `backdrop-blur-*` compile to nothing |
| `ring-offset-*` | Not drawn: an element has one stroke |
| Child selectors (`[&>svg]:`, `[&_p]:`) | Compiled, not drawn yet |
| `dark:` | Compiled, never active: there is no dark mode to turn on yet |
| `bg-linear-*` blends in OKLab | Roblox blends gradient stops in sRGB |

The shadow and dashed-border images are Roblox assets uploaded by the maintainer
(`assets/`, drawn by `tools/`). If an experience cannot load them, upload `assets/` to your own
account and change the ids in `src/Assets.luau`.

## API

| Name | What it is |
|---|---|
| `h(kind, props?, ...children)` | An element. `props`: `className`, `layoutOrder`, `disabled`, `data`, `pressed`, `onClick`, `name`, `image` (an `img`), `value`, `placeholder`, `onChange`, `onSubmit` (an `input`) |
| `Styles` | The StyleLink for the ScreenGui it renders in |
| `configure(options)` | `theme`, `textColor`, `borderColor`, `ringColor`; once, before the first render |
| `cva(base, config)`, `cn(...)` | Variant helpers |
| `Presence`, `presets` | Enter and exit animations |
| `Fade`, `AutoHeight`, `Portal`, `Layout` | Whole-subtree fades, height tweens, portals, rows and stacks |
| `Text`, `Glyph` | Text and images in the surrounding text style |
| `useText()`, `useSlot()` | The text style around a component, and how its root sits |
| `useViewport()`, `useReducedMotion()` | The screen's size; the Reduced Motion setting |
| `useTween(goal, timing, initial?)` | A binding that tweens to `goal` |
| `bezier(x1, y1, x2, y2)`, `linear(points)`, `spring` | Easings |
| `frame` | The signal animations step on: PreRender in a game, Heartbeat in edit mode |
| `color(css)` | A CSS colour as the theme's `{ r, g, b, a }`; raises on text that is not one |

Types: `Kind`, `Props`, `Choice`, `Variants`, `Preset`, `From`, `Timing`, `Easing`, `Options`,
`TextStyle`, `TextAround`, `Slot`.

## Development

You need [Rokit](https://github.com/rojo-rbx/rokit).

```sh
rokit install
lune run install   # React for type checking, the sourcemap, package types
lune run check     # what CI runs
```

`lune run check` checks the license copy, that `src/Theme/Default.luau` matches
`theme/tailwind.css` (`lune run theme` writes it), that `Declarations.merge` copies every field
(`lune run declarations`), StyLua formatting, the style rules in [STYLE.md](STYLE.md) (the Linux
kernel's coding style, read for Luau), Selene, strict types, the Lune tests, and the build.

The compiler (`src/Compiler`) is plain Luau and tested in Lune. The rest needs Roblox: it is
proven in the game it came from, by Studio specs that render it, a page of 110 elements compared
with what Chrome computes for the same classes, and a snapshot of every instance a gallery of
components draws.

**Releasing:** bump `version` in `lib/quarry-tailwind/wally.toml`, add the changes to
`CHANGELOG.md`, and publish a GitHub release tagged `vX.Y.Z`. The Release workflow checks, attaches
the model and publishes to Wally.

## License

[MIT](LICENSE). The default theme is Tailwind CSS 4.1.18's, © Tailwind Labs, Inc., also MIT.
