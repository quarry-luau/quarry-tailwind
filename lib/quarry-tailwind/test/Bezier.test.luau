--!strict
local Testing = require("../../../.lune/testing")

local Bezier = require("../src/Motion/Bezier")

local function near(actual: number, expected: number): string
	return if math.abs(actual - expected) < 1e-3
		then "near"
		else `{actual} is not {expected}`
end

local suite: Testing.Suite = function(test, expect)
	test("ends stay at 0 and 1, and inputs outside are clamped", function()
		local ease = Bezier.new(0.22, 1, 0.36, 1)
		expect.deepEqual(
			{ ease(-1), ease(0), ease(1), ease(2) },
			{ 0, 0, 1, 1 }
		)
	end)

	test("the straight curve is linear", function()
		local ease = Bezier.new(0.25, 0.25, 0.75, 0.75)
		for _, x in { 0.1, 0.33, 0.5, 0.9 } do
			expect.equal(near(ease(x), x), "near")
		end
	end)

	test("CSS ease-in-out is symmetric around the middle", function()
		local ease = Bezier.new(0.42, 0, 0.58, 1)
		expect.equal(near(ease(0.5), 0.5), "near")
		expect.equal(near(ease(0.25) + ease(0.75), 1), "near")
	end)

	test(
		"ease-out (0.22, 1, 0.36, 1) matches the bisected curve",
		function()
			local ease = Bezier.new(0.22, 1, 0.36, 1)
			-- The curve bisected to 200 steps in double precision.
			expect.equal(near(ease(0.1), 0.401097), "near")
			expect.equal(near(ease(0.25), 0.764865), "near")
			expect.equal(near(ease(0.5), 0.961383), "near")
			expect.equal(near(ease(0.75), 0.996894), "near")
		end
	)
end

return suite
