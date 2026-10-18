--!strict
local Testing = require("../../../.lune/testing")

local Compiler = require("../src/Compiler")
local Text = require("../src/Compiler/Text")
local Theme = require("../src/Theme")

local compiler = Compiler.new(Theme.default)
local BLACK = { r = 0, g = 0, b = 0, a = 1 }

local function style(parent: Text.Style, classes: string): Text.Style
	return Text.resolve(parent, Compiler.base(compiler.compile(classes)))
end

local suite: Testing.Suite = function(test, expect)
	local body = Text.body(BLACK)

	test("the body is 16 px with a line height of 1.5", function()
		expect.equal(Text.lineHeight(body), 24)
	end)

	test(
		"a text size's line height scales with a child's own size",
		function()
			local small = style(body, "text-sm")
			local child = style(small, "text-xs")
			expect.equal(Text.lineHeight(small), 20)
			expect.equal(Text.lineHeight(child), 16)
		end
	)

	test("a leading class beats the size's, in either order", function()
		expect.equal(
			Text.lineHeight(style(body, "text-sm leading-6")),
			24
		)
		expect.equal(
			Text.lineHeight(style(body, "leading-6 text-sm")),
			24
		)
		expect.equal(
			Text.lineHeight(style(body, "leading-6 leading-none")),
			16
		)
	end)

	test(
		"a px line height is inherited as px, a size's own replaces it",
		function()
			local fixed = style(body, "leading-4")
			expect.equal(
				Text.lineHeight(style(fixed, "text-[30px]")),
				16
			)
			expect.equal(
				Text.lineHeight(style(fixed, "text-2xl")),
				32
			)
		end
	)

	test(
		"colour, weight and casing inherit; unset fields keep them",
		function()
			local parent = style(
				body,
				"text-red-500 font-semibold uppercase"
			)
			local child = style(parent, "text-sm")
			expect.deepEqual(
				child.color,
				Theme.default.color["red-500"]
			)
			expect.equal(child.weight, 600)
			expect.equal(child.casing, "uppercase")
		end
	)

	test(
		"styles says whether an element changes what text inherits",
		function()
			local function styles(classes: string): boolean
				return Text.styles(
					Compiler.base(compiler.compile(classes))
				)
			end
			expect.equal(styles("p-2 bg-red-500"), false)
			expect.equal(styles("text-sm"), true)
			expect.equal(styles("opacity-50"), true)
		end
	)
end

return suite
