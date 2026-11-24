extends RefCounted

const INK: Color = Color("#231e2e")
const CREAM: Color = Color("#faf0dd")
const MUTED: Color = Color("#c9c5df")
const FRAME: Color = Color("#7272a2")
const TITLE: Color = Color("#535479")
const BODY: Color = Color("#32263a")
const MINT: Color = Color("#81e6c0")
const GOLD: Color = Color("#f4ba72")


static func style(fill: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.anti_aliasing = false
	return box


static func place(control: Control, parent: Node, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size
	parent.add_child(control)


static func block(parent: Node, rect: Rect2, color: Color) -> ColorRect:
	var block_rect: ColorRect = ColorRect.new()
	block_rect.color = color
	block_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(block_rect, parent, rect)
	return block_rect


static func label(parent: Node, rect: Rect2, content: String, font_size: int,
		color: Color = CREAM, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var caption: Label = Label.new()
	caption.text = content
	caption.horizontal_alignment = alignment
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override(&"font_size", font_size)
	caption.add_theme_color_override(&"font_color", color)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(caption, parent, rect)
	return caption


static func window(parent: Node, rect: Rect2, caption: String) -> Panel:
	var frame: Panel = Panel.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	place(frame, parent, rect)
	block(frame, Rect2(Vector2(3, 3), rect.size), INK)
	var shell: Panel = Panel.new()
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell.add_theme_stylebox_override(&"panel", style(FRAME, INK, 2))
	place(shell, frame, Rect2(Vector2.ZERO, rect.size))
	var inner: Panel = Panel.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_stylebox_override(&"panel", style(BODY, INK))
	place(inner, frame, Rect2(Vector2(3, 3), rect.size - Vector2(6, 6)))
	block(frame, Rect2(4, 4, rect.size.x - 8, 15), TITLE)
	block(frame, Rect2(4, 19, rect.size.x - 8, 1), INK)
	label(frame, Rect2(8, 3, rect.size.x - 60, 16), caption, 10)
	for index: int in range(3):
		var x: float = rect.size.x - 40 + index * 12
		block(frame, Rect2(x, 6, 10, 10), INK)
		block(frame, Rect2(x + 1, 7, 8, 8), FRAME)
		match index:
			0:
				block(frame, Rect2(x + 3, 12, 4, 1), CREAM)
			1:
				block(frame, Rect2(x + 3, 9, 4, 4), CREAM)
				block(frame, Rect2(x + 4, 10, 2, 2), FRAME)
			2:
				for pixel: int in range(5):
					block(frame, Rect2(x + 3 + pixel, 9 + pixel, 1, 1), CREAM)
					block(frame, Rect2(x + 7 - pixel, 9 + pixel, 1, 1), CREAM)
	return frame


static func button(parent: Node, rect: Rect2, content: String = "") -> Button:
	var action: Button = Button.new()
	action.text = content
	action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	action.focus_mode = Control.FOCUS_NONE
	action.add_theme_font_size_override(&"font_size", 12)
	action.add_theme_color_override(&"font_color", CREAM)
	action.add_theme_color_override(&"font_hover_color", CREAM)
	action.add_theme_color_override(&"font_pressed_color", CREAM)
	action.add_theme_stylebox_override(&"normal", style(TITLE, FRAME))
	action.add_theme_stylebox_override(&"hover", style(Color("#455e68"), MINT, 2))
	action.add_theme_stylebox_override(&"pressed", style(BODY, GOLD, 2))
	action.add_theme_stylebox_override(&"disabled", style(INK, TITLE))
	place(action, parent, rect)
	return action


static func meter(parent: Node, rect: Rect2, color: Color) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.step = 0.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override(&"background", style(INK, FRAME))
	bar.add_theme_stylebox_override(&"fill", style(color, color, 0))
	place(bar, parent, rect)
	return bar
