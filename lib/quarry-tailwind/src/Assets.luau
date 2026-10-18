--!strict
-- The images the package draws with, uploaded to Roblox from assets/: the
-- blurred boxes shadows are 9-sliced from (tools/make-shadow.py), one per
-- corner radius, smallest first, and one period of a dashed line across and
-- down (tools/make-dash.py).

export type Shadow = { corner: number, image: string }

local shadows: { Shadow } = {
	{ corner = 0, image = "rbxassetid://79974134774505" },
	{ corner = 8, image = "rbxassetid://81523909988358" },
	{ corner = 16, image = "rbxassetid://124602143751850" },
	{ corner = 24, image = "rbxassetid://88698904073873" },
	{ corner = 32, image = "rbxassetid://110883809312153" },
	{ corner = 48, image = "rbxassetid://86049603817275" },
	{ corner = 64, image = "rbxassetid://85829496958633" },
	{ corner = 96, image = "rbxassetid://100616240476959" },
	{ corner = 128, image = "rbxassetid://131143648185129" },
	{ corner = 192, image = "rbxassetid://98207902641458" },
	{ corner = 256, image = "rbxassetid://106082288936704" },
}

return {
	shadows = shadows,
	dashAcross = "rbxassetid://84587028337185",
	dashDown = "rbxassetid://126052029162383",
}
