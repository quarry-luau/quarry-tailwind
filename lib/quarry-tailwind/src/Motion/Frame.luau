--!strict
-- The signal animations step on, once a frame: PreRender in a running game,
-- just before the frame is drawn, and Heartbeat in edit mode (a story in
-- UI Labs), where Roblox fires PreRender only while the 3D view draws.

local RunService = game:GetService("RunService")

local Frame: RBXScriptSignal = if RunService:IsRunning()
	then RunService.PreRender
	else RunService.Heartbeat

return Frame
