--!strict
local Testing = require("../../../.lune/testing")

local Compiler = require("../src/Compiler")
local Theme = require("../src/Theme")

local BRAND = { r = 61, g = 56, b = 255, a = 1 }

local suite: Testing.Suite = function(test, expect)
	test("the default theme is Tailwind 4's", function()
		expect.deepEqual(
			Theme.default.color["red-500"],
			{ r = 251, g = 44, b = 54, a = 1 }
		)
		expect.equal(Theme.default.spacing, 4)
		expect.deepEqual(
			Theme.default.text.sm,
			{ size = 14, lineHeight = 20 }
		)
		expect.equal(Theme.default.radius.lg, 8)
	end)

	test(
		"an extension adds and replaces tokens and keeps the rest",
		function()
			local theme = Theme.extend(Theme.default, {
				color = { brand = BRAND, ["red-500"] = BRAND },
				spacing = 2,
			})
			expect.deepEqual(theme.color.brand, BRAND)
			expect.deepEqual(theme.color["red-500"], BRAND)
			expect.deepEqual(
				theme.color["blue-500"],
				Theme.default.color["blue-500"]
			)
			expect.equal(theme.spacing, 2)
			expect.equal(theme.radius, Theme.default.radius)
			expect.equal(Theme.default.color.brand, nil)
		end
	)

	test(
		"classes compile against the theme their compiler was given",
		function()
			local theme = Theme.extend(
				Theme.default,
				{ color = { brand = BRAND } }
			)
			local branded = Compiler.new(theme)
				.compile("bg-brand p-1")
			local plain = Compiler.new(Theme.default)
				.compile("bg-brand p-1")
			expect.deepEqual(
				Compiler.base(branded).fillColor,
				BRAND
			)
			expect.equal(Compiler.base(branded).paddingTop, 4)
			expect.deepEqual(plain.unsupported, { "bg-brand" })
		end
	)
end

return suite
