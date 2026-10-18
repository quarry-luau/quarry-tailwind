--!strict
local Testing = require("../../../.lune/testing")

local Linear = require("../src/Motion/Linear")

local suite: Testing.Suite = function(test, expect)
	test(
		"interpolates between evenly spaced points and holds the ends",
		function()
			local ease = Linear.new({ 0, 0.5, 1 })
			expect.equal(ease(0), 0)
			expect.equal(ease(0.25), 0.25)
			expect.equal(ease(0.75), 0.75)
			expect.equal(ease(1), 1)
			expect.equal(ease(2), 1)
		end
	)

	test("follows an uneven curve point by point", function()
		local ease = Linear.new({ 0, 0.8, 0.9, 1 })
		expect.equal(ease(1 / 3), 0.8)
		expect.truthy(math.abs(ease(0.5) - 0.85) < 1e-9)
	end)
end

return suite
