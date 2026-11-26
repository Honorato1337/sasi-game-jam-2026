extends RefCounted

const FONT_REGULAR: Font = preload("res://assets/fonts/PixelifySans-Regular.ttf")
const FONT_BOLD: Font = preload("res://assets/fonts/PixelifySans-Bold.ttf")

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
const KEY_RED: Color = Color("#ff5263")

static var _box_cache: Dictionary[String, StyleBoxTexture] = {}
static var _key_regex: RegEx


static func style(fill: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.anti_aliasing = false
	return box


static func pixel_panel_box(fill: Color, border: Color, highlight: Color,
		shadow_bevel: Color) -> StyleBoxTexture:
	var key: String = "panel_%s_%s_%s_%s" % [fill.to_html(), border.to_html(), highlight.to_html(), shadow_bevel.to_html()]
	if _box_cache.has(key):
		return _box_cache[key]
	var img: Image = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(4, 4, 8, 8), fill)
	img.fill_rect(Rect2i(3, 3, 10, 10), INK)
	img.fill_rect(Rect2i(4, 4, 8, 8), fill)
	img.fill_rect(Rect2i(2, 2, 12, 1), highlight)
	img.fill_rect(Rect2i(2, 2, 1, 12), highlight)
	img.fill_rect(Rect2i(3, 13, 11, 1), shadow_bevel)
	img.fill_rect(Rect2i(13, 3, 1, 11), shadow_bevel)
	for stud: Vector2i in [Vector2i(2, 2), Vector2i(13, 2), Vector2i(2, 13), Vector2i(13, 13)]:
		img.set_pixelv(stud, highlight)
	img.fill_rect(Rect2i(2, 1, 12, 1), border)
	img.fill_rect(Rect2i(2, 14, 12, 1), border)
	img.fill_rect(Rect2i(1, 2, 1, 12), border)
	img.fill_rect(Rect2i(14, 2, 1, 12), border)
	img.fill_rect(Rect2i(2, 0, 12, 1), INK)
	img.fill_rect(Rect2i(2, 15, 12, 1), INK)
	img.fill_rect(Rect2i(0, 2, 1, 12), INK)
	img.fill_rect(Rect2i(15, 2, 1, 12), INK)
	for corner: Vector2i in [Vector2i(1, 1), Vector2i(14, 1), Vector2i(1, 14), Vector2i(14, 14)]:
		img.set_pixelv(corner, INK)
	var box: StyleBoxTexture = _make_texture_box(img, 5.0, 0.0, 0.0)
	_box_cache[key] = box
	return box


static func pixel_button_box(fill: Color, border: Color, highlight: Color,
		shadow_bevel: Color, pressed: bool = false) -> StyleBoxTexture:
	var key: String = "btn_org_%s_%s_%s_%s_%s" % [fill.to_html(), border.to_html(), highlight.to_html(), shadow_bevel.to_html(), pressed]
	if _box_cache.has(key):
		return _box_cache[key]
	const W: int = 48
	const H: int = 28
	var img: Image = Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(key)
	var bayer: Array[float] = [0.0, 0.5, 0.75, 0.25]
	var lit_top: Color = fill.lightened(0.09)
	var lit_mid: Color = fill.lightened(0.03)
	var shade_low: Color = fill.darkened(0.14)
	for y: int in range(3, H - 3):
		var raw_t: float = float(y - 3) / float(H - 7)
		var t: float = 1.0 - raw_t if pressed else raw_t
		for x: int in range(3, W - 3):
			var threshold: float = bayer[((x & 1) * 2) + (y & 1)]
			var px: Color = fill
			if t < 0.28:
				var f: float = 1.0 - t / 0.28
				px = lit_top if f > threshold else lit_mid
			elif t > 0.70:
				var f: float = (t - 0.70) / 0.30
				px = shade_low if f > threshold else fill
			if rng.randf() < 0.11:
				px = px.lightened(0.04) if rng.randf() < 0.5 else px.darkened(0.05)
			img.set_pixel(x, y, px)

	# Estrias orgânicas horizontais simulando placa entalhada.
	for row_y: int in range(5, H - 5, 3):
		var cursor_x: int = rng.randi_range(5, 11)
		while cursor_x < W - 8:
			var span: int = rng.randi_range(3, 8)
			var tone: Color = fill.lightened(0.06) if (row_y + cursor_x) % 2 == 0 else fill.darkened(0.07)
			for dx: int in range(mini(span, W - 5 - cursor_x)):
				img.set_pixel(cursor_x + dx, row_y, tone)
			cursor_x += span + rng.randi_range(4, 9)

	if not pressed:
		img.fill_rect(Rect2i(3, H - 4, W - 6, 1), fill.darkened(0.20))

	var top_left: Color = shadow_bevel if pressed else highlight
	var bottom_right: Color = highlight if pressed else shadow_bevel
	img.fill_rect(Rect2i(2, 2, W - 4, 1), top_left)
	img.fill_rect(Rect2i(2, 2, 1, H - 4), top_left)
	img.fill_rect(Rect2i(3, H - 3, W - 5, 1), bottom_right)
	img.fill_rect(Rect2i(W - 3, 3, 1, H - 5), bottom_right)
	for chip_x: int in [16, 31]:
		img.set_pixel(chip_x, 2, top_left.lerp(border, 0.55))
		img.set_pixel(chip_x + 2, H - 3, bottom_right.lerp(border, 0.55))

	img.fill_rect(Rect2i(2, 1, W - 4, 1), border)
	img.fill_rect(Rect2i(2, H - 2, W - 4, 1), border)
	img.fill_rect(Rect2i(1, 2, 1, H - 4), border)
	img.fill_rect(Rect2i(W - 2, 2, 1, H - 4), border)
	for rim_x: int in [11, 22, 34]:
		img.set_pixel(rim_x, 1, border.lerp(highlight, 0.35))
		img.set_pixel(rim_x, H - 2, border.lerp(shadow_bevel, 0.45))

	img.fill_rect(Rect2i(2, 0, W - 4, 1), INK)
	img.fill_rect(Rect2i(2, H - 1, W - 4, 1), INK)
	img.fill_rect(Rect2i(0, 2, 1, H - 4), INK)
	img.fill_rect(Rect2i(W - 1, 2, 1, H - 4), INK)
	for notch: Vector2i in [Vector2i(1, 1), Vector2i(W - 2, 1), Vector2i(1, H - 2), Vector2i(W - 2, H - 2)]:
		img.set_pixelv(notch, INK)

	for stud_pair: Array in [
		[Vector2i(3, 3), Vector2i(4, 3)],
		[Vector2i(W - 4, 3), Vector2i(W - 5, 3)],
		[Vector2i(3, H - 4), Vector2i(4, H - 4)],
		[Vector2i(W - 4, H - 4), Vector2i(W - 5, H - 4)],
	]:
		img.set_pixelv(stud_pair[0] as Vector2i, highlight)
		img.set_pixelv(stud_pair[1] as Vector2i, shadow_bevel)

	var box: StyleBoxTexture = _make_texture_box(img, 7.0, 5.0, 2.0)
	_box_cache[key] = box
	return box


static func pixel_focus_box(border: Color) -> StyleBoxTexture:
	var key: String = "focus2_%s" % border.to_html()
	if _box_cache.has(key):
		return _box_cache[key]
	var img: Image = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(2, 0, 12, 1), INK)
	img.fill_rect(Rect2i(2, 15, 12, 1), INK)
	img.fill_rect(Rect2i(0, 2, 1, 12), INK)
	img.fill_rect(Rect2i(15, 2, 1, 12), INK)
	for notch: Vector2i in [Vector2i(1, 1), Vector2i(14, 1), Vector2i(1, 14), Vector2i(14, 14)]:
		img.set_pixelv(notch, INK)
	img.fill_rect(Rect2i(2, 1, 12, 2), border)
	img.fill_rect(Rect2i(2, 13, 12, 2), border)
	img.fill_rect(Rect2i(1, 2, 2, 12), border)
	img.fill_rect(Rect2i(13, 2, 2, 12), border)
	img.fill_rect(Rect2i(3, 3, 10, 10), Color(0, 0, 0, 0))
	var box: StyleBoxTexture = _make_texture_box(img, 5.0, 0.0, 0.0)
	_box_cache[key] = box
	return box


static func pixel_card_box(fill: Color, border: Color) -> StyleBoxTexture:
	var key: String = "card_%s_%s" % [fill.to_html(), border.to_html()]
	if _box_cache.has(key):
		return _box_cache[key]
	var img: Image = Image.create_empty(12, 12, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(2, 2, 8, 8), fill)
	img.fill_rect(Rect2i(2, 1, 8, 1), border)
	img.fill_rect(Rect2i(2, 10, 8, 1), border)
	img.fill_rect(Rect2i(1, 2, 1, 8), border)
	img.fill_rect(Rect2i(10, 2, 1, 8), border)
	img.fill_rect(Rect2i(1, 0, 10, 1), INK)
	img.fill_rect(Rect2i(1, 11, 10, 1), INK)
	img.fill_rect(Rect2i(0, 1, 1, 10), INK)
	img.fill_rect(Rect2i(11, 1, 1, 10), INK)
	for notch: Vector2i in [Vector2i(1, 1), Vector2i(10, 1), Vector2i(1, 10), Vector2i(10, 10)]:
		img.set_pixelv(notch, INK)
	var box: StyleBoxTexture = _make_texture_box(img, 3.0, 1.0, 1.0)
	_box_cache[key] = box
	return box


static func _pixel_meter_fill_box(color: Color) -> StyleBoxTexture:
	var key: String = "mfill_%s" % color.to_html()
	if _box_cache.has(key):
		return _box_cache[key]
	var img: Image = Image.create_empty(4, 6, false, Image.FORMAT_RGBA8)
	img.fill(color)
	img.fill_rect(Rect2i(0, 0, 4, 1), color.lightened(0.26))
	var box: StyleBoxTexture = _make_texture_box(img, 1.0, 0.0, 0.0)
	_box_cache[key] = box
	return box


static func _make_texture_box(img: Image, margin: float, pad_x: float,
		pad_y: float) -> StyleBoxTexture:
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	var box: StyleBoxTexture = StyleBoxTexture.new()
	box.texture = tex
	box.texture_margin_left = margin
	box.texture_margin_right = margin
	box.texture_margin_top = margin
	box.texture_margin_bottom = margin
	box.content_margin_left = pad_x
	box.content_margin_right = pad_x
	box.content_margin_top = pad_y
	box.content_margin_bottom = pad_y
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
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


static func highlight_keys(content: String, key_color: Color = KEY_RED) -> String:
	if _key_regex == null:
		_key_regex = RegEx.new()
		_key_regex.compile("\\[([^\\[\\]]+)\\]")
	var matches: Array[RegExMatch] = _key_regex.search_all(content)
	if matches.is_empty():
		return content
	var hex: String = key_color.to_html(false)
	var result: String = ""
	var cursor: int = 0
	for hit: RegExMatch in matches:
		result += content.substr(cursor, hit.get_start() - cursor)
		result += "[color=#%s][lb]%s[rb][/color]" % [hex, hit.get_string(1)]
		cursor = hit.get_end()
	result += content.substr(cursor)
	return result


static func rich_label(parent: Node, rect: Rect2, content: String, font_size: int,
		color: Color = CREAM, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		shadow: bool = true, key_color: Color = KEY_RED) -> RichTextLabel:
	var caption: RichTextLabel = RichTextLabel.new()
	caption.bbcode_enabled = true
	caption.scroll_active = false
	caption.fit_content = false
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = alignment
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())
	caption.add_theme_font_size_override(&"normal_font_size", font_size)
	caption.add_theme_font_size_override(&"bold_font_size", font_size)
	caption.add_theme_color_override(&"default_color", color)
	if shadow:
		caption.add_theme_color_override(&"font_shadow_color", Color(0.08, 0.05, 0.12, 0.85))
		caption.add_theme_constant_override(&"shadow_offset_x", 1)
		caption.add_theme_constant_override(&"shadow_offset_y", 1)
	caption.text = highlight_keys(content, key_color)
	place(caption, parent, rect)
	return caption


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
	var shadow_color: Color = Color(0.05, 0.03, 0.09, 0.55)
	var drop: Panel = Panel.new()
	drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	drop.add_theme_stylebox_override(&"panel", pixel_card_box(shadow_color, shadow_color))
	place(drop, frame, Rect2(Vector2(2, 2), rect.size))
	var shell: Panel = Panel.new()
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var box: StyleBoxTexture = pixel_panel_box(
		BODY_HUD if translucent else BODY,
		GOLD if highlight else FRAME,
		GOLD.lightened(0.22) if highlight else BEVEL_LIGHT,
		Color("#8a5f3c") if highlight else BEVEL_DARK
	)
	shell.add_theme_stylebox_override(&"panel", box)
	place(shell, frame, Rect2(Vector2.ZERO, rect.size))
	return frame


static func divider(parent: Node, rect: Rect2) -> void:
	block(parent, Rect2(rect.position, Vector2(rect.size.x, 1)), BEVEL_DARK)
	block(parent, Rect2(rect.position, Vector2(2, 1)), BEVEL_LIGHT)
	block(parent, Rect2(Vector2(rect.position.x + rect.size.x - 2, rect.position.y), Vector2(2, 1)), BEVEL_LIGHT)


static func window(parent: Node, rect: Rect2, caption: String = "") -> Panel:
	var frame: Panel = panel(parent, rect, false, false)
	if not caption.is_empty():
		var header: Label = label(frame, Rect2(12, 7, rect.size.x - 24, 18), caption, 13, GOLD,
				HORIZONTAL_ALIGNMENT_CENTER)
		header.add_theme_font_override(&"font", FONT_BOLD)
		divider(frame, Rect2(16, 27, rect.size.x - 32, 1))
	return frame


static func button(parent: Node, rect: Rect2, content: String = "") -> Button:
	var action: Button = Button.new()
	action.text = content
	action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	action.focus_mode = Control.FOCUS_NONE
	action.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	action.add_theme_font_size_override(&"font_size", 12)
	action.add_theme_color_override(&"font_color", CREAM)
	action.add_theme_color_override(&"font_hover_color", CREAM)
	action.add_theme_color_override(&"font_pressed_color", CREAM)
	action.add_theme_color_override(&"font_shadow_color", Color(0.08, 0.05, 0.12, 0.85))
	action.add_theme_constant_override(&"shadow_offset_x", 1)
	action.add_theme_constant_override(&"shadow_offset_y", 1)
	action.add_theme_stylebox_override(&"normal",
			pixel_button_box(Color("#3a2c4a"), Color("#9982ad"), Color("#c4a8d1"), Color("#22182e"), false))
	action.add_theme_stylebox_override(&"hover",
			pixel_button_box(Color("#33535c"), MINT, Color("#c0fae4"), Color("#1e343b"), false))
	action.add_theme_stylebox_override(&"pressed",
			pixel_button_box(Color("#251c32"), GOLD, Color("#ffe3a0"), Color("#8a5d36"), true))
	action.add_theme_stylebox_override(&"disabled",
			pixel_button_box(INK, BEVEL_DARK, Color("#342a42"), INK, false))
	place(action, parent, rect)
	return action


static func meter(parent: Node, rect: Rect2, color: Color) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.step = 0.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bar.add_theme_stylebox_override(&"background", pixel_card_box(INK, BEVEL_DARK))
	bar.add_theme_stylebox_override(&"fill", _pixel_meter_fill_box(color))
	place(bar, parent, rect)
	return bar


static func slider(parent: Node, rect: Rect2, fill_color: Color) -> HSlider:
	var bar: HSlider = HSlider.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.step = 5.0
	bar.focus_mode = Control.FOCUS_NONE
	bar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var track: StyleBoxTexture = pixel_card_box(INK, BEVEL_DARK)
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
	img.fill_rect(Rect2i(1, 0, 6, 14), INK)
	img.fill_rect(Rect2i(0, 1, 8, 12), INK)
	img.fill_rect(Rect2i(1, 1, 6, 12), fill)
	img.fill_rect(Rect2i(2, 1, 4, 1), fill.lightened(0.25))
	return ImageTexture.create_from_image(img)
