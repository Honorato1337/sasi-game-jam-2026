extends CanvasLayer

const Retro = preload("res://scenes/ui/retro_window.gd")
const ANTONIO_SHEET: Texture2D = preload("res://assets/sprites/seu_antonio_sheet.png")
const CORE_SHEET: Texture2D = preload("res://assets/sprites/care_core_sheet.png")
const WINDOW_WIDTH: int = 450

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
var _music_value: Label
var _sfx_value: Label
var _mute_button: Button
var _shake_button: Button
var _fullscreen_button: Button
var _end_caption: Label
var _end_heading: Label
var _end_message: Label
var _stats: Label


func _ready() -> void:
	var backdrop: ColorRect = Retro.block(self, Rect2(0, 0, 640, 360), Color("#231e2ec4"))
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_build_help()
	_build_settings()
	_build_credits()
	_build_title()
	_build_pause()
	_build_end()
	get_viewport().size_changed.connect(_refresh_fullscreen)
	GameManager.state_changed.connect(_on_state_changed)
	_on_state_changed(GameManager.current_state)


func _build_title() -> void:
	_title_window = _window(298, "O QUE MANTÉM DE PÉ.EXE")
	_centered(_title_window, 26, 35, "O QUE MANTÉM DE PÉ", 27, Retro.CREAM)
	_centered(_title_window, 62, 21, "Entre Fôlego e Rotina", 15, Retro.MINT)
	_preview(_title_window, 21, ANTONIO_SHEET, 2, "Seu Antônio")
	_preview(_title_window, 333, CORE_SHEET, 1, "Núcleo do Lar")

	_action(_title_window, Rect2(123, 93, 204, 27), "JOGAR", GameManager.start_new_run)
	var help: Button = _action(_title_window, Rect2(123, 126, 204, 27), "COMO JOGAR")
	help.pressed.connect(_open_subwindow.bind(_help_window, help))
	var settings: Button = _action(_title_window, Rect2(123, 159, 204, 27), "CONFIGURAÇÕES")
	settings.pressed.connect(_open_subwindow.bind(_settings_window, settings))
	var credits: Button = _action(_title_window, Rect2(123, 192, 204, 27), "CRÉDITOS & SAÚDE")
	credits.pressed.connect(_open_subwindow.bind(_credits_window, credits))
	if not OS.has_feature("web"):
		_action(_title_window, Rect2(123, 225, 204, 27), "SAIR", get_tree().quit)
	_centered(_title_window, 263, 19, "W/S ou ↑/↓ para navegar   •   Enter para confirmar", 11, Retro.MUTED)


func _preview(parent: Panel, x: int, sheet: Texture2D, scale_factor: int, caption: String) -> void:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(0, 0, sheet.get_width() / 4.0, sheet.get_height())
	atlas.filter_clip = true
	Retro.block(parent, Rect2(x + 14, 115, 68, 68), Retro.INK)
	var preview: TextureRect = TextureRect.new()
	preview.texture = atlas
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_size: Vector2 = atlas.region.size * scale_factor
	var center: Vector2 = Vector2(x + 48, 149)
	Retro.place(preview, parent, Rect2(center - frame_size / 2, frame_size))
	Retro.label(parent, Rect2(x, 188, 96, 20), caption, 11, Retro.MUTED,
			HORIZONTAL_ALIGNMENT_CENTER)


func _build_help() -> void:
	_help_window = _window(294, "COMO JOGAR.EXE")
	var controls: Array[String] = ["WASD / Setas", "Espaço / Clique", "Shift", "Segurar R", "Esc / P"]
	var actions: Array[String] = ["Mover", "Atacar", "Esquivar", "Respirar", "Pausar"]
	for index: int in range(controls.size()):
		var x: int = 16 + (index % 2) * 213
		var y: int = 29 + floori(index / 2.0) * 28
		Retro.block(_help_window, Rect2(x, y, 205, 24), Retro.INK)
		Retro.label(_help_window, Rect2(x + 8, y, 113, 24), controls[index], 12, Retro.GOLD)
		Retro.label(_help_window, Rect2(x + 121, y, 76, 24), actions[index], 12, Retro.CREAM,
				HORIZONTAL_ALIGNMENT_RIGHT)

	var topics: Array[String] = ["SINAIS", "EQUILÍBRIO", "CONEXÕES"]
	var explanations: Array[String] = [
		"Observe o BPM. Atacar e esquivar aceleram o coração.\nEm sobrecarga, a visão se fecha e o ritmo muda.",
		"Segure R para baixar o BPM. Complete a respiração\npara transformar o próximo ataque no Golpe de Clareza.",
		"Escolha Rede de Apoio entre ondas. Os aliados\nprotegem o Núcleo e ajudam a baixar o BPM por perto.",
	]
	for index: int in range(topics.size()):
		var y: int = 118 + index * 43
		Retro.block(_help_window, Rect2(16, y, 418, 38), Retro.INK)
		Retro.label(_help_window, Rect2(24, y, 88, 38), topics[index], 11, Retro.MINT)
		Retro.label(_help_window, Rect2(116, y, 310, 38), explanations[index], 11)
	_back_button(_help_window, 256)


func _build_settings() -> void:
	_settings_window = _window(246, "CONFIGURAÇÕES.EXE")
	_music_value = _volume_row(31, "Música", _change_music_volume)
	_sfx_value = _volume_row(65, "Efeitos (SFX)", _change_sfx_volume)
	_mute_button = _toggle_row(99, "Áudio Geral", _toggle_mute)
	_shake_button = _toggle_row(133, "Tremor de Tela", _toggle_shake)
	_fullscreen_button = _toggle_row(167, "Tela Cheia", _toggle_fullscreen)
	_fullscreen_button.disabled = DisplayServer.get_name() == "headless"
	_back_button(_settings_window, 208)
	_refresh_settings()


func _volume_row(y: int, caption: String, change: Callable) -> Label:
	_setting_label(y, caption)
	_action(_settings_window, Rect2(220, y, 44, 28), "[-]", change.bind(-10))
	_action(_settings_window, Rect2(378, y, 44, 28), "[+]", change.bind(10))
	return Retro.label(_settings_window, Rect2(264, y, 114, 28), "", 13, Retro.GOLD,
			HORIZONTAL_ALIGNMENT_CENTER)


func _toggle_row(y: int, caption: String, action: Callable) -> Button:
	_setting_label(y, caption)
	return _action(_settings_window, Rect2(220, y, 202, 28), "", action)


func _setting_label(y: int, caption: String) -> void:
	Retro.block(_settings_window, Rect2(16, y, 418, 28), Retro.INK)
	Retro.label(_settings_window, Rect2(27, y, 182, 28), caption, 13)


func _build_credits() -> void:
	_credits_window = _window(223, "CRÉDITOS.EXE")
	_centered(_credits_window, 28, 24, "SASI: GAME JAM 2026  •  UFAC", 16, Retro.MINT)
	_centered(_credits_window, 56, 38,
			"Arte pixel e áudio chiptune criados para o jogo.\nDesenvolvimento com apoio de Antigravity e OpenAI Codex.",
			12, Retro.CREAM)
	Retro.block(_credits_window, Rect2(16, 105, 418, 70), Retro.INK)
	_centered(_credits_window, 109, 20, "SAÚDE EM JOGO", 12, Retro.GOLD)
	_centered(_credits_window, 132, 36,
			"Cuidar também passa por perceber os sinais do corpo,\nrespeitar seus limites e dividir a rotina com quem pode ajudar.",
			12, Retro.CREAM)
	_back_button(_credits_window, 185)


func _build_pause() -> void:
	_pause_window = _window(200, "PAUSA.EXE")
	_action(_pause_window, Rect2(101, 32, 248, 30), "CONTINUAR [ESC]", GameManager.toggle_pause)
	var settings: Button = _action(_pause_window, Rect2(101, 74, 248, 30), "CONFIGURAÇÕES")
	settings.pressed.connect(_open_subwindow.bind(_settings_window, settings))
	_action(_pause_window, Rect2(101, 116, 248, 30), "REINICIAR PARTIDA", GameManager.start_new_run)
	_action(_pause_window, Rect2(101, 158, 248, 30), "MENU PRINCIPAL", GameManager.reset_game)


func _build_end() -> void:
	_end_window = _window(218, "")
	_end_caption = Retro.label(_end_window, Rect2(8, 3, 384, 16), "", 10)
	_end_heading = _centered(_end_window, 31, 35, "", 24, Retro.MINT)
	_end_message = _centered(_end_window, 71, 40, "", 13, Retro.CREAM)
	Retro.block(_end_window, Rect2(16, 122, 418, 28), Retro.INK)
	_stats = _centered(_end_window, 122, 28, "", 12, Retro.GOLD)
	_action(_end_window, Rect2(16, 169, 236, 31), "JOGAR NOVAMENTE [ENTER]", GameManager.start_new_run)
	_action(_end_window, Rect2(262, 169, 172, 31), "MENU PRINCIPAL", GameManager.reset_game)


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
	if callback.is_valid():
		button.pressed.connect(callback)
	return button


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
		hide()
		return
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


func _change_sfx_volume(step: int) -> void:
	var previous: float = AudioManager.sfx_volume
	AudioManager.set_sfx_volume((roundi(previous * 100.0) + step) / 100.0)
	if AudioManager.sfx_volume != previous:
		AudioManager.play_ui_cue()
	_refresh_settings()


func _toggle_mute() -> void:
	AudioManager.set_muted(not AudioManager.muted)
	_refresh_settings()


func _toggle_shake() -> void:
	GameManager.set_screen_shake_enabled(not GameManager.screen_shake_enabled)
	_refresh_settings()


func _toggle_fullscreen() -> void:
	if _fullscreen_button.disabled:
		return
	var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_WINDOWED if _is_fullscreen() \
			else DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(mode)
	_refresh_fullscreen()


func _is_fullscreen() -> bool:
	return DisplayServer.get_name() != "headless" and DisplayServer.window_get_mode() in [
		DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
	]


func _refresh_fullscreen() -> void:
	_fullscreen_button.text = "TELA CHEIA" if _is_fullscreen() else "JANELA"


func _refresh_settings() -> void:
	_music_value.text = "%d%%" % roundi(AudioManager.music_volume * 100.0)
	_sfx_value.text = "%d%%" % roundi(AudioManager.sfx_volume * 100.0)
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
	_end_caption.text = "CADERNO DE ROTINA.EXE — Resumo do dia"
	_end_heading.text = "O LAR SEGUE DE PÉ" if won else "A SOBRECARGA PEDIU PAUSA"
	_end_heading.add_theme_color_override(&"font_color", Retro.MINT if won else Retro.GOLD)
	_end_message.text = ("Seu Antônio e Clara atravessaram o dia.\nRespirar e aceitar ajuda também é cuidar."
			if won else "Seu Antônio chegou ao limite.\nAmanhã, há tempo para respirar e pedir ajuda.")
	_stats.text = "Onda %d/%d    •    Núcleo %d/%d HP    •    Rede de Apoio %d/%d" % [
		GameManager.wave, GameManager.MAX_WAVES, GameManager.core_hp, GameManager.max_core_hp,
		GameManager.ally_count, GameManager.MAX_ALLIES,
	]
