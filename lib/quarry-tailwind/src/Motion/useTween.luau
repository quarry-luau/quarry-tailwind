--!strict
-- A binding that tweens to `goal` along `timing` whenever the goal changes,
-- from wherever it is, so a reversed tween turns around smoothly. It starts
-- at `initial`, so a component can animate in on mount, or at the goal.
-- Under Reduced Motion it jumps.

local Frame = require("./Frame")
local React = require("../../React")
local Timing = require("./Timing")
local useReducedMotion = require("./useReducedMotion")

local function useTween(
	goal: number,
	timing: Timing.Timing,
	initial: number?
): React.Binding<number>
	local reduced = useReducedMotion()
	local binding, setBinding =
		React.useBinding(if initial ~= nil then initial else goal)
	local changes: { number | boolean } = { goal, reduced }
	React.useEffect(function(): (() -> ())?
		local from = binding:getValue()
		if reduced or from == goal or timing.duration <= 0 then
			setBinding(goal)
			return nil
		end
		local started = os.clock() + (timing.delay or 0)
		local connection = Frame:Connect(function()
			local progress = (os.clock() - started)
				/ timing.duration
			if progress >= 0 then
				local eased = timing.ease(math.min(progress, 1))
				setBinding(from + (goal - from) * eased)
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, changes)
	return binding
end

return useTween
