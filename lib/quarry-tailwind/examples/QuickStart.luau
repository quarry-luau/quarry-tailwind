--!strict
-- The README's quick start, type checked with the package (lune run analyze).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Tailwind = require("../src")

local CARD = "flex flex-col gap-3 rounded-xl bg-white p-6 shadow-lg"

local e = React.createElement
local h = Tailwind.h

local function Counter()
	local count, setCount = React.useState(0)
	return h(
		"div",
		{ className = CARD },
		h("p", { className = "text-sm text-gray-500" }, "Clicked"),
		h(
			"p",
			{ className = "text-3xl font-semibold" },
			tostring(count)
		),
		h("button", {
			className = "rounded-md bg-blue-600 px-4 py-2 text-sm "
				.. "font-medium text-white transition-colors "
				.. "hover:bg-blue-500 active:scale-95",
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
