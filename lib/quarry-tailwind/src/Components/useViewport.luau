--!strict
-- The size of the player's screen, re-rendering when it changes.

local Workspace = game:GetService("Workspace")

local React = require("../../React")

local function useViewport(): Vector2
	local camera = Workspace.CurrentCamera
	local size, setSize = React.useState(
		if camera then camera.ViewportSize else Vector2.zero
	)
	React.useEffect(function(): (() -> ())?
		if camera == nil then
			return nil
		end
		local changed = camera:GetPropertyChangedSignal("ViewportSize")
		local connection = changed:Connect(function()
			setSize(camera.ViewportSize)
		end)
		return function()
			connection:Disconnect()
		end
	end, {})
	return size
end

return useViewport
