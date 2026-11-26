extends CanvasLayer

const Retro = preload("res://scenes/ui/retro_window.gd")
const Story = preload("res://scripts/data/story_dialogues.gd")
const STUDENT = preload("res://assets/sprites/student_sheet.png")
const CLASSMATE = preload("res://assets/sprites/classmate_sheet.png")
const PORTRAITS = preload("res://assets/sprites/cutscene_portraits.png")

var active_sequence: String = ""
var _lines: Array = []
var _index: int
var _elapsed: float
var _letter_count: int
var _finishing: bool
var _on_finished: Callable
var _atlas: AtlasTexture = AtlasTexture.new()
var _portrait_rect: TextureRect
var _speaker: Label
var _text: RichTextLabel
var _raw_text: String = ""
var _continue_arrow: Label


func _ready() -> void:
	var panel: Panel = Retro.panel(self, Rect2(48, 260, 544, 88), true, false)
	var portrait_frame: Panel = Panel.new()
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_frame.add_theme_stylebox_override(&"panel", Retro.pixel_card_box(Retro.INK, Retro.FRAME))
	Retro.place(portrait_frame, panel, Rect2(12, 11, 64, 66))
	_portrait_rect = TextureRect.new()
	_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_atlas.filter_clip = true
	_atlas.atlas = PORTRAITS
	_portrait_rect.texture = _atlas
	Retro.place(_portrait_rect, panel, Rect2(14, 13, 60, 62))
	_speaker = Retro.label(panel, Rect2(86, 10, 446, 17), "", 13, Retro.GOLD)
	_text = Retro.rich_label(panel, Rect2(86, 27, 446, 38), "", 13)
	_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	Retro.rich_label(panel, Rect2(86, 68, 410, 14), "[ESPAÇO / CLIQUE] Próximo    •    [ESC] Pular", 10, Retro.MUTED)
	_continue_arrow = Retro.label(panel, Rect2(500, 67, 32, 15), "▼", 11, Retro.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	_continue_arrow.hide()
	GameManager.state_changed.connect(_on_state_changed)
	hide()


func play_sequence(sequence_id: String, on_finished: Callable = Callable()) -> void:
	var lines: Array = Story.SEQUENCES.get(sequence_id, [])
	if lines.is_empty():
		if on_finished.is_valid():
			on_finished.call()
		return
	_lines = lines
	active_sequence = sequence_id
	_index = 0
	_finishing = false
	_on_finished = on_finished
	_show_line()
	show()
	GameManager.set_state(GameManager.GameState.DIALOGUE)


func _show_line() -> void:
	var entry: Dictionary = _lines[_index]
	_speaker.text = entry["speaker"]
	_raw_text = entry["text"]
	_text.text = Retro.highlight_keys(_raw_text)
	_text.visible_characters = 0
	_elapsed = 0.0
	_letter_count = 0
	_continue_arrow.hide()
	_portrait_rect.position.y = 13.0
	var classmate: bool = entry["portrait"] == "classmate"
	var frame_idx: int = 4 if classmate else (
			3 if (active_sequence == "victory" or GameManager.in_respite_room)
			else clampi(GameManager.get_cycle() - 1, 0, 2))
	_atlas.atlas = PORTRAITS
	_atlas.region = Rect2(frame_idx * 48, 0, 48, 48)


func _process(delta: float) -> void:
	if active_sequence.is_empty() or _finishing:
		return
	_elapsed += delta
	var typing: bool = _text.visible_characters < _text.text.length()
	if typing:
		_portrait_rect.position.y = 13.0 - (1.0 if int(_elapsed * 14.0) % 2 == 1 else 0.0)
	else:
		_portrait_rect.position.y = 13.0
	_continue_arrow.visible = not typing
	if _continue_arrow.visible:
		_continue_arrow.position.y = 67.0 + roundf(sin(_elapsed * 7.0) * 1.5)
	var raw_len: int = _raw_text.length()
	var prev_raw: int = mini(_text.visible_characters, raw_len)
	var target_raw: int = mini(int(_elapsed * 45.0), raw_len)
	for index: int in range(prev_raw, target_raw):
		if _raw_text[index].to_lower() != _raw_text[index].to_upper():
			_letter_count += 1
			if _letter_count % 3 == 0:
				AudioManager.play_voice_blip()
	if int(_elapsed * 45.0) >= raw_len:
		_text.visible_characters = _text.text.length()
	else:
		_text.visible_characters = maxi(_text.visible_characters, target_raw)


func _input(event: InputEvent) -> void:
	if active_sequence.is_empty():
		return
	var key: InputEventKey = event as InputEventKey
	var click: InputEventMouseButton = event as InputEventMouseButton
	if key != null and key.keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		if key.pressed and not key.echo and not _finishing:
			if key.keycode == KEY_ESCAPE:
				_finish()
			else:
				_advance()
	elif click != null and click.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if click.pressed and not _finishing:
			_advance()


func _advance() -> void:
	if _text.visible_characters < _text.text.length():
		_text.visible_characters = _text.text.length()
	elif _index + 1 < _lines.size():
		_index += 1
		_show_line()
	else:
		_finish()


func _finish() -> void:
	_finishing = true
	# O jogador lê Input no tick físico. Deixe esse tick terminar em diálogo.
	await get_tree().create_timer(0.0, true, true).timeout
	if not _finishing or GameManager.current_state != GameManager.GameState.DIALOGUE:
		return
	var callback: Callable = _on_finished
	GameManager.set_state(GameManager.GameState.PLAYING)
	if callback.is_valid():
		callback.call()


func _on_state_changed(state: GameManager.GameState) -> void:
	if state != GameManager.GameState.DIALOGUE:
		active_sequence = ""
		_finishing = false
		_on_finished = Callable()
		hide()
