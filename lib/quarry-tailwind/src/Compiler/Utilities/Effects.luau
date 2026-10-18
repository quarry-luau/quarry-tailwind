--!strict
-- Opacity, shadows, aspect ratios and overflow: `opacity-50`, `shadow-sm`,
-- `aspect-square`, `aspect-[4/3]`, `overflow-hidden`, `overflow-y-auto`.

local Declarations = require("../Declarations")
local Registry = require("../Registry")
local Theme = require("../../Theme")

type Declarations = Declarations.Declarations

local function opacity(
	candidate: Registry.Candidate,
	_: Theme.Theme
): Declarations?
	local value = if candidate.value then tonumber(candidate.value) else nil
	local found: Declarations =
		{ opacity = if value then value / 100 else nil }
	return if value then found else nil
end

-- A theme shadow or `none`; the bare `shadow` is `shadow-sm`.
local function shadow(
	candidate: Registry.Candidate,
	theme: Theme.Theme
): Declarations?
	local name = candidate.value or "sm"
	local found: Declarations = { shadow = name }
	if name ~= "none" and theme.shadow[name] == nil then
		return nil
	end
	return found
end

local function aspect(
	candidate: Registry.Candidate,
	_: Theme.Theme
): Declarations?
	local width, height =
		string.match(candidate.value or "", "^%[(%d+)/(%d+)%]$")
	if width == nil or height == nil then
		return nil
	end
	local found: Declarations =
		{ aspect = (tonumber(width) or 1) / (tonumber(height) or 1) }
	return found
end

local CLIPS: Declarations = { clips = true }
local SCROLLS: Declarations = { clips = true, scrolls = true }

local group: Registry.Group = {
	static = {
		["aspect-square"] = { aspect = 1 },
		["aspect-video"] = { aspect = 16 / 9 },
		["overflow-hidden"] = CLIPS,
		["overflow-clip"] = CLIPS,
		["overflow-auto"] = SCROLLS,
		["overflow-y-auto"] = SCROLLS,
	},
	functional = { opacity = opacity, shadow = shadow, aspect = aspect },
	noop = {
		["^aspect%-auto$"] = "a box takes its content's aspect already",
		["^backdrop%-blur"] = "Roblox cannot blur behind a frame",
		["^will%-change%-"] = "a rendering hint",
		["^scroll%-smooth$"] = "Roblox scrolls smoothly already",
	},
}

return group
