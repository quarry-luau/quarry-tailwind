--!strict
-- What an element takes, as a DOM element's attributes. The one definition:
-- `h` takes it, the element reads it, and its states and text box read the
-- parts they use.

export type Attributes = {
	className: string?,
	layoutOrder: number?,
	disabled: boolean?,
	-- data-* attributes, as Radix sets them: { state = "checked" } is
	-- data-[state=checked].
	data: { [string]: string }?,
	-- aria-pressed.
	pressed: boolean?,
	onClick: (() -> ())?,
	-- The instance's Name, for finding it in tests.
	name: string?,
	-- The picture an `img` shows.
	image: string?,
	-- An `input`'s text, the hint shown while it is empty, and what it
	-- calls as the text changes and when Enter is pressed.
	value: string?,
	placeholder: string?,
	onChange: ((text: string) -> ())?,
	onSubmit: ((text: string) -> ())?,
}

return {}
