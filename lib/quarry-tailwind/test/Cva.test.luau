--!strict
local Testing = require("../../../.lune/testing")

local Cva = require("../src/Cva")

local suite: Testing.Suite = function(test, expect)
	local button = Cva.cva("rounded-full font-medium", {
		variants = {
			variant = {
				default = "bg-primary text-white",
				outline = "border border-input",
			},
			size = { default = "h-9 px-3.5", sm = "h-8 px-2.5" },
		},
		defaultVariants = { variant = "default", size = "default" },
	})

	test("defaults fill in variants that were not chosen", function()
		expect.equal(
			button(),
			"rounded-full font-medium h-9 px-3.5 "
				.. "bg-primary text-white"
		)
	end)

	test("a chosen variant replaces its default", function()
		local choice: Cva.Choice = { variant = "outline", size = "sm" }
		expect.equal(
			button(choice),
			"rounded-full font-medium h-8 px-2.5 "
				.. "border border-input"
		)
	end)

	test("cn joins strings and skips nil and false", function()
		expect.equal(Cva.cn("a", nil, false, "", "b"), "a b")
	end)
end

return suite
