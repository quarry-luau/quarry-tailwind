--!strict
-- The README's guides, type checked with the package (lune run analyze).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Tailwind = require("../src")

local e = React.createElement
local h = Tailwind.h

Tailwind.configure({
	theme = {
		color = {
			primary = Tailwind.color("oklch(0.5076 0.2767 271.74)"),
			border = Tailwind.color("#e4e4e7"),
			foreground = Tailwind.color("#0a0a0a"),
		},
		radius = { lg = 10 },
	},
	textColor = "foreground",
	borderColor = "border",
	ringColor = "foreground",
})

local function Toggle(props: { on: boolean, locked: boolean, toggle: () -> () })
	return h("button", {
		className = "rounded-md border px-3 py-1.5 hover:bg-gray-100 "
			.. "disabled:opacity-50 data-[state=on]:bg-gray-900 "
			.. "data-[state=on]:text-white",
		data = { state = if props.on then "on" else "off" },
		disabled = props.locked,
		onClick = props.toggle,
	}, "Bold")
end

local button = Tailwind.cva(
	"inline-flex items-center rounded-md text-sm font-medium "
		.. "transition-colors",
	{
		variants = {
			variant = {
				default = "bg-gray-900 text-white "
					.. "hover:bg-gray-800",
				outline = "border border-gray-200 bg-white "
					.. "hover:bg-gray-100",
			},
			size = { default = "h-9 px-4", sm = "h-8 px-3" },
		},
		defaultVariants = { variant = "default", size = "default" },
	}
)

local function Button(props: {
	variant: string?,
	size: string?,
	children: React.ReactNode,
})
	local choice: Tailwind.Choice =
		{ variant = props.variant, size = props.size }
	return h("button", { className = button(choice) }, props.children)
end

local function Saved(props: { open: boolean })
	return e(
		Tailwind.Presence,
		{
			show = props.open,
			from = Tailwind.presets.pop.from,
			timing = Tailwind.presets.pop.timing,
		},
		h(
			"div",
			{ className = "rounded-lg bg-white p-4 shadow-lg" },
			"Saved"
		)
	)
end

return { Toggle = Toggle, Button = Button, Saved = Saved }
