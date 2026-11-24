extends CanvasLayer

const Retro = preload("res://scenes/ui/retro_window.gd")
const Story = preload("res://scripts/data/story_dialogues.gd")
const STUDENT = preload("res://assets/sprites/student_sheet.png")
const CLASSMATE = preload("res://assets/sprites/classmate_sheet.png")

var active_sequence: String = ""
var _lines: Array = []
var _index: int
var _elapsed: float
var _letter_count: int
var _finishing: bool
var _on_finished: Callable
var _atlas: AtlasTexture = AtlasTexture.new()
var _speaker: Label
var _text: Label


func _ready() -> void:
	var panel: Panel = Retro.panel(self, Rect2(48, 260, 544, 88), true, false)
	var portrait_frame: Panel = Panel.new()
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.add_theme_stylebox_override(&"panel", Retro.style(Retro.INK, Retro.FRAME, 1))
	Retro.place(portrait_frame, panel, Rect2(12, 11, 64, 66))
	var portrait: TextureRect = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_atlas.filter_clip = true
	portrait.texture = _atlas
	Retro.place(portrait, panel, Rect2(14, 13, 60, 62))
	_speaker = Retro.label(panel, Rect2(86, 10, 446, 17), "", 13, Retro.GOLD)
	_text = Retro.label(panel, Rect2(86, 28, 446, 36), "", 13)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_text.clip_text = true
	_text.max_lines_visible = 2
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	Retro.label(panel, Rect2(86, 68, 446, 14), "[ESPAÇO / CLIQUE] Próximo    •    [ESC] Pular", 10, Retro.MUTED)
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
	_text.text = entry["text"]
	_text.visible_characters = 0
	_elapsed = 0.0
	_letter_count = 0
	var classmate: bool = entry["portrait"] == "classmate"
	_atlas.atlas = CLASSMATE if classmate else STUDENT
	_atlas.region = Rect2(0, 0, _atlas.atlas.get_width() / (2.0 if classmate else 8.0), _atlas.atlas.get_height())


func _process(delta: float) -> void:
	if active_sequence.is_empty() or _finishing:
		return
	_elapsed += delta
	var region: Rect2 = _atlas.region
	region.position.x = region.size.x * (int(_elapsed * 4.0) % 2)
	_atlas.region = region
	var target: int = mini(int(_elapsed * 45.0), _text.text.length())
	for index: int in range(_text.visible_characters, target):
		if _text.text[index].to_lower() != _text.text[index].to_upper():
			_letter_count += 1
			if _letter_count % 3 == 0:
				AudioManager.play_voice_blip()
	_text.visible_characters = maxi(_text.visible_characters, target)


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
