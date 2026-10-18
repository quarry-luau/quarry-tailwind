--!strict
local Testing = require("../../../.lune/testing")

local Declarations = require("../src/Compiler/Declarations")

local suite: Testing.Suite = function(test, expect)
	test("a later false or 0 replaces an earlier value", function()
		local merged = Declarations.merge(
			{ textWrap = true, hidden = true, paddingTop = 4 },
			{ textWrap = false, hidden = false, paddingTop = 0 }
		)
		expect.equal(merged.textWrap, false)
		expect.equal(merged.hidden, false)
		expect.equal(merged.paddingTop, 0)
	end)

	test(
		"an unset field keeps the base's, and neither input changes",
		function()
			local base: Declarations.Declarations =
				{ paddingTop = 4, z = 1 }
			local over: Declarations.Declarations = { z = 2 }
			local merged = Declarations.merge(base, over)
			expect.equal(merged.paddingTop, 4)
			expect.equal(merged.z, 2)
			expect.equal(base.z, 1)
			expect.equal(over.paddingTop, nil)
		end
	)
end

return suite
