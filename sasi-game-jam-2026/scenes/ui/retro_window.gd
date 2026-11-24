extends RefCounted

const INK: Color = Color("#181322")
const CREAM: Color = Color("#faf0dd")
const MUTED: Color = Color("#c9c5df")
const FRAME: Color = Color("#8f7aa6")
const BEVEL_LIGHT: Color = Color("#d8be92")
const BEVEL_DARK: Color = Color("#4a3c5c")
const TITLE: Color = Color("#372c48")
const BODY: Color = Color("#241c31")
const BODY_HUD: Color = Color("#1e172ae0")
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
	control.set_deferred(&"size", rect.size)


static func block(parent: Node, rect: Rect2, color: Color) -> ColorRect:
	var block_rect: ColorRect = ColorRect.new()
	block_rect.color = color
	block_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(block_rect, parent, rect)
	return block_rect


static func label(parent: Node, rect: Rect2, content: String, font_size: int,
		color: Color = CREAM, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		shadow: bool = true) -> Label:
	var caption: Label = Label.new()
	caption.text = content
	caption.horizontal_alignment = alignment
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override(&"font_size", font_size)
	caption.add_theme_color_override(&"font_color", color)
	if shadow:
		caption.add_theme_color_override(&"font_shadow_color", Color(0.08, 0.05, 0.12, 0.85))
		caption.add_theme_constant_override(&"shadow_offset_x", 1)
		caption.add_theme_constant_override(&"shadow_offset_y", 1)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(caption, parent, rect)
	return caption


static func panel(parent: Node, rect: Rect2, translucent: bool = false,
		highlight: bool = false) -> Panel:
	var frame: Panel = Panel.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	place(frame, parent, rect)
	block(frame, Rect2(Vector2(2, 2), rect.size), Color(0.05, 0.03, 0.09, 0.65))
	var shell: Panel = Panel.new()
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell.add_theme_stylebox_override(&"panel", style(GOLD if highlight else FRAME, INK, 1))
	place(shell, frame, Rect2(Vector2.ZERO, rect.size))
	var inner: Panel = Panel.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_stylebox_override(&"panel", style(BODY_HUD if translucent else BODY, INK, 1))
	place(inner, frame, Rect2(Vector2(2, 2), rect.size - Vector2(4, 4)))
	var accent: Color = GOLD if highlight else BEVEL_LIGHT
	block(frame, Rect2(3, 3, maxf(0.0, rect.size.x - 6), 1), Color(accent, 0.45))
	for corner: Vector2 in [
		Vector2(2, 2),
		Vector2(rect.size.x - 4, 2),
		Vector2(2, rect.size.y - 4),
		Vector2(rect.size.x - 4, rect.size.y - 4),
	]:
		block(frame, Rect2(corner, Vector2(2, 2)), accent)
	return frame


static func divider(parent: Node, rect: Rect2) -> void:
	block(parent, Rect2(rect.position, Vector2(rect.size.x, 1)), BEVEL_DARK)
	block(parent, Rect2(rect.position, Vector2(2, 1)), BEVEL_LIGHT)
	block(parent, Rect2(Vector2(rect.position.x + rect.size.x - 2, rect.position.y), Vector2(2, 1)), BEVEL_LIGHT)


static func window(parent: Node, rect: Rect2, caption: String = "") -> Panel:
	var frame: Panel = panel(parent, rect, false, false)
	if not caption.is_empty():
		label(frame, Rect2(12, 7, rect.size.x - 24, 18), caption, 13, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		divider(frame, Rect2(16, 27, rect.size.x - 32, 1))
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
	action.add_theme_color_override(&"font_shadow_color", Color(0.08, 0.05, 0.12, 0.85))
	action.add_theme_constant_override(&"shadow_offset_x", 1)
	action.add_theme_constant_override(&"shadow_offset_y", 1)
	action.add_theme_stylebox_override(&"normal", style(TITLE, FRAME, 1))
	action.add_theme_stylebox_override(&"hover", style(Color("#3c5560"), MINT, 2))
	action.add_theme_stylebox_override(&"pressed", style(BODY, GOLD, 2))
	action.add_theme_stylebox_override(&"disabled", style(INK, BEVEL_DARK, 1))
	place(action, parent, rect)
	return action


static func meter(parent: Node, rect: Rect2, color: Color) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.step = 0.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override(&"background", style(INK, BEVEL_DARK, 1))
	bar.add_theme_stylebox_override(&"fill", style(color, color, 0))
	place(bar, parent, rect)
	return bar


static func slider(parent: Node, rect: Rect2, fill_color: Color) -> HSlider:
	var bar: HSlider = HSlider.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.step = 5.0
	bar.focus_mode = Control.FOCUS_NONE
	bar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var track: StyleBoxFlat = style(INK, BEVEL_DARK, 1)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	var filled: StyleBoxFlat = style(fill_color, fill_color, 0)
	filled.content_margin_top = 4
	filled.content_margin_bottom = 4
	var filled_hover: StyleBoxFlat = style(fill_color.lightened(0.14), fill_color.lightened(0.14), 0)
	filled_hover.content_margin_top = 4
	filled_hover.content_margin_bottom = 4
	bar.add_theme_stylebox_override(&"slider", track)
	bar.add_theme_stylebox_override(&"grabber_area", filled)
	bar.add_theme_stylebox_override(&"grabber_area_highlight", filled_hover)
	bar.add_theme_icon_override(&"grabber", _grabber_texture(CREAM))
	bar.add_theme_icon_override(&"grabber_highlight", _grabber_texture(fill_color.lightened(0.25)))
	place(bar, parent, rect)
	return bar


static func _grabber_texture(fill: Color) -> ImageTexture:
	var img: Image = Image.create_empty(8, 14, false, Image.FORMAT_RGBA8)
	img.fill(INK)
	img.fill_rect(Rect2i(1, 1, 6, 12), fill)
	return ImageTexture.create_from_image(img)
