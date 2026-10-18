--!strict
local Testing = require("../../../.lune/testing")

local Color = require("../src/Compiler/Color")

local function hex(text: string): string
	local color = Color.parse(text)
	if color == nil then
		return "unparsed"
	end
	return string.format(
		"#%02x%02x%02x %.2f",
		color.r,
		color.g,
		color.b,
		color.a
	)
end

local suite: Testing.Suite = function(test, expect)
	test(
		"oklch converts to the reference sRGB, in both lightness forms",
		function()
			expect.equal(
				hex("oklch(0.5076 0.2767 271.74)"),
				"#3d38ff 1.00"
			)
			expect.equal(
				hex("oklch(96.7% 0.003 264.542)"),
				"#f3f4f6 1.00"
			)
			expect.equal(
				hex("oklch(72.3% 0.219 149.579)"),
				"#00c950 1.00"
			)
			expect.equal(
				hex("oklch(0.6431 0.2458 16.2)"),
				"#ff1f57 1.00"
			)
		end
	)

	test("an achromatic oklch is grey, with a 'none' hue", function()
		expect.equal(
			hex("oklch(98.5% 0 none)"),
			hex("oklch(0.985 0 0)")
		)
	end)

	test("hex, rgb and alpha forms parse", function()
		expect.equal(hex("#fff"), "#ffffff 1.00")
		expect.equal(hex("#00000080"), "#000000 0.50")
		expect.equal(hex("rgb(0 0 0 / 0.1)"), "#000000 0.10")
		expect.equal(hex("rgb(251, 44, 54)"), "#fb2c36 1.00")
		expect.equal(hex("transparent"), "#000000 0.00")
	end)

	test("oklab, as browsers report it, matches the same oklch", function()
		local reported = "oklab(0.5076 0.00840176 -0.276572 / 0.15)"
		expect.equal(hex(reported), "#3d38ff 0.15")
	end)

	test("an opacity modifier multiplies the alpha", function()
		local color = Color.parse("oklch(0.5076 0.2767 271.74)")
		expect.equal(color and Color.withOpacity(color, 0.8).a, 0.8)
	end)

	test("text that is not a colour does not parse", function()
		expect.equal(Color.parse("var(--primary)"), nil)
		expect.equal(Color.parse("1rem"), nil)
	end)
end

return suite
