--!strict
-- Development warnings, as React gives them: in Studio each distinct
-- message is printed once, when the mistake first renders; a live game
-- prints nothing.

local RunService = game:GetService("RunService")

local shown: { [string]: boolean } = {}

local function warnOnce(message: string)
	if RunService:IsStudio() and not shown[message] then
		shown[message] = true
		warn(`[Tailwind] {message}`)
	end
end

return warnOnce
