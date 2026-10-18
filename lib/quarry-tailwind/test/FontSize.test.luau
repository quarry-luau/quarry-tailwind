--!strict
local Testing = require("../../../.lune/testing")

local FontSize = require("../src/Compiler/FontSize")
local TextMetrics = require("../src/Compiler/TextMetrics")

local suite: Testing.Suite = function(test, expect)
	test(
		"a calibrated size and weight gives its TextSize, unscaled",
		function()
			expect.deepEqual(FontSize.resolve("sans", 500, 12), {
				textSize = TextMetrics.sans[500][12][1],
				scale = 1,
			})
		end
	)

	test(
		"a size between calibrated ones rounds the interpolation",
		function()
			local low, high =
				TextMetrics.sans[400][12],
				TextMetrics.sans[400][14]
			local expected = 13
				* (
					(
						low[1] * low[2] / 12
						+ high[1] * high[2] / 14
					) / 2
				)
			expect.deepEqual(
				FontSize.resolve("sans", 400, 13),
				{ textSize = math.round(expected), scale = 1 }
			)
		end
	)

	test("a weight that was not calibrated uses the nearest one", function()
		expect.deepEqual(
			FontSize.resolve("sans", 800, 14),
			FontSize.resolve("sans", 700, 14)
		)
	end)

	test("sizes past Roblox's cap of 100 scale up from 100", function()
		local size = FontSize.resolve("sans", 400, 128)
		expect.equal(size.textSize, 100)
		expect.equal(size.scale > 1, true)
		expect.equal(FontSize.resolve("sans", 400, 200).textSize, 100)
	end)
end

return suite
