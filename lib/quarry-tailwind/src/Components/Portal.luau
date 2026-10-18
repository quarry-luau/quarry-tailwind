--!strict
-- Draws its children on a screen of their own above the interface, as
-- Radix's Portal moves them to the end of the document: at the top of a
-- ScreenGui, where `fixed` and `absolute` place them, with the styles
-- linked and the body's text style. Outside a game (a story in edit mode,
-- with no local player) they draw where they are.

local Players = game:GetService("Players")

local Context = require("../Element/Context")
local React = require("../../React")
local ReactRoblox = require("../../ReactRoblox")
local Sheet = require("../Style/Sheet")

export type Props = {
	-- Names its screen, for finding it in tests.
	name: string?,
	-- Its screen's DisplayOrder; above most interfaces by default.
	displayOrder: number?,
	children: React.ReactNode?,
}

local DISPLAY_ORDER = 500

local e = React.createElement

local function Portal(props: Props): React.ReactNode
	local player = Players.LocalPlayer
	local playerGui = if player
		then player:FindFirstChildOfClass("PlayerGui")
		else nil
	local content =
		e(Context.Provider, { value = Context.root() }, props.children)
	if playerGui == nil then
		return content
	end
	local screen = e("ScreenGui", {
		DisplayOrder = props.displayOrder or DISPLAY_ORDER,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		-- z-index orders siblings, as CSS stacking does.
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		Styles = e("StyleLink", { StyleSheet = Sheet.get() }),
		Content = content,
	})
	-- Named by its key, as React names an instance.
	local named: { [string]: React.ReactNode } =
		{ [props.name or "TailwindPortal"] = screen }
	return ReactRoblox.createPortal(
		e(React.Fragment, nil, named),
		playerGui
	)
end

return Portal
