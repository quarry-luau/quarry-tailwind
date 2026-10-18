--!strict
local Testing = require("../../../.lune/testing")

local Parse = require("../src/Compiler/Parse")

local suite: Testing.Suite = function(test, expect)
	test("variants, utility and opacity modifier separate", function()
		local token = Parse.parse("hover:bg-primary/80")
		expect.deepEqual(token.variants, { "hover" })
		expect.equal(token.utility, "bg-primary")
		expect.equal(token.modifier, "80")
	end)

	test(
		"a length's n/m is a fraction, a colour's is an opacity",
		function()
			expect.equal(Parse.parse("top-1/3").utility, "top-1/3")
			expect.equal(
				Parse.parse("-translate-x-1/2").utility,
				"-translate-x-1/2"
			)
			expect.equal(Parse.parse("md:w-1/2").modifier, nil)
			local colour = Parse.parse("bg-red-500/50")
			expect.equal(colour.utility, "bg-red-500")
			expect.equal(colour.modifier, "50")
		end
	)

	test("brackets and parentheses are not split", function()
		local token = Parse.parse("data-[state=checked]:translate-x-4")
		expect.deepEqual(token.variants, { "data-[state=checked]" })
		expect.equal(
			Parse.parse("rounded-(--card-radius)").utility,
			"rounded-(--card-radius)"
		)
		expect.equal(
			Parse.parse("w-[calc(100%-32px)]").utility,
			"w-[calc(100%-32px)]"
		)
		expect.equal(
			Parse.parse("[&>svg]:text-gray-400").variants[1],
			"[&>svg]"
		)
	end)

	test("important is noted at either end", function()
		expect.equal(Parse.parse("p-0!").important, true)
		expect.equal(Parse.parse("p-0!").utility, "p-0")
		expect.equal(Parse.parse("!flex").important, true)
		expect.equal(Parse.parse("lg:flex!").variants[1], "lg")
	end)
end

return suite
