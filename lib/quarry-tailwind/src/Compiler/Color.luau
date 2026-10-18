--!strict
-- CSS colours as sRGB: `#rgb`, `#rrggbb`, `#rrggbbaa`, `rgb()` in either
-- syntax, `oklch()` (the space Tailwind 4 writes its palette in) and `oklab()`
-- (how browsers report them). OKLCH goes through OKLab to linear sRGB and is
-- clipped to the sRGB gamut, as browsers do for an sRGB screen.

export type Rgba = { r: number, g: number, b: number, a: number }

local Color = {}

local TRANSPARENT: Rgba = { r = 0, g = 0, b = 0, a = 0 }

local function encode(linear: number): number
	local clipped = math.clamp(linear, 0, 1)
	local gamma = if clipped <= 0.0031308
		then clipped * 12.92
		else 1.055 * clipped ^ (1 / 2.4) - 0.055
	return math.round(gamma * 255)
end

-- A channel: a number, or a percentage of `percentScale`; `none` is 0.
local function channel(text: string, percentScale: number): number?
	local percent = string.match(text, "^(-?[%d.]+)%%$")
	if percent then
		local value = tonumber(percent)
		return if value then value / 100 * percentScale else nil
	end
	if text == "none" then
		return 0
	end
	return tonumber(text)
end

local function oklab(
	lightness: number,
	a: number,
	b: number,
	alpha: number
): Rgba
	local l = (lightness + 0.3963377774 * a + 0.2158037573 * b) ^ 3
	local m = (lightness - 0.1055613458 * a - 0.0638541728 * b) ^ 3
	local s = (lightness - 0.0894841775 * a - 1.2914855480 * b) ^ 3
	return {
		r = encode(
			4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
		),
		g = encode(
			-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
		),
		b = encode(
			-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
		),
		a = alpha,
	}
end

local function hex(digits: string): Rgba?
	local full = if #digits == 3 or #digits == 4
		then string.gsub(digits, "%x", "%0%0")
		else digits
	if #full ~= 6 and #full ~= 8 then
		return nil
	end
	local function byte(from: number): number
		return tonumber(string.sub(full, from, from + 1), 16) or 0
	end
	return {
		r = byte(1),
		g = byte(3),
		b = byte(5),
		a = if #full == 8 then byte(7) / 255 else 1,
	}
end

-- The channels of a colour function's body, with its alpha (1 when absent):
-- `0.5 0.2 270 / 0.4` and `251, 44, 54` both read.
local function channels(body: string): ({ string }, number?)
	local list, slash = string.match(body, "^([^/]*)/?%s*(.-)$")
	local values = {}
	for _, part in string.split(string.gsub(list or body, ",", " "), " ") do
		if part ~= "" then
			table.insert(values, part)
		end
	end
	local alpha = if slash ~= "" then slash else values[4]
	return values, if alpha then channel(alpha, 1) else 1
end

local function fromFunction(space: string, body: string): Rgba?
	local values, alpha = channels(body)
	if #values < 3 or alpha == nil then
		return nil
	end
	local scale = if space == "oklch"
		then { 1, 0.4, 1 }
		elseif space == "oklab" then { 1, 0.4, 0.4 }
		else { 255, 255, 255 }
	local x = channel(values[1], scale[1])
	local y = channel(values[2], scale[2])
	local z = channel(values[3], scale[3])
	if x == nil or y == nil or z == nil then
		return nil
	end
	if space == "oklch" then
		local hue = math.rad(z)
		return oklab(x, y * math.cos(hue), y * math.sin(hue), alpha)
	elseif space == "oklab" then
		return oklab(x, y, z, alpha)
	end
	return {
		r = math.round(x),
		g = math.round(y),
		b = math.round(z),
		a = alpha,
	}
end

local FUNCTIONS = { oklch = true, oklab = true, rgb = true, rgba = true }

-- The colour a CSS colour value names, or nil when it is none of the forms
-- above.
function Color.parse(text: string): Rgba?
	local value = string.lower((string.gsub(text, "^%s*(.-)%s*$", "%1")))
	local digits = string.match(value, "^#(%x+)$")
	if digits then
		return hex(digits)
	end
	if value == "transparent" then
		return TRANSPARENT
	end
	local space, body = string.match(value, "^(%a+)%((.*)%)$")
	if space == nil or body == nil or not FUNCTIONS[space] then
		return nil
	end
	return fromFunction(space, body)
end

-- The colour with its alpha multiplied by `opacity` (`/80` is 0.8).
function Color.withOpacity(color: Rgba, opacity: number): Rgba
	return { r = color.r, g = color.g, b = color.b, a = color.a * opacity }
end

return Color
