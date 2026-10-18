--!strict
local Testing = require("../../../.lune/testing")

local Compiler = require("../src/Compiler")
local Declarations = require("../src/Compiler/Declarations")
local Theme = require("../src/Theme")

local compiler = Compiler.new(Theme.default)

local function base(classes: string): Declarations.Declarations
	return Compiler.base(compiler.compile(classes))
end

local suite: Testing.Suite = function(test, expect)
	test("calc() widths keep a fraction and a pixel offset", function()
		expect.deepEqual(
			base("w-[calc(100%-32px)]").width,
			{ kind = "fraction", value = 1, offset = -32 }
		)
	end)

	test("a negative arbitrary translate is a negative fraction", function()
		expect.deepEqual(
			base("translate-x-[-50%]").translateX,
			{ kind = "fraction", value = -0.5 }
		)
		expect.deepEqual(
			base("-translate-x-1/2").translateX,
			{ kind = "fraction", value = -0.5 }
		)
	end)

	test("a leading - negates only roots that take one", function()
		expect.equal(base("-mt-2").marginTop, -8)
		expect.deepEqual(
			base("-top-2").insetTop,
			{ kind = "px", value = -8 }
		)
		local compiled = compiler.compile("-bg-red-500 -p-2")
		expect.deepEqual(
			compiled.unsupported,
			{ "-bg-red-500", "-p-2" }
		)
	end)

	test(
		"a transition list names each kind of property it covers",
		function()
			local tabs = base(
				"transition-[background-color,color,box-shadow]"
			)
			expect.deepEqual(tabs.transition, {
				colors = true,
				opacity = false,
				transform = false,
				shadow = true,
				size = false,
			})
		end
	)

	test(
		"a transition takes the theme's timing where no class sets it",
		function()
			local plain = base("transition-colors")
			expect.equal(
				plain.duration,
				Theme.default.defaultTransition.duration
			)
			expect.deepEqual(
				plain.ease,
				Theme.default.defaultTransition.ease
			)
			expect.equal(
				base("duration-300 transition").duration,
				0.3
			)
			expect.equal(
				base("transition duration-300").duration,
				0.3
			)
			expect.equal(base("duration-300").duration, 0.3)
		end
	)

	test(
		"a state's shadow and margin compile under its condition",
		function()
			local compiled = compiler.compile(
				"data-[state=active]:shadow-sm "
					.. "data-[state=active]:mt-5"
			)
			local active = Compiler.resolve(
				compiled,
				{ ["data-state=active"] = true }
			)
			expect.equal(active.shadow, "sm")
			expect.equal(active.marginTop, 20)
			expect.equal(Compiler.base(compiled).shadow, nil)
		end
	)

	test(
		"a later class overrides an earlier one in the same state",
		function()
			expect.equal(base("p-2 p-4").paddingTop, 16)
			expect.deepEqual(
				base("bg-red-500 bg-white").fillColor,
				{
					r = 255,
					g = 255,
					b = 255,
					a = 1,
				}
			)
		end
	)

	test(
		"rules sort as Tailwind sorts its CSS, breakpoints last",
		function()
			local compiled = compiler.compile(
				"md:p-4 disabled:p-3 hover:p-2 p-1"
			)
			local order = {}
			for _, rule in compiled.rules do
				table.insert(
					order,
					table.concat(rule.conditions, "&")
				)
			end
			expect.deepEqual(
				order,
				{ "", "hover", "disabled", "min-width:768" }
			)
		end
	)

	test(
		"unknown classes and variants are reported, inert ones apart",
		function()
			local compiled = compiler.compile(
				"p-2 animate-bounce foo:p-2 file:p-2 bg-inherit"
			)
			expect.deepEqual(
				compiled.unsupported,
				{ "animate-bounce", "foo:p-2", "bg-inherit" }
			)
			expect.deepEqual(compiled.inert, { "file:p-2" })
		end
	)

	test(
		"deliberate no-ops compile to nothing and are not reported",
		function()
			local compiled = compiler.compile(
				"animate-in fade-in-0 zoom-in-95 tracking-tight"
			)
			expect.deepEqual(compiled.rules, {})
			expect.deepEqual(compiled.unsupported, {})
		end
	)

	test("per-corner radii round every corner by the largest", function()
		local style = base("rounded-t-lg rounded-bl-sm")
		expect.equal(style.cornerTopLeft, 8)
		expect.equal(style.cornerBottomLeft, 4)
		expect.equal(Declarations.radius(style), 8)
		expect.equal(
			Declarations.radius(base("rounded-full")),
			math.huge
		)
		expect.equal(Declarations.radius(base("p-2")), nil)
	end)

	test("truncate keeps text on one line and truncates it", function()
		local style = base("truncate")
		expect.equal(style.textWrap, false)
		expect.equal(style.textTruncate, true)
	end)

	test("text sizes bring their line height, which /n replaces", function()
		local sized = base("text-sm")
		expect.equal(sized.textSize, 14)
		expect.equal(sized.textSizeRatio, 20 / 14)
		expect.deepEqual(
			base("text-sm/6").textLeading,
			{ kind = "px", value = 24 }
		)
	end)

	test("a display utility shows what hidden hid", function()
		expect.equal(base("hidden").hidden, true)
		expect.equal(base("hidden md:flex").hidden, true)
		local compiled = compiler.compile("hidden md:flex")
		local wide =
			Compiler.resolve(compiled, { ["min-width:768"] = true })
		expect.equal(wide.hidden, false)
		expect.equal(wide.layout, "flex")
	end)

	test(
		"compiling the same string twice gives the cached result",
		function()
			expect.equal(
				compiler.compile("p-2"),
				compiler.compile("p-2")
			)
		end
	)
end

return suite
