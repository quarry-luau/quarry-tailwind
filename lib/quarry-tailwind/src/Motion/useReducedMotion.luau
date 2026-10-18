--!strict
-- Whether the player turned on Reduced Motion in Roblox's settings;
-- animations then jump to their end, as under prefers-reduced-motion.

local GuiService = game:GetService("GuiService")

local React = require("../../React")

local function useReducedMotion(): boolean
	local reduced, setReduced =
		React.useState(GuiService.ReducedMotionEnabled)
	React.useEffect(function()
		local changed = GuiService:GetPropertyChangedSignal(
			"ReducedMotionEnabled"
		)
		local connection = changed:Connect(function()
			setReduced(GuiService.ReducedMotionEnabled)
		end)
		return function()
			connection:Disconnect()
		end
	end, {})
	return reduced
end

return useReducedMotion
