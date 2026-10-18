--!strict
-- Tailwind's keyframe animations, driven by one loop that runs only while
-- some element uses one. Pulse is a style token (`$TwPulse500`) the loop
-- updates on the style sheet, so the element's other styles still apply.
-- Spin is a binding (`spin`) set as the element's Rotation: under a
-- Rotation token spinners stood still on screen while GetStyled reported
-- them turning. The keyframes are Tailwind's: spin turns 360 degrees a
-- second, linearly; pulse fades opacity 1 -> 0.5 -> 1 over 2 seconds,
-- cubic-bezier(0.4, 0, 0.6, 1) each half.

local Bezier = require("./Bezier")
local Frame = require("./Frame")
local React = require("../../React")

local SPIN_SECONDS = 1
local PULSE_SECONDS = 2
local PULSE_LOW = 0.5
local TOKEN_PRECISION = 1000
local pulseEase = Bezier.new(0.4, 0, 0.6, 1)

-- The angle a spinning element turns to, in degrees.
local spin, setSpin = React.createBinding(0)
local users = 0
local connection: RBXScriptConnection? = nil
local pulses: { [string]: number } = {}

local function pulseOpacity(time: number): number
	local phase = (time % PULSE_SECONDS) / PULSE_SECONDS
	if phase < 0.5 then
		return 1 - (1 - PULSE_LOW) * pulseEase(phase * 2)
	end
	return PULSE_LOW + (1 - PULSE_LOW) * pulseEase((phase - 0.5) * 2)
end

local function step(sheet: StyleSheet)
	local time = os.clock()
	setSpin((time % SPIN_SECONDS) / SPIN_SECONDS * 360)
	local opacity = pulseOpacity(time)
	for token, alpha in pulses do
		sheet:SetAttribute(token, 1 - alpha * opacity)
	end
end

-- The token for the background transparency of a pulsing fill of opacity
-- `alpha`.
local function pulseToken(sheet: StyleSheet, alpha: number): string
	local token = `TwPulse{math.round(alpha * TOKEN_PRECISION)}`
	if pulses[token] == nil then
		pulses[token] = alpha
		sheet:SetAttribute(token, 1 - alpha)
	end
	return `${token}`
end

local function release()
	users -= 1
	if users == 0 and connection then
		connection:Disconnect()
		connection = nil
	end
end

-- Notes that an animated element appeared; returns what to call when it
-- goes away.
local function use(sheet: StyleSheet): () -> ()
	users += 1
	if connection == nil then
		connection = Frame:Connect(function()
			step(sheet)
		end)
	end
	local released = false
	return function()
		if not released then
			released = true
			release()
		end
	end
end

return { spin = spin, pulseToken = pulseToken, use = use }
