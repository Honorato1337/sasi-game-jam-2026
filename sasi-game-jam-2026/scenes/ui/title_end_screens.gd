extends CanvasLayer

const Retro = preload("res://scenes/ui/retro_window.gd")
const TITLE_BG: Texture2D = preload("res://assets/sprites/title_bg.png")
const STUDENT_SHEET: Texture2D = preload("res://assets/sprites/student_sheet.png")
const CLASSMATE_SHEET: Texture2D = preload("res://assets/sprites/classmate_sheet.png")
const WINDOW_WIDTH: int = 450
const SETTINGS_PATH: String = "user://settings.cfg"
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

var _title_art: TextureRect
var _backdrop: ColorRect
var _title_fx: Node2D
var _title_window: Panel
var _help_window: Panel
var _settings_window: Panel
var _credits_window: Panel
var _pause_window: Panel
var _end_window: Panel
var _active_window: Panel
var _return_button: Button
var _space_button: Button
var _buttons: Dictionary[Panel, Array] = {}
var _music_slider: HSlider
var _sfx_slider: HSlider
var _music_value: Label
var _sfx_value: Label
var _mute_button: Button
var _shake_button: Button
var _fullscreen_button: Button
var _resolution_button: Button
var _reset_button: Button
var _quit_button: Button
var _sfx_step_buttons: Array[Button] = []
var _syncing_sliders: bool
var _end_caption: Label
var _end_heading: Label
var _end_message: Label
var _stats: Label
var _cursor: Label
var _student_atlas: AtlasTexture = AtlasTexture.new()
var _classmate_atlas: AtlasTexture = AtlasTexture.new()
var _preview_time: float


func _ready() -> void:
	_title_art = TextureRect.new()
	_title_art.texture = TITLE_BG
	_title_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Retro.place(_title_art, self, Rect2(0, 0, 640, 360))

	_backdrop = Retro.block(self, Rect2(0, 0, 640, 360), Color("#140e1fb8"))
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP

	_build_help()
	_build_settings()
	_build_credits()
	_build_title()
	_build_pause()
	_build_end()
	_load_settings()
	_refresh_settings()
	get_viewport().size_changed.connect(_refresh_fullscreen)
	GameManager.state_changed.connect(_on_state_changed)
	_on_state_changed(GameManager.current_state)


func _build_title() -> void:
	_title_window = Panel.new()
	_title_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_window.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	Retro.place(_title_window, self, Rect2(0, 0, 640, 360))
	_title_window.hide()
	_buttons[_title_window] = []

	_title_fx = Node2D.new()
	_title_fx.draw.connect(_draw_title_fx)
	_title_window.add_child(_title_fx)

	_character_actor(_title_window, Rect2(364, 198, 96, 96), STUDENT_SHEET, 8, _student_atlas)
	_character_actor(_title_window, Rect2(464, 200, 96, 96), CLASSMATE_SHEET, 2, _classmate_atlas)

	_outlined_label(_title_window, Rect2(40, 26, 240, 16), "SASI: GAME JAM 2026  •  UFAC",
			10, Retro.MUTED, 3)
	_outlined_label(_title_window, Rect2(38, 44, 290, 40), "TRÊS TURNOS", 32, Retro.GOLD, 6)
	_outlined_label(_title_window, Rect2(40, 86, 250, 20), "Manhã, Tarde e Noite",
			14, Retro.MINT, 4)
	Retro.divider(_title_window, Rect2(40, 110, 212, 1))

	var play: Button = _action(_title_window, Rect2(40, 124, 212, 28), "JOGAR",
			GameManager.start_new_run)
	play.add_theme_stylebox_override(&"normal", Retro.style(Color("#3f3357"), Retro.GOLD, 1))

	var settings: Button = _action(_title_window, Rect2(40, 158, 212, 28), "CONFIGURAÇÕES")
	settings.pressed.connect(_open_subwindow.bind(_settings_window, settings))

	var help: Button = _action(_title_window, Rect2(40, 192, 212, 28), "COMO JOGAR")
	help.pressed.connect(_open_subwindow.bind(_help_window, help))

	var credits: Button = _action(_title_window, Rect2(40, 226, 212, 28), "CRÉDITOS & SAÚDE")
	credits.pressed.connect(_open_subwindow.bind(_credits_window, credits))

	if not OS.has_feature("web"):
		_quit_button = _action(_title_window, Rect2(40, 260, 212, 28), "SAIR", get_tree().quit)

	_cursor = _outlined_label(_title_window, Rect2(24, 124, 14, 28), "▶", 12, Retro.MINT, 3)
	_outlined_label(_title_window, Rect2(40, 330, 320, 18),
			"↑/↓ ou Mouse para navegar  •  Enter / Clique para confirmar", 10, Retro.MUTED, 3)


func _character_actor(parent: Control, rect: Rect2, sheet: Texture2D, frame_count: int,
		atlas: AtlasTexture) -> void:
	atlas.atlas = sheet
	atlas.region = Rect2(0, 0, float(sheet.get_width()) / frame_count, sheet.get_height())
	atlas.filter_clip = true
	var actor: TextureRect = TextureRect.new()
	actor.texture = atlas
	actor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	actor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	actor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Retro.place(actor, parent, rect)


func _outlined_label(parent: Control, rect: Rect2, content: String, font_size: int,
		color: Color, outline: int) -> Label:
	var label_node: Label = Retro.label(parent, rect, content, font_size, color,
			HORIZONTAL_ALIGNMENT_LEFT, false)
	label_node.add_theme_color_override(&"font_outline_color", Color("#140e1f"))
	label_node.add_theme_constant_override(&"outline_size", outline)
	return label_node


func _draw_title_fx() -> void:
	if _title_fx == null or not visible or _active_window != _title_window:
		return
	for shadow_center: Vector2 in [Vector2(412, 286), Vector2(512, 288)]:
		_title_fx.draw_rect(Rect2(shadow_center - Vector2(20, 3), Vector2(40, 6)),
				Color(0.08, 0.05, 0.12, 0.55))
		_title_fx.draw_rect(Rect2(shadow_center - Vector2(14, 5), Vector2(28, 10)),
				Color(0.08, 0.05, 0.12, 0.35))

	var pulse: float = 0.5 + 0.5 * sin(_preview_time * 3.0)
	for radius: float in [42.0, 28.0, 16.0]:
		_title_fx.draw_circle(Vector2(587, 188), radius, Color(0.98, 0.78, 0.44, 0.035 + pulse * 0.02))

	var stars: Array[Vector3] = [
		Vector3(294, 42, 0.0), Vector3(368, 28, 1.3), Vector3(422, 64, 2.4),
		Vector3(486, 36, 0.8), Vector3(598, 72, 1.9), Vector3(340, 88, 2.9),
	]
	for star: Vector3 in stars:
		var glow: float = 0.35 + 0.65 * (0.5 + 0.5 * sin(_preview_time * 3.2 + star.z))
		var pos: Vector2 = Vector2(star.x, star.y)
		_title_fx.draw_rect(Rect2(pos, Vector2(1, 1)), Color(0.98, 0.94, 0.86, glow))
		if glow > 0.82:
			_title_fx.draw_rect(Rect2(pos - Vector2(1, 0), Vector2(3, 1)), Color(0.8, 0.78, 0.9, glow * 0.45))
			_title_fx.draw_rect(Rect2(pos - Vector2(0, 1), Vector2(1, 3)), Color(0.8, 0.78, 0.9, glow * 0.45))

	for idx: int in range(6):
		var phase: float = float(idx) * 1.15
		var mote: Vector2 = Vector2(
			345.0 + float(idx) * 44.0 + sin(_preview_time * 0.9 + phase) * 8.0,
			226.0 + float((idx % 3) * 18) + cos(_preview_time * 1.2 + phase) * 5.0
		).round()
		var alpha: float = 0.25 + 0.45 * (0.5 + 0.5 * sin(_preview_time * 2.5 + phase))
		_title_fx.draw_rect(Rect2(mote, Vector2(2, 2)), Color(0.96, 0.79, 0.48, alpha))


func _process(delta: float) -> void:
	if not visible or _active_window != _title_window:
		return
	_preview_time = fposmod(_preview_time + delta, TAU * 10.0)
	var student_region: Rect2 = _student_atlas.region
	student_region.position.x = student_region.size.x * (int(_preview_time * 2.4) % 2)
	_student_atlas.region = student_region
	var classmate_region: Rect2 = _classmate_atlas.region
	classmate_region.position.x = classmate_region.size.x * (int(_preview_time * 2.0) % 2)
	_classmate_atlas.region = classmate_region
	if _title_fx != null:
		_title_fx.queue_redraw()
	if _cursor != null:
		var focused: Button = get_viewport().gui_get_focus_owner() as Button
		var valid: bool = focused != null and focused.get_parent() == _title_window
		_cursor.visible = valid
		if valid:
			var bob: float = roundf(sin(_preview_time * 7.0) * 1.5)
			_cursor.position = Vector2(focused.position.x - 16.0 + bob, focused.position.y)


func _build_help() -> void:
	_help_window = _window(298, "COMO JOGAR")
	var controls: Array[String] = ["WASD / Setas", "Espaço / Clique", "Shift", "Segurar R", "E", "Esc / P"]
	var actions: Array[String] = ["Mover", "Espada", "Dash", "Respirar", "Interagir", "Pausar"]
	for index: int in range(controls.size()):
		var x: int = 16 + (index % 2) * 213
		var y: int = 36 + floori(index / 2.0) * 27
		Retro.block(_help_window, Rect2(x, y, 205, 24), Retro.INK)
		Retro.label(_help_window, Rect2(x + 8, y, 113, 24), controls[index], 12, Retro.GOLD)
		Retro.label(_help_window, Rect2(x + 121, y, 76, 24), actions[index], 12, Retro.CREAM,
				HORIZONTAL_ALIGNMENT_RIGHT)

	var topics: Array[String] = ["CORPO", "MENTE", "DESCANSO"]
	var explanations: Array[String] = [
		"Corpo baixo encurta a espada e deixa o passo lento.\nBeba água [E] e recolha gotas dos inimigos.",
		"Com a Mente baixa, a visão se fecha. Segure [R]\npara carregar Clareza ou peça ajuda ao colega [E].",
		"Espada e dash gastam energia. Dê uma pausa para\nrecuperá-la. Na última sala, reacenda os pilares [E].",
	]
	for index: int in range(topics.size()):
		var y: int = 122 + index * 43
		Retro.block(_help_window, Rect2(16, y, 418, 38), Retro.INK)
		Retro.label(_help_window, Rect2(24, y, 88, 38), topics[index], 11, Retro.MINT)
		Retro.label(_help_window, Rect2(116, y, 310, 38), explanations[index], 11)
	_back_button(_help_window, 260)


func _build_settings() -> void:
	_settings_window = _window(292, "CONFIGURAÇÕES")
	_music_value = _slider_row(38, "Música", Retro.MINT, _change_music_volume, _on_music_slider_changed, false)
	_sfx_value = _slider_row(72, "Efeitos (SFX)", Retro.GOLD, _change_sfx_volume, _on_sfx_slider_changed, true)
	_mute_button = _toggle_row(106, "Áudio Geral", _toggle_mute)
	_shake_button = _toggle_row(140, "Tremor de Tela", _toggle_shake)
	_fullscreen_button = _toggle_row(174, "Modo de Tela", _toggle_fullscreen)
	_fullscreen_button.disabled = DisplayServer.get_name() == "headless"
	_resolution_button = _toggle_row(208, "Resolução", _cycle_resolution)
	_reset_button = _action(_settings_window, Rect2(40, 248, 178, 28), "RESTAURAR PADRÕES", _reset_settings)
	_action(_settings_window, Rect2(232, 248, 178, 28), "VOLTAR [ESC]", _close_subwindow)


func _slider_row(y: int, caption: String, fill_color: Color, step_change: Callable,
		slide_change: Callable, is_sfx: bool) -> Label:
	_setting_label(y, caption)
	var minus_btn: Button = _action(_settings_window, Rect2(152, y, 32, 26), "[-]", step_change.bind(-10))
	var bar: HSlider = Retro.slider(_settings_window, Rect2(190, y, 134, 26), fill_color)
	bar.value_changed.connect(slide_change)
	var plus_btn: Button = _action(_settings_window, Rect2(330, y, 32, 26), "[+]", step_change.bind(10))
	if is_sfx:
		_sfx_slider = bar
		_sfx_step_buttons.append(minus_btn)
		_sfx_step_buttons.append(plus_btn)
	else:
		_music_slider = bar
	return Retro.label(_settings_window, Rect2(368, y, 58, 26), "", 12, Retro.GOLD,
			HORIZONTAL_ALIGNMENT_RIGHT)


func _toggle_row(y: int, caption: String, action: Callable) -> Button:
	_setting_label(y, caption)
	return _action(_settings_window, Rect2(220, y, 206, 26), "", action)


func _setting_label(y: int, caption: String) -> void:
	Retro.block(_settings_window, Rect2(16, y, 418, 26), Retro.INK)
	Retro.label(_settings_window, Rect2(24, y, 122, 26), caption, 12)


func _build_credits() -> void:
	_credits_window = _window(230, "CRÉDITOS & SAÚDE")
	_centered(_credits_window, 36, 22, "SASI: GAME JAM 2026  •  UFAC", 15, Retro.MINT)
	_centered(_credits_window, 62, 36,
			"Arte pixel e áudio chiptune criados para o jogo.\nDesenvolvimento com apoio de Antigravity e OpenAI Codex.",
			12, Retro.CREAM)
	Retro.block(_credits_window, Rect2(16, 108, 418, 70), Retro.INK)
	_centered(_credits_window, 112, 20, "SAÚDE EM JOGO", 12, Retro.GOLD)
	_centered(_credits_window, 136, 36,
			"Cuidar também passa por perceber os sinais do corpo,\nrespeitar seus limites e dividir a rotina com quem pode ajudar.",
			12, Retro.CREAM)
	_back_button(_credits_window, 192)


func _build_pause() -> void:
	_pause_window = _window(208, "PAUSA")
	_action(_pause_window, Rect2(101, 40, 248, 30), "CONTINUAR [ESC]", GameManager.toggle_pause)
	var settings: Button = _action(_pause_window, Rect2(101, 80, 248, 30), "CONFIGURAÇÕES")
	settings.pressed.connect(_open_subwindow.bind(_settings_window, settings))
	_action(_pause_window, Rect2(101, 120, 248, 30), "REINICIAR PARTIDA", GameManager.start_new_run)
	_action(_pause_window, Rect2(101, 160, 248, 30), "MENU PRINCIPAL", GameManager.reset_game)


func _build_end() -> void:
	_end_window = _window(222, "")
	_end_caption = _centered(_end_window, 8, 16, "", 11, Retro.MINT)
	Retro.divider(_end_window, Rect2(16, 27, WINDOW_WIDTH - 32, 1))
	_end_heading = _centered(_end_window, 35, 35, "", 24, Retro.MINT)
	_end_message = _centered(_end_window, 74, 40, "", 13, Retro.CREAM)
	var stats_box: Panel = Panel.new()
	stats_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_box.add_theme_stylebox_override(&"panel", Retro.style(Retro.INK, Retro.BEVEL_DARK, 1))
	Retro.place(stats_box, _end_window, Rect2(16, 124, 418, 28))
	_stats = _centered(_end_window, 124, 28, "", 12, Retro.GOLD)
	_action(_end_window, Rect2(16, 172, 236, 31), "JOGAR NOVAMENTE [ENTER]", GameManager.start_new_run)
	_action(_end_window, Rect2(262, 172, 172, 31), "MENU PRINCIPAL", GameManager.reset_game)


func _window(height: int, caption: String) -> Panel:
	var panel: Panel = Retro.window(self, Rect2(95, floori((360 - height) / 2.0), WINDOW_WIDTH, height), caption)
	panel.hide()
	_buttons[panel] = []
	return panel


func _centered(parent: Panel, y: int, height: int, content: String, font_size: int,
		color: Color) -> Label:
	return Retro.label(parent, Rect2(12, y, WINDOW_WIDTH - 24, height), content, font_size, color,
			HORIZONTAL_ALIGNMENT_CENTER)


func _action(parent: Panel, rect: Rect2, caption: String, callback: Callable = Callable()) -> Button:
	var button: Button = Retro.button(parent, rect, caption)
	button.focus_mode = Control.FOCUS_ALL
	var focus: StyleBoxFlat = Retro.style(Color.TRANSPARENT, Retro.MINT, 2)
	focus.draw_center = false
	button.add_theme_stylebox_override(&"focus", focus)
	_buttons[parent].append(button)
	button.mouse_entered.connect(_on_button_hovered.bind(button))
	button.pressed.connect(_on_button_cue.bind(button))
	if callback.is_valid():
		button.pressed.connect(callback)
	return button


func _on_button_hovered(button: Button) -> void:
	if not button.disabled and button.get_parent() == _active_window:
		button.grab_focus()


func _on_button_cue(button: Button) -> void:
	if button == _quit_button or button in _sfx_step_buttons:
		return
	AudioManager.play_ui_cue()


func _back_button(parent: Panel, y: int) -> void:
	_action(parent, Rect2(140, y, 170, 26), "VOLTAR [ESC]", _close_subwindow)


func _open_subwindow(window: Panel, opener: Button) -> void:
	_return_button = opener
	if window == _settings_window:
		_refresh_settings()
	_show_window(window)


func _close_subwindow() -> void:
	var opener: Button = _return_button
	_return_button = null
	_show_window(opener.get_parent() as Panel)
	opener.grab_focus()


func _show_window(window: Panel) -> void:
	_space_button = null
	if _active_window != null:
		_active_window.hide()
	_active_window = window
	if window == null:
		_title_art.hide()
		_backdrop.hide()
		hide()
		return
	_title_art.visible = (GameManager.current_state == GameManager.GameState.MENU)
	_backdrop.visible = (window != _title_window)
	window.show()
	show()
	_focus_active_window()


func _focus_active_window() -> void:
	if visible and _active_window != null:
		var first: Button = _buttons[_active_window][0]
		first.grab_focus()


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null:
		return
	var code: Key = key.keycode
	var state: GameManager.GameState = GameManager.current_state
	if state == GameManager.GameState.PLAYING:
		if code in [KEY_ESCAPE, KEY_P] and key.pressed and not key.echo:
			get_viewport().set_input_as_handled()
			GameManager.toggle_pause()
		return
	if not visible or _active_window == null:
		return

	match code:
		KEY_ESCAPE, KEY_P:
			if code == KEY_ESCAPE or _active_window == _pause_window:
				get_viewport().set_input_as_handled()
				if key.pressed and not key.echo:
					if _return_button != null:
						_close_subwindow()
					elif _active_window == _pause_window:
						GameManager.toggle_pause()
		KEY_W, KEY_S, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_TAB:
			get_viewport().set_input_as_handled()
			if key.pressed:
				var previous: bool = code in [KEY_W, KEY_UP, KEY_LEFT] or (code == KEY_TAB and key.shift_pressed)
				_move_focus(-1 if previous else 1)
		KEY_ENTER, KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			var focused: Button = get_viewport().gui_get_focus_owner() as Button
			if key.pressed and not key.echo and focused != null and not focused.disabled \
					and focused.get_parent() == _active_window:
				focused.pressed.emit()
		KEY_SPACE:
			get_viewport().set_input_as_handled()
			if key.echo:
				return
			var focused: Button = get_viewport().gui_get_focus_owner() as Button
			# Space also attacks, so only activate after a press and release in the menu.
			if key.pressed:
				_space_button = focused
			else:
				var pressed: Button = _space_button
				_space_button = null
				if pressed != null and pressed == focused and not pressed.disabled \
						and pressed.get_parent() == _active_window:
					pressed.pressed.emit()


func _move_focus(step: int) -> void:
	var actions: Array = _buttons[_active_window]
	var index: int = actions.find(get_viewport().gui_get_focus_owner())
	if index == -1:
		index = -1 if step > 0 else 0
	for _attempt: int in range(actions.size()):
		index = posmod(index + step, actions.size())
		var button: Button = actions[index]
		if not button.disabled:
			button.grab_focus()
			return


func _change_music_volume(step: int) -> void:
	AudioManager.set_music_volume((roundi(AudioManager.music_volume * 100.0) + step) / 100.0)
	_refresh_settings()
	_save_settings()


func _on_music_slider_changed(value: float) -> void:
	if _syncing_sliders:
		return
	AudioManager.set_music_volume(value / 100.0)
	_refresh_settings()
	_save_settings()


func _change_sfx_volume(step: int) -> void:
	var previous: float = AudioManager.sfx_volume
	AudioManager.set_sfx_volume((roundi(previous * 100.0) + step) / 100.0)
	if AudioManager.sfx_volume != previous:
		AudioManager.play_ui_cue()
	_refresh_settings()
	_save_settings()


func _on_sfx_slider_changed(value: float) -> void:
	if _syncing_sliders:
		return
	var previous: float = AudioManager.sfx_volume
	AudioManager.set_sfx_volume(value / 100.0)
	if not is_equal_approx(AudioManager.sfx_volume, previous):
		AudioManager.play_ui_cue()
	_refresh_settings()
	_save_settings()


func _toggle_mute() -> void:
	AudioManager.set_muted(not AudioManager.muted)
	_refresh_settings()
	_save_settings()


func _toggle_shake() -> void:
	GameManager.set_screen_shake_enabled(not GameManager.screen_shake_enabled)
	_refresh_settings()
	_save_settings()


func _toggle_fullscreen() -> void:
	if _fullscreen_button.disabled:
		return
	var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_WINDOWED if _is_fullscreen() \
			else DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(mode)
	_refresh_settings()
	_save_settings()


func _cycle_resolution() -> void:
	if _resolution_button.disabled:
		return
	var current: Vector2i = DisplayServer.window_get_size()
	var idx: int = RESOLUTIONS.find(current)
	var next_idx: int = (idx + 1) % RESOLUTIONS.size() if idx != -1 else 1
	_apply_window_size(RESOLUTIONS[next_idx])
	_refresh_resolution()
	_save_settings()


func _apply_window_size(target: Vector2i) -> void:
	if DisplayServer.get_name() == "headless" or OS.has_feature("web") or _is_fullscreen():
		return
	var screen: int = DisplayServer.window_get_current_screen()
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	DisplayServer.window_set_size(target)
	var offset: Vector2i = Vector2i(
		maxi(0, (usable.size.x - target.x) / 2),
		maxi(28, (usable.size.y - target.y) / 2)
	)
	DisplayServer.window_set_position(usable.position + offset)


func _reset_settings() -> void:
	AudioManager.set_music_volume(1.0)
	AudioManager.set_sfx_volume(1.0)
	AudioManager.set_muted(false)
	GameManager.set_screen_shake_enabled(true)
	if _is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_apply_window_size(Vector2i(1280, 720))
	_refresh_settings()
	_save_settings()


func _should_persist_settings() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	var node: Node = self
	while node != null:
		if node.name == &"ValidateT018":
			return false
		node = node.get_parent()
	return true


func _load_settings() -> void:
	if not _should_persist_settings():
		return
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	AudioManager.set_music_volume(float(cfg.get_value("audio", "music_volume", 1.0)))
	AudioManager.set_sfx_volume(float(cfg.get_value("audio", "sfx_volume", 1.0)))
	AudioManager.set_muted(bool(cfg.get_value("audio", "muted", false)))
	GameManager.set_screen_shake_enabled(bool(cfg.get_value("gameplay", "screen_shake", true)))
	var full: bool = bool(cfg.get_value("display", "fullscreen", false))
	if full and not _is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not full:
		var w: int = int(cfg.get_value("display", "window_width", 1280))
		var h: int = int(cfg.get_value("display", "window_height", 720))
		if w >= 640 and h >= 360:
			_apply_window_size(Vector2i(w, h))


func _save_settings() -> void:
	if not _should_persist_settings():
		return
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("audio", "music_volume", AudioManager.music_volume)
	cfg.set_value("audio", "sfx_volume", AudioManager.sfx_volume)
	cfg.set_value("audio", "muted", AudioManager.muted)
	cfg.set_value("gameplay", "screen_shake", GameManager.screen_shake_enabled)
	var full: bool = _is_fullscreen()
	cfg.set_value("display", "fullscreen", full)
	if not full:
		var win_size: Vector2i = DisplayServer.window_get_size()
		cfg.set_value("display", "window_width", win_size.x)
		cfg.set_value("display", "window_height", win_size.y)
	cfg.save(SETTINGS_PATH)


func _is_fullscreen() -> bool:
	return DisplayServer.get_name() != "headless" and DisplayServer.window_get_mode() in [
		DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
	]


func _refresh_fullscreen() -> void:
	_fullscreen_button.text = "TELA CHEIA" if _is_fullscreen() else "JANELA"
	_refresh_resolution()


func _refresh_resolution() -> void:
	if _resolution_button == null:
		return
	if DisplayServer.get_name() == "headless":
		_resolution_button.text = "HEADLESS"
		_resolution_button.disabled = true
	elif OS.has_feature("web"):
		_resolution_button.text = "AUTOMÁTICA"
		_resolution_button.disabled = true
	else:
		var win_size: Vector2i = DisplayServer.window_get_size()
		_resolution_button.text = "%dx%d" % [win_size.x, win_size.y]
		_resolution_button.disabled = _is_fullscreen()


func _refresh_settings() -> void:
	_syncing_sliders = true
	var music_pct: int = roundi(AudioManager.music_volume * 100.0)
	var sfx_pct: int = roundi(AudioManager.sfx_volume * 100.0)
	if _music_slider != null:
		_music_slider.value = float(music_pct)
	if _sfx_slider != null:
		_sfx_slider.value = float(sfx_pct)
	_syncing_sliders = false
	_music_value.text = "%d%%" % music_pct
	_sfx_value.text = "%d%%" % sfx_pct
	_mute_button.text = "MUDO" if AudioManager.muted else "ATIVO"
	_shake_button.text = "LIGADO" if GameManager.screen_shake_enabled else "DESLIGADO"
	_refresh_fullscreen()


func _on_state_changed(state: GameManager.GameState) -> void:
	_return_button = null
	match state:
		GameManager.GameState.MENU:
			_show_window(_title_window)
		GameManager.GameState.PAUSED:
			_show_window(_pause_window)
		GameManager.GameState.VICTORY, GameManager.GameState.GAME_OVER:
			_update_summary(state == GameManager.GameState.VICTORY)
			_show_window(_end_window)
		_:
			_show_window(null)


func _update_summary(won: bool) -> void:
	_end_caption.text = "VITÓRIA" if won else "FIM DE TURNO"
	_end_caption.add_theme_color_override(&"font_color", Retro.MINT if won else Retro.GOLD)
	_end_heading.text = "O AMANHECER CHEGOU" if won else "O BURNOUT PEDIU PAUSA"
	_end_heading.add_theme_color_override(&"font_color", Retro.MINT if won else Retro.GOLD)
	_end_message.text = ("O estudante atravessou a noite e viu o dia nascer.\nCuide dos seus pilares e aceite companhia."
			if won else "O estudante chegou ao limite.\nÉ hora de respirar, descansar e pedir apoio.")
	_stats.text = "Sala %d/3   •   HP %d/%d   •   Score %d   •   Combo x%d" % [
		GameManager.room, GameManager.hp, GameManager.max_hp, GameManager.score, maxi(1, GameManager.combo),
	]
