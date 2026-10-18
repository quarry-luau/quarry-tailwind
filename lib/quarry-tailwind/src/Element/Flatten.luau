--!strict
-- React children with nested lists spliced in place and numbered in order,
-- as React flattens nested arrays. Keyed children (at any depth) keep their
-- keys; holes (`if icon then ... else nil` leaves one) are skipped.

local Nodes = require("./Nodes")
local React = require("../../React")

type List = Nodes.List

-- The highest numbered position in `items`.
local function last(items: List): number
	local highest = 0
	for key in items do
		if type(key) == "number" and key > highest then
			highest = key
		end
	end
	return highest
end

local function add(items: List, into: List, count: number): number
	for key, child in items do
		if type(key) == "string" then
			into[key] = child
		end
	end
	local total = count
	for position = 1, last(items) do
		local child: React.ReactNode = items[position]
		local nested = Nodes.list(child)
		if nested then
			total = add(nested, into, total)
		elseif child ~= nil then
			total += 1
			into[total] = child
		end
	end
	return total
end

local function flatten(list: List): List
	local result: List = {}
	add(list, result, 0)
	return result
end

return flatten
