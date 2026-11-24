extends CanvasLayer

const Retro = preload("res://scenes/ui/retro_window.gd")
const CHOICES: Array[String] = ["sleep", "nutrition", "connection"]
const HEADINGS: Array[String] = [
	"Descansar & Remédio em Dia",
	"Alimentar & Hidratar",
	"Conexão / Rede de Apoio",
]
const BENEFITS: Array[String] = [
	"−20% ganho de BPM  /  +2,5 BPM/s de recuperação  /  volta a 70 BPM",
	"+15% velocidade  /  −0,2 s de respiração  /  +25 HP no Núcleo",
	"+1 aliado  /  pulso de 15 de dano  /  aura calma de −4 BPM/s",
]

var _choose_in_arena: Callable
var _window: Panel
var _caption: Label
var _support: Label
var _cards: Array[Button] = []


func _ready() -> void:
	Retro.block(self, Rect2(0, 0, 640, 360), Color("#231e2eae"))
	var window: Panel = Retro.window(self, Rect2(70, 56, 500, 248), "")
	_window = window
	_caption = Retro.label(window, Rect2(8, 3, 420, 16), "", 10)
	Retro.label(window, Rect2(16, 27, 468, 23), "Escolha um cuidado para o próximo turno", 16)
	for index: int in range(CHOICES.size()):
		var card: Button = Retro.button(window, Rect2(16, 61 + index * 59, 468, 50))
		card.pressed.connect(_choose.bind(index))
		Retro.block(card, Rect2(8, 10, 28, 29), Retro.INK)
		Retro.label(card, Rect2(8, 10, 28, 29), str(index + 1), 15, Retro.GOLD,
				HORIZONTAL_ALIGNMENT_CENTER)
		Retro.label(card, Rect2(46, 5, 414, 18), HEADINGS[index], 13)
		var detail: Label = Retro.label(card, Rect2(46, 24, 414, 18), BENEFITS[index],
				11, Retro.MUTED)
		_cards.append(card)
		if CHOICES[index] == "connection":
			_support = detail
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.habits_updated.connect(_on_habits_updated)
	_on_state_changed(GameManager.current_state)


func bind_arena(choose_in_arena: Callable) -> void:
	_choose_in_arena = choose_in_arena


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if not visible or key == null or not key.pressed or key.echo:
		return
	var index: int = int(key.keycode) - int(KEY_1)
	if key.keycode >= KEY_KP_1 and key.keycode <= KEY_KP_3:
		index = int(key.keycode) - int(KEY_KP_1)
	if index >= 0 and index < CHOICES.size():
		get_viewport().set_input_as_handled()
		_choose(index)


func _choose(index: int) -> void:
	if GameManager.current_state != GameManager.GameState.HABIT_SELECT or _cards[index].disabled:
		return
	var choice: String = CHOICES[index]
	if _choose_in_arena.is_valid():
		_choose_in_arena.call(choice)
	else:
		GameManager.apply_habit_choice(choice)
		GameManager.advance_wave()


func _on_state_changed(state: GameManager.GameState) -> void:
	visible = state == GameManager.GameState.HABIT_SELECT
	_window.visible = visible
	if visible:
		_caption.text = "CADERNO DE ROTINA — Fim do Turno %d" % GameManager.wave
		_on_habits_updated(GameManager.sleep_rank, GameManager.nutrition_rank, GameManager.ally_count)


func _on_habits_updated(_sleep: int, _nutrition: int, allies: int) -> void:
	var maxed: bool = allies >= GameManager.MAX_ALLIES
	_cards[2].disabled = maxed
	_support.text = "MÁXIMO %d/%d  —  escolha 1 ou 2" % [allies, GameManager.MAX_ALLIES] \
			if maxed else BENEFITS[2]
	_support.add_theme_color_override(&"font_color", Retro.GOLD if maxed else Retro.MUTED)
