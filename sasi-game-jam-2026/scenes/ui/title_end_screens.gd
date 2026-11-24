extends CanvasLayer

const Retro = preload("res://scenes/ui/retro_window.gd")

var _title_window: Panel
var _end_window: Panel
var _end_caption: Label
var _end_heading: Label
var _end_message: Label
var _stats: Label


func _ready() -> void:
	Retro.block(self, Rect2(0, 0, 640, 360), Color("#231e2ec4"))
	_build_title()
	_build_end()
	GameManager.state_changed.connect(_on_state_changed)
	_on_state_changed(GameManager.current_state)


func _build_title() -> void:
	_title_window = Retro.window(self, Rect2(95, 41, 450, 278), "O QUE MANTÉM DE PÉ.EXE")
	_centered(_title_window, 29, 35, "O QUE MANTÉM DE PÉ", 27, Retro.CREAM)
	_centered(_title_window, 64, 21, "Entre Fôlego e Rotina", 15, Retro.MINT)
	_centered(_title_window, 92, 38,
			"Ajude Seu Antônio a sustentar o Núcleo do Lar\ne cuidar da neta Clara ao longo de quatro turnos.",
			13, Retro.CREAM)

	var controls: Array[String] = ["WASD / Setas", "Espaço / Clique", "Shift", "Segurar R"]
	var actions: Array[String] = ["Mover", "Atacar", "Esquivar", "Respirar"]
	for index: int in range(controls.size()):
		var x: int = 16 + (index % 2) * 213
		var y: int = 141 + floori(index / 2.0) * 34
		Retro.block(_title_window, Rect2(x, y, 205, 28), Retro.INK)
		Retro.label(_title_window, Rect2(x + 8, y, 112, 28), controls[index], 12, Retro.GOLD)
		Retro.label(_title_window, Rect2(x + 120, y, 77, 28), actions[index], 12, Retro.CREAM,
				HORIZONTAL_ALIGNMENT_RIGHT)

	var play: Button = Retro.button(_title_window, Rect2(101, 220, 248, 31),
			"COMEÇAR  [ENTER / ESPAÇO]")
	play.pressed.connect(_start_run)


func _build_end() -> void:
	_end_window = Retro.window(self, Rect2(95, 71, 450, 218), "")
	_end_caption = Retro.label(_end_window, Rect2(8, 3, 384, 16), "", 10)
	_end_heading = _centered(_end_window, 31, 35, "", 24, Retro.MINT)
	_end_message = _centered(_end_window, 71, 40, "", 13, Retro.CREAM)
	Retro.block(_end_window, Rect2(16, 122, 418, 28), Retro.INK)
	_stats = _centered(_end_window, 122, 28, "", 12, Retro.GOLD)
	var restart: Button = Retro.button(_end_window, Rect2(101, 169, 248, 31),
			"JOGAR NOVAMENTE  [ENTER]")
	restart.pressed.connect(_start_run)


func _centered(parent: Panel, y: int, height: int, content: String, font_size: int,
		color: Color) -> Label:
	return Retro.label(parent, Rect2(12, y, 426, height), content, font_size, color,
			HORIZONTAL_ALIGNMENT_CENTER)


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if not visible or key == null or key.echo:
		return
	var confirm: bool = key.pressed and key.keycode in [KEY_ENTER, KEY_KP_ENTER]
	# Space also attacks in the arena, so start after it is released.
	var menu_space: bool = _title_window.visible and key.keycode == KEY_SPACE
	if confirm or menu_space:
		get_viewport().set_input_as_handled()
		if confirm or not key.pressed:
			_start_run()


func _start_run() -> void:
	if visible:
		GameManager.start_new_run()


func _on_state_changed(state: GameManager.GameState) -> void:
	var menu: bool = state == GameManager.GameState.MENU
	var won: bool = state == GameManager.GameState.VICTORY
	var ended: bool = won or state == GameManager.GameState.GAME_OVER
	visible = menu or ended
	_title_window.visible = menu
	_end_window.visible = ended
	if ended:
		_end_caption.text = "CADERNO DE ROTINA.EXE — Resumo do dia"
		_end_heading.text = "O LAR SEGUE DE PÉ" if won else "A SOBRECARGA PEDIU PAUSA"
		_end_heading.add_theme_color_override(&"font_color", Retro.MINT if won else Retro.GOLD)
		_end_message.text = ("Seu Antônio e Clara atravessaram o dia.\nRespirar e aceitar ajuda também é cuidar."
				if won else "Seu Antônio chegou ao limite.\nAmanhã, há tempo para respirar e pedir ajuda.")
		_stats.text = "Onda %d/%d    •    Núcleo %d/%d HP    •    Rede de Apoio %d/%d" % [
			GameManager.wave, GameManager.MAX_WAVES, GameManager.core_hp, GameManager.max_core_hp,
			GameManager.ally_count, GameManager.MAX_ALLIES,
		]
