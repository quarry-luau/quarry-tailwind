--!strict
-- Assertions for the Lune tests. Each raises an error naming what was expected.

local Unknown = require("./unknown")

local expect = {}

local function show(value: unknown): string
	return if type(value) == "string"
		then string.format("%q", value)
		else tostring(value)
end

function expect.equal(actual: unknown, expected: unknown)
	if actual ~= expected then
		error(`expected {show(expected)}, got {show(actual)}`, 2)
	end
end

function expect.truthy(value: unknown)
	if not value then
		error(`expected a truthy value, got {show(value)}`, 2)
	end
end

-- Asserts that `text` contains `fragment` literally.
function expect.contains(text: string, fragment: string)
	if not string.find(text, fragment, 1, true) then
		error(`expected {show(text)} to contain {show(fragment)}`, 2)
	end
end

local function deepEqual(a: unknown, b: unknown): boolean
	if a == b then
		return true
	end
	local left, right = Unknown.fields(a), Unknown.fields(b)
	if not left or not right then
		return false
	end
	for key, value in left do
		if not deepEqual(value, right[key]) then
			return false
		end
	end
	for key in right do
		if left[key] == nil then
			return false
		end
	end
	return true
end

function expect.deepEqual(actual: unknown, expected: unknown)
	if not deepEqual(actual, expected) then
		error("tables are not deeply equal", 2)
	end
end

-- Asserts that `body` raises an error and returns its message.
function expect.throws(body: () -> ()): string
	local message: string? = nil
	xpcall(body, function(raised: unknown)
		message = tostring(raised)
	end)
	if message == nil then
		error("expected an error, none was raised", 2)
	end
	return message
end

return expect
