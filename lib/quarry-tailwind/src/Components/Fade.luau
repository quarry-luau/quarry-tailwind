--!strict
-- Content that fades as a whole, as CSS opacity fades a subtree. Roblox
-- fades a subtree only in a CanvasGroup, which draws through a texture: its
-- quality drops with the graphics level, it blurs text on dense screens and
-- it is blank past the texture memory cap. So the content sits in a plain
-- frame and moves into a CanvasGroup only while `fading`. It is moved,
-- never remounted: a remounted subtree measures its text again and flickers
-- for a frame.

local React = require("../../React")

export type Props = {
	fading: boolean,
	-- Applied only while fading.
	transparency: React.Binding<number>,
	size: UDim2,
	automaticSize: Enum.AutomaticSize,
	anchorPoint: Vector2?,
	position: (UDim2 | React.Binding<UDim2>)?,
	scale: React.Binding<number>?,
	-- Whether its content takes input while it fades.
	interactable: boolean?,
	children: React.ReactNode?,
}

local e = React.createElement

local function Fade(props: Props): React.ReactNode
	local noFrame: Frame? = nil
	local noGroup: CanvasGroup? = nil
	local frame = React.useRef(noFrame)
	local group = React.useRef(noGroup)
	local holder = React.useRef(noFrame)
	React.useLayoutEffect(function()
		local content = holder.current
		local into = if props.fading
			then group.current
			else frame.current
		if content and into then
			content.Parent = into
		end
	end, { props.fading })
	return e("Frame", {
		BackgroundTransparency = 1,
		Size = props.size,
		AutomaticSize = props.automaticSize,
		AnchorPoint = props.anchorPoint,
		Position = props.position,
		ref = frame,
	}, {
		Scale = if props.scale
			then e("UIScale", { Scale = props.scale })
			else nil,
		Group = e("CanvasGroup", {
			BackgroundTransparency = 1,
			Size = props.size,
			AutomaticSize = props.automaticSize,
			Visible = props.fading,
			Interactable = props.interactable ~= false,
			GroupTransparency = props.transparency,
			ref = group,
		}),
		-- A Fragment takes keyed tables, which a frame refuses.
		Content = e("Frame", {
			BackgroundTransparency = 1,
			Size = props.size,
			AutomaticSize = props.automaticSize,
			ref = holder,
		}, { Content = e(React.Fragment, nil, props.children) }),
	})
end

return Fade
