extends CanvasLayer

const Retro = preload("res://scenes/ui/retro_window.gd")
const STUDENT_SHEET: Texture2D = preload("res://assets/sprites/student_sheet.png")
const CLASSMATE_SHEET: Texture2D = preload("res://assets/sprites/classmate_sheet.png")
const ROOM_MORNING_TEX: Texture2D = preload("res://assets/sprites/room_morning.png")

enum Phase { NONE, MONTAGE, INTRO_POEM, CONSOLE_ENTRY, ENDING_POEM }

const CYCLE_TITLES: Array[String] = [
	"SEMANA 1  •  ROTINA",
	"SEMANA 2  •  SOBRECARGA",
	"SEMANA 3  •  EXAUSTÃO",
]
const CYCLE_COLORS: Array[Color] = [Retro.MINT, Retro.GOLD, Color("#ff7b8d")]
const CYCLE_PITCHES: Array[float] = [1.00, 1.14, 1.30]
const CYCLE_BEAT_STEP: Array[float] = [1.28, 1.28, 0.64]
const SCENE_NAMES: Array[String] = [
	"ACORDAR", "BUSÃO LOTADO", "SALA DE AULA", "ALMOÇO NO RU", "BUSÃO DE VOLTA", "DORMIR TARDE",
]
const SCENE_TIMES: Array[Array] = [
	["06:00", "06:40", "08:00", "12:30", "18:30", "23:30"],
	["05:45", "06:35", "08:00", "12:45", "19:50", "01:15"],
	["05:30", "06:30", "08:00", "13:05", "21:20", "02:40"],
]
const FATIGUE_LABELS: Array[String] = ["RITMO FIRME", "OLHOS PESADOS", "NO LIMITE..."]
const FATIGUE_LEVELS: Array[float] = [0.76, 0.42, 0.14]
const MONTAGE_CAPTIONS: Array[Array] = [
	[
		"Mais um dia começa cedo. É só manter o ritmo.",
		"Ônibus cheio de novo, mas logo chego na faculdade.",
		"Aula, anotações e os primeiros prazos da semana.",
		"Almoço rápido no RU entre uma matéria e outra.",
		"Busão lotado na volta. O céu já está escuro.",
		"Tarde da noite. Amanhã começa tudo de novo.",
	],
	[
		"O despertador toca antes de o corpo conseguir descansar.",
		"Em pé no busão apertado, segurando a mochila pesada.",
		"A matéria acumula no quadro. Os olhos já começam a arder.",
		"Almoço apressado, a cabeça presa na lista de entregas.",
		"Mais um dia escorrido pelo vidro embaçado do ônibus.",
		"Mais de uma da manhã... e a mente não desliga.",
	],
	[
		"De novo o alarme...",
		"Sem espaço nem para respirar.",
		"Tudo embaça no quadro...",
		"Sem apetite. Só cansaço.",
		"Noite fechada. Só quero chegar em casa.",
		"Madrugada... exausto demais até para dormir.",
	],
]
const CANSACO_LINES: Array[String] = [
	"O que há em mim é sobretudo cansaço —",
	"Não disto nem daquilo,",
	"Nem sequer de tudo ou de nada:",
	"Cansaço assim mesmo, ele mesmo,",
	"Cansaço.",
	"",
	"A subtileza das sensações inúteis,",
	"As paixões violentas por coisa nenhuma,",
	"Os amores intensos por o suposto em alguém,",
	"Essas coisas todas —",
	"Essas e o que falta nelas eternamente —;",
	"Tudo isso faz um cansaço,",
	"Este cansaço,",
	"Cansaço.",
]
const CONSOLE_CAPTIONS: Array[String] = [
	"Preciso desligar a cabeça... talvez jogar um pouco ajude a descansar.",
	"O videogame liga. A luz da tela preenche o quarto escuro...",
	"E quando percebo... eu entrei dentro do jogo.",
]
const HOPE_LINES: Array[String] = [
	"\"A esperança\" é a coisa com penas —",
	"Que pousa na alma em silêncio —",
	"E canta a melodia sem palavras —",
	"E jamais se cala — por completo —",
	"",
	"E mais doce — no vendaval — se escuta —",
	"E cruel há de ser a tempestade —",
	"Para abater o pequeno pássaro",
	"Que a tantos manteve aquecidos —",
	"",
	"Eu a ouvi na terra mais gelada —",
	"E sobre o mar mais estranho —",
	"Contudo — nunca — no extremo,",
	"Pediu de mim — uma migalha —",
]

var _phase: Phase = Phase.NONE
var _on_finished: Callable
var _finishing: bool = false
var _elapsed: float = 0.0
var _beat_elapsed: float = 0.0
var _cycle: int = 0
var _scene_idx: int = 0
var _console_step: int = 0
var _console_elapsed: float = 0.0
var _pause_before_poem: bool = false
var _pause_elapsed: float = 0.0
var _poem_reveal_count: int = 0
var _poem_elapsed: float = 0.0

var _backdrop: ColorRect
var _montage_root: Control
var _montage_cycle_lbl: Label
var _montage_scene_lbl: Label
var _montage_caption: Label
var _montage_fatigue_lbl: Label
var _montage_bar_fill: ColorRect
var _montage_stage: Node2D
var _portrait_stage: Node2D

var _intro_poem_root: Control
var _intro_poem_labels: Array[Label] = []
var _intro_poem_author: Label
var _intro_poem_prompt: Label

var _console_root: Control
var _console_stage: Node2D
var _console_caption: Label

var _ending_poem_root: Control
var _ending_stage: Node2D
var _ending_poem_labels: Array[Label] = []
var _ending_poem_author: Label
var _ending_poem_prompt: Label

var _dawn_bg: ImageTexture
var _feather_seeds: Array[Vector3] = []


func _ready() -> void:
	for index: int in range(14):
		_feather_seeds.append(Vector3(
			fmod(float(index) * 23.7 + 14.0, 310.0),
			fmod(float(index) * 19.3 + 12.0, 170.0),
			float(index) * 0.85
		))
	_dawn_bg = _build_dawn_texture()

	_backdrop = Retro.block(self, Rect2(0, 0, 640, 360), Color("#050408"))
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP

	_build_montage_ui()
	_build_intro_poem_ui()
	_build_console_ui()
	_build_ending_poem_ui()
	GameManager.state_changed.connect(_on_state_changed)
	hide()


func _build_montage_ui() -> void:
	_montage_root = Control.new()
	_montage_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Retro.place(_montage_root, self, Rect2(0, 0, 640, 360))
	_montage_root.hide()

	_montage_cycle_lbl = Retro.label(_montage_root, Rect2(34, 14, 210, 18), "", 12, Retro.MINT)
	_montage_cycle_lbl.add_theme_font_override(&"font", Retro.FONT_BOLD)
	_montage_scene_lbl = Retro.label(_montage_root, Rect2(246, 14, 360, 18), "", 12, Retro.GOLD,
			HORIZONTAL_ALIGNMENT_RIGHT)
	_montage_scene_lbl.add_theme_font_override(&"font", Retro.FONT_BOLD)

	Retro.panel(_montage_root, Rect2(32, 38, 428, 218), false, false)
	var stage_clip: Control = Control.new()
	stage_clip.clip_contents = true
	stage_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Retro.place(stage_clip, _montage_root, Rect2(38, 44, 416, 206))
	_montage_stage = Node2D.new()
	_montage_stage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_montage_stage.scale = Vector2(2, 2)
	_montage_stage.draw.connect(_draw_montage_scene)
	stage_clip.add_child(_montage_stage)

	Retro.panel(_montage_root, Rect2(468, 38, 140, 218), false, false)
	Retro.label(_montage_root, Rect2(476, 46, 124, 14), "ESTUDANTE", 11, Retro.GOLD,
			HORIZONTAL_ALIGNMENT_CENTER).add_theme_font_override(&"font", Retro.FONT_BOLD)
	var card: Panel = Panel.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card.add_theme_stylebox_override(&"panel", Retro.pixel_card_box(Color("#120d1c"), Retro.BEVEL_DARK))
	Retro.place(card, _montage_root, Rect2(484, 66, 108, 108))

	_portrait_stage = Node2D.new()
	_portrait_stage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait_stage.position = Vector2(484, 66)
	_portrait_stage.scale = Vector2(3, 3)
	_portrait_stage.draw.connect(_draw_portrait_face)
	_montage_root.add_child(_portrait_stage)

	_montage_fatigue_lbl = Retro.label(_montage_root, Rect2(476, 184, 124, 16), "", 11, Retro.MINT,
			HORIZONTAL_ALIGNMENT_CENTER)
	Retro.block(_montage_root, Rect2(484, 206, 108, 10), Retro.INK)
	_montage_bar_fill = Retro.block(_montage_root, Rect2(486, 208, 104, 6), Retro.MINT)
	Retro.label(_montage_root, Rect2(476, 224, 124, 16), "Cansaço acumulado", 10, Retro.MUTED,
			HORIZONTAL_ALIGNMENT_CENTER)

	var caption_box: Panel = Retro.panel(_montage_root, Rect2(32, 266, 576, 80), false, false)
	_montage_caption = Retro.label(caption_box, Rect2(14, 10, 548, 40), "", 13, Retro.CREAM)
	_montage_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_montage_caption.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	Retro.label(caption_box, Rect2(14, 56, 548, 16),
			"[ESPAÇO / CLIQUE] Avançar    •    [ESC] Pular", 10, Retro.MUTED)


func _build_intro_poem_ui() -> void:
	_intro_poem_root = Control.new()
	_intro_poem_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Retro.place(_intro_poem_root, self, Rect2(0, 0, 640, 360))
	_intro_poem_root.hide()

	var title: Label = Retro.label(_intro_poem_root, Rect2(60, 16, 520, 20), "CANSAÇO", 14,
			Retro.GOLD, HORIZONTAL_ALIGNMENT_CENTER, false)
	title.add_theme_font_override(&"font", Retro.FONT_BOLD)
	Retro.block(_intro_poem_root, Rect2(260, 38, 120, 1), Color("#3b324a"))

	_intro_poem_labels.clear()
	var cursor_y: int = 48
	for line: String in CANSACO_LINES:
		if line.is_empty():
			cursor_y += 10
			continue
		var lbl: Label = Retro.label(_intro_poem_root, Rect2(48, cursor_y, 544, 17), line, 12,
				Retro.CREAM, HORIZONTAL_ALIGNMENT_CENTER, false)
		lbl.modulate.a = 0.0
		_intro_poem_labels.append(lbl)
		cursor_y += 17

	_intro_poem_author = Retro.label(_intro_poem_root, Rect2(48, 294, 544, 18),
			"— Álvaro de Campos (Fernando Pessoa, 1934)", 11, Retro.BEVEL_LIGHT,
			HORIZONTAL_ALIGNMENT_CENTER, false)
	_intro_poem_author.modulate.a = 0.0
	_intro_poem_prompt = Retro.label(_intro_poem_root, Rect2(48, 328, 544, 18),
			"[ESPAÇO / CLIQUE] Continuar    •    [ESC] Pular", 10, Color("#8f88a6"),
			HORIZONTAL_ALIGNMENT_CENTER, false)


func _build_console_ui() -> void:
	_console_root = Control.new()
	_console_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Retro.place(_console_root, self, Rect2(0, 0, 640, 360))
	_console_root.hide()

	Retro.panel(_console_root, Rect2(32, 22, 576, 244), false, false)
	var clip: Control = Control.new()
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Retro.place(clip, _console_root, Rect2(38, 28, 564, 232))
	_console_stage = Node2D.new()
	_console_stage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_console_stage.scale = Vector2(2, 2)
	_console_stage.draw.connect(_draw_console_scene)
	clip.add_child(_console_stage)

	var box: Panel = Retro.panel(_console_root, Rect2(32, 274, 576, 72), false, false)
	_console_caption = Retro.label(box, Rect2(14, 10, 548, 36), "", 13, Retro.CREAM)
	_console_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_console_caption.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	Retro.label(box, Rect2(14, 50, 548, 16),
			"[ESPAÇO / CLIQUE] Continuar    •    [ESC] Pular", 10, Retro.MUTED)


func _build_ending_poem_ui() -> void:
	_ending_poem_root = Control.new()
	_ending_poem_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Retro.place(_ending_poem_root, self, Rect2(0, 0, 640, 360))
	_ending_poem_root.hide()

	_ending_stage = Node2D.new()
	_ending_stage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ending_stage.scale = Vector2(2, 2)
	_ending_stage.draw.connect(_draw_ending_scene)
	_ending_poem_root.add_child(_ending_stage)

	Retro.panel(_ending_poem_root, Rect2(36, 16, 424, 328), true, true)
	var title: Label = Retro.label(_ending_poem_root, Rect2(48, 26, 400, 18),
			"A ESPERANÇA É A COISA COM PENAS", 13, Retro.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override(&"font", Retro.FONT_BOLD)
	Retro.divider(_ending_poem_root, Rect2(64, 46, 368, 1))

	_ending_poem_labels.clear()
	var cursor_y: int = 54
	for line: String in HOPE_LINES:
		if line.is_empty():
			cursor_y += 10
			continue
		var lbl: Label = Retro.label(_ending_poem_root, Rect2(48, cursor_y, 400, 17), line, 12,
				Retro.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		lbl.modulate.a = 0.0
		_ending_poem_labels.append(lbl)
		cursor_y += 16

	_ending_poem_author = Retro.label(_ending_poem_root, Rect2(48, 278, 400, 18),
			"— Emily Dickinson (tradução livre)", 11, Retro.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_ending_poem_author.modulate.a = 0.0
	_ending_poem_prompt = Retro.label(_ending_poem_root, Rect2(48, 314, 400, 16),
			"[ESPAÇO / CLIQUE] Continuar    •    [ESC] Pular", 10, Retro.MUTED,
			HORIZONTAL_ALIGNMENT_CENTER)


func play_intro(on_finished: Callable = Callable()) -> void:
	_finishing = false
	_on_finished = on_finished
	_elapsed = 0.0
	show()
	GameManager.set_state(GameManager.GameState.CUTSCENE)
	_enter_phase(Phase.MONTAGE)


func play_ending_poem(on_finished: Callable = Callable()) -> void:
	_finishing = false
	_on_finished = on_finished
	_elapsed = 0.0
	show()
	GameManager.set_state(GameManager.GameState.CUTSCENE)
	_enter_phase(Phase.ENDING_POEM)


func get_phase_name() -> String:
	match _phase:
		Phase.MONTAGE: return "MONTAGE"
		Phase.INTRO_POEM: return "INTRO_POEM"
		Phase.CONSOLE_ENTRY: return "CONSOLE_ENTRY"
		Phase.ENDING_POEM: return "ENDING_POEM"
		_: return "NONE"


func _enter_phase(next_phase: Phase) -> void:
	_phase = next_phase
	_montage_root.visible = (next_phase == Phase.MONTAGE)
	_intro_poem_root.visible = (next_phase == Phase.INTRO_POEM)
	_console_root.visible = (next_phase == Phase.CONSOLE_ENTRY)
	_ending_poem_root.visible = (next_phase == Phase.ENDING_POEM)
	match next_phase:
		Phase.MONTAGE:
			_cycle = 0
			_scene_idx = 0
			_beat_elapsed = 0.0
			_pause_before_poem = false
			_pause_elapsed = 0.0
			AudioManager.play_track(&"beethoven", -9.0, CYCLE_PITCHES[0])
			AudioManager.play_alarm_beep()
			_refresh_montage_labels()
		Phase.INTRO_POEM:
			AudioManager.stop_music()
			_poem_elapsed = 0.0
			_poem_reveal_count = 0
			for lbl: Label in _intro_poem_labels:
				lbl.modulate.a = 0.0
			_intro_poem_author.modulate.a = 0.0
		Phase.CONSOLE_ENTRY:
			AudioManager.stop_music()
			_console_step = 0
			_console_elapsed = 0.0
			_console_caption.text = CONSOLE_CAPTIONS[0]
		Phase.ENDING_POEM:
			AudioManager.play_track(&"hope", -8.0, 1.0)
			_poem_elapsed = 0.0
			_poem_reveal_count = 0
			for lbl: Label in _ending_poem_labels:
				lbl.modulate.a = 0.0
			_ending_poem_author.modulate.a = 0.0


func _refresh_montage_labels() -> void:
	_montage_cycle_lbl.text = CYCLE_TITLES[_cycle]
	_montage_cycle_lbl.add_theme_color_override(&"font_color", CYCLE_COLORS[_cycle])
	var time_str: String = (SCENE_TIMES[_cycle] as Array)[_scene_idx]
	_montage_scene_lbl.text = "%s  •  %s" % [time_str, SCENE_NAMES[_scene_idx]]
	_montage_caption.text = (MONTAGE_CAPTIONS[_cycle] as Array)[_scene_idx]
	_montage_fatigue_lbl.text = FATIGUE_LABELS[_cycle]
	_montage_fatigue_lbl.add_theme_color_override(&"font_color", CYCLE_COLORS[_cycle])
	var level: float = FATIGUE_LEVELS[_cycle]
	var fill_w: float = maxf(6.0, roundf(104.0 * level))
	_montage_bar_fill.size = Vector2(fill_w, 6.0)
	_montage_bar_fill.set_deferred(&"size", Vector2(fill_w, 6.0))
	_montage_bar_fill.color = CYCLE_COLORS[_cycle]


func _process(delta: float) -> void:
	if _phase == Phase.NONE or _finishing or GameManager.current_state != GameManager.GameState.CUTSCENE:
		return
	_elapsed += delta
	match _phase:
		Phase.MONTAGE:
			_tick_montage(delta)
			_montage_stage.queue_redraw()
			_portrait_stage.queue_redraw()
		Phase.INTRO_POEM:
			_tick_poem(delta, _intro_poem_labels, _intro_poem_author)
		Phase.CONSOLE_ENTRY:
			_tick_console(delta)
			_console_stage.queue_redraw()
		Phase.ENDING_POEM:
			_tick_poem(delta, _ending_poem_labels, _ending_poem_author)
			_ending_stage.queue_redraw()


func _tick_montage(delta: float) -> void:
	if _pause_before_poem:
		_pause_elapsed += delta
		if _pause_elapsed >= 0.45:
			_enter_phase(Phase.INTRO_POEM)
		return
	var pitch: float = CYCLE_PITCHES[_cycle]
	_beat_elapsed += delta * pitch
	var step_len: float = CYCLE_BEAT_STEP[_cycle]
	if _beat_elapsed >= step_len:
		_beat_elapsed -= step_len
		_scene_idx += 1
		if _scene_idx >= 6:
			_scene_idx = 0
			_cycle += 1
			if _cycle >= 3:
				_cycle = 2
				_scene_idx = 5
				_pause_before_poem = true
				_pause_elapsed = 0.0
				AudioManager.stop_music()
				return
			AudioManager.set_music_pitch(CYCLE_PITCHES[_cycle])
			AudioManager.play_alarm_beep()
		_refresh_montage_labels()


func _tick_poem(delta: float, labels: Array[Label], author: Label) -> void:
	_poem_elapsed += delta
	var target: int = mini(labels.size() + 1, int(_poem_elapsed / 0.34) + 1)
	_poem_reveal_count = maxi(_poem_reveal_count, target)
	for index: int in range(labels.size()):
		var desired: float = 1.0 if index < _poem_reveal_count else 0.0
		labels[index].modulate.a = move_toward(labels[index].modulate.a, desired, delta * 3.8)
	var author_target: float = 1.0 if _poem_reveal_count > labels.size() else 0.0
	author.modulate.a = move_toward(author.modulate.a, author_target, delta * 3.2)


func _tick_console(delta: float) -> void:
	_console_elapsed += delta
	var limit: float = 2.6 if _console_step < 2 else 2.4
	if _console_elapsed >= limit:
		_advance_console()


func _advance_console() -> void:
	_console_step += 1
	_console_elapsed = 0.0
	if _console_step >= 3:
		_finish()
		return
	_console_caption.text = CONSOLE_CAPTIONS[_console_step]
	if _console_step == 1:
		AudioManager.play_console_boot()


func _input(event: InputEvent) -> void:
	if _phase == Phase.NONE or _finishing or GameManager.current_state != GameManager.GameState.CUTSCENE:
		return
	var key: InputEventKey = event as InputEventKey
	var click: InputEventMouseButton = event as InputEventMouseButton
	if key != null and key.keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		if key.pressed and not key.echo:
			if key.keycode == KEY_ESCAPE:
				_finish()
			else:
				_advance()
	elif click != null and click.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if click.pressed:
			_advance()


func _advance() -> void:
	match _phase:
		Phase.MONTAGE:
			_enter_phase(Phase.INTRO_POEM)
		Phase.INTRO_POEM:
			if _poem_reveal_count <= _intro_poem_labels.size():
				_poem_reveal_count = _intro_poem_labels.size() + 1
				for lbl: Label in _intro_poem_labels:
					lbl.modulate.a = 1.0
				_intro_poem_author.modulate.a = 1.0
			else:
				_enter_phase(Phase.CONSOLE_ENTRY)
		Phase.CONSOLE_ENTRY:
			_advance_console()
		Phase.ENDING_POEM:
			if _poem_reveal_count <= _ending_poem_labels.size():
				_poem_reveal_count = _ending_poem_labels.size() + 1
				for lbl: Label in _ending_poem_labels:
					lbl.modulate.a = 1.0
				_ending_poem_author.modulate.a = 1.0
			else:
				_finish()


func _finish() -> void:
	if _finishing or _phase == Phase.NONE:
		return
	_finishing = true
	var callback: Callable = _on_finished
	await get_tree().create_timer(0.0, true, true).timeout
	if not _finishing:
		return
	_phase = Phase.NONE
	_finishing = false
	_on_finished = Callable()
	hide()
	if callback.is_valid():
		callback.call()


func _on_state_changed(state: GameManager.GameState) -> void:
	if state != GameManager.GameState.CUTSCENE:
		_phase = Phase.NONE
		_finishing = false
		_on_finished = Callable()
		hide()


# --- Desenho procedural em pixel art (escala 2x exata em palco 208x103) ---

func _draw_montage_scene() -> void:
	const W: float = 208.0
	const H: float = 103.0
	var beat: float = sin(_elapsed * TAU * (2.6 + float(_cycle) * 0.6))
	var jitter_y: float = roundf(beat) if _scene_idx in [1, 4] else 0.0
	match _scene_idx:
		0: _draw_scene_wake(W, H, beat)
		1: _draw_scene_bus(W, H, jitter_y, false)
		2: _draw_scene_class(W, H)
		3: _draw_scene_lunch(W, H)
		4: _draw_scene_bus(W, H, jitter_y, true)
		5: _draw_scene_sleep(W, H)

	# Escurece e dessatura sutilmente conforme os ciclos acumulam cansaço.
	if _cycle > 0:
		var shade_alpha: float = 0.14 if _cycle == 1 else 0.30
		_montage_stage.draw_rect(Rect2(0, 0, W, H), Color(0.06, 0.04, 0.12, shade_alpha))
		var pulse_border: float = 0.25 if _cycle == 2 and beat > 0.2 else 0.0
		if pulse_border > 0.0:
			_montage_stage.draw_rect(Rect2(0, 0, W, 3), Color(0.75, 0.22, 0.32, pulse_border))
			_montage_stage.draw_rect(Rect2(0, H - 3, W, 3), Color(0.75, 0.22, 0.32, pulse_border))


func _draw_scene_wake(w: float, h: float, beat: float) -> void:
	var wall: Color = Color("#4c3a56") if _cycle < 2 else Color("#362b42")
	_montage_stage.draw_rect(Rect2(0, 0, w, 64), wall)
	_montage_stage.draw_rect(Rect2(0, 64, w, h - 64), Color("#634230"))
	_montage_stage.draw_rect(Rect2(0, 62, w, 2), Color("#2c1d28"))

	# Janela com luz do amanhecer.
	var sky: Color = Color("#ffbf78") if _cycle == 0 else (Color("#b88fa0") if _cycle == 1 else Color("#5e6485"))
	_montage_stage.draw_rect(Rect2(138, 12, 46, 36), Color("#181322"))
	_montage_stage.draw_rect(Rect2(140, 14, 42, 32), sky)
	_montage_stage.draw_rect(Rect2(160, 14, 2, 32), Color("#36273f"))
	_montage_stage.draw_rect(Rect2(140, 29, 42, 2), Color("#36273f"))
	_montage_stage.draw_rect(Rect2(136, 10, 8, 40), Color("#7a4e68"))
	_montage_stage.draw_rect(Rect2(178, 10, 8, 40), Color("#7a4e68"))

	# Cama à esquerda e cobertor.
	_montage_stage.draw_rect(Rect2(16, 48, 88, 36), Color("#291c33"))
	_montage_stage.draw_rect(Rect2(18, 38, 8, 48), Color("#593a2b"))
	_montage_stage.draw_rect(Rect2(26, 56, 76, 22), Color("#faf0dd"))
	_montage_stage.draw_rect(Rect2(28, 52, 20, 9), Color("#e2d4cc"))
	_montage_stage.draw_rect(Rect2(44, 58, 58, 18), Color("#3b4c73"))

	# Estudante sentando na cama (curvado conforme o ciclo).
	var droop: float = float(_cycle) * 2.0
	_draw_tiny_student(_montage_stage, Vector2(54, 44 + droop), true, _cycle)

	# Criado-mudo e despertador tocando na batida.
	_montage_stage.draw_rect(Rect2(114, 56, 22, 24), Color("#4a3026"))
	_montage_stage.draw_rect(Rect2(116, 58, 18, 2), Color("#704b38"))
	var shake_x: float = roundf(beat * 1.5)
	_montage_stage.draw_rect(Rect2(119 + shake_x, 46, 12, 10), Color("#d64256"))
	_montage_stage.draw_rect(Rect2(121 + shake_x, 48, 8, 6), Color("#181322"))
	_montage_stage.draw_rect(Rect2(122 + shake_x, 49, 6, 4), Color("#ff8f9e" if beat > 0.0 else "#ffe091"))
	if beat > 0.1:
		_montage_stage.draw_rect(Rect2(114, 42, 3, 2), Color("#ffd38a"))
		_montage_stage.draw_rect(Rect2(133, 42, 3, 2), Color("#ffd38a"))


func _draw_scene_bus(w: float, h: float, jitter_y: float, is_night: bool) -> void:
	# Interior do ônibus e paisagem passando nas janelas.
	var sky: Color = Color("#161529") if is_night else (Color("#9ec4e8") if _cycle == 0 else Color("#8a8ca8"))
	_montage_stage.draw_rect(Rect2(0, 0, w, 18), Color("#372d44"))
	_montage_stage.draw_rect(Rect2(0, 18, w, 46), sky)
	_montage_stage.draw_rect(Rect2(0, 64, w, h - 64), Color("#252033"))

	# Paisagem em movimento fora das janelas.
	var speed: float = 95.0 if is_night else 75.0
	var scroll: float = fmod(_elapsed * speed, 240.0)
	for idx: int in range(6):
		var px: float = fposmod(float(idx) * 44.0 - scroll, 240.0) - 20.0
		if is_night:
			_montage_stage.draw_rect(Rect2(px, 24, 2, 36), Color("#2b2844"))
			_montage_stage.draw_rect(Rect2(px - 2, 22, 6, 3), Color("#ffd275"))
			_montage_stage.draw_rect(Rect2(px - 10, 50, 14, 2), Color(1.0, 0.42, 0.42, 0.7))
		else:
			var bh: float = 16.0 + float((idx * 7) % 18)
			_montage_stage.draw_rect(Rect2(px, 62.0 - bh, 22, bh), Color("#4f5d78"))
			_montage_stage.draw_rect(Rect2(px + 4, 65.0 - bh, 3, 3), Color("#fff1b8"))
			_montage_stage.draw_rect(Rect2(px + 12, 65.0 - bh, 3, 3), Color("#fff1b8"))

	if is_night and _cycle >= 1:
		for drop: int in range(14):
			var rx: float = fmod(float(drop) * 19.0 + _elapsed * 45.0, w)
			var ry: float = fmod(float(drop) * 11.0 + _elapsed * 65.0, 44.0) + 18.0
			_montage_stage.draw_rect(Rect2(roundf(rx), roundf(ry), 1, 3), Color(0.62, 0.78, 0.98, 0.55))

	# Montantes das janelas do ônibus.
	for post_x: float in [0.0, 66.0, 134.0, 200.0]:
		_montage_stage.draw_rect(Rect2(post_x, 16, 8, 52), Color("#3d334c"))
	_montage_stage.draw_rect(Rect2(0, 60, w, 4), Color("#4e4261"))

	# Barras amarelas superiores e alças balançando.
	_montage_stage.draw_rect(Rect2(0, 12 + jitter_y, w, 3), Color("#e5ae3e"))
	for strap_x: int in range(28, 190, 32):
		var sway: float = roundf(sin(_elapsed * 5.0 + float(strap_x)) * 2.0)
		_montage_stage.draw_rect(Rect2(strap_x, 15 + jitter_y, 2, 7), Color("#c48f31"))
		_montage_stage.draw_rect(Rect2(strap_x - 2 + sway, 22 + jitter_y, 6, 5), Color("#f4cf6e"))

	# Barra vertical + passageiros espremidos dos dois lados sobre o piso do ônibus.
	_montage_stage.draw_rect(Rect2(0, 92, w, h - 92), Color("#1b1726"))
	_montage_stage.draw_rect(Rect2(102, 12, 3, h - 14), Color("#d9a236"))
	var crowd: Array[Array] = [
		[18, Color("#495575"), Color("#33293e")],
		[44, Color("#6e4b64"), Color("#4f3427")],
		[70, Color("#3e6466"), Color("#292334")],
		[130, Color("#6b5944"), Color("#28222e")],
		[156, Color("#51456e"), Color("#6b4032")],
		[182, Color("#3c4b5c"), Color("#1e1a26")],
	]
	for p_data: Array in crowd:
		var px: float = float(p_data[0])
		var coat: Color = p_data[1] as Color
		var hair: Color = p_data[2] as Color
		_montage_stage.draw_rect(Rect2(px, 54 + jitter_y, 20, 40), coat)
		_montage_stage.draw_rect(Rect2(px + 3, 38 + jitter_y, 14, 15), Color("#dcb49a"))
		_montage_stage.draw_rect(Rect2(px + 2, 36 + jitter_y, 16, 7), hair)
		_montage_stage.draw_rect(Rect2(px - 2, 54 + jitter_y, 2, 40), Color("#140f1d"))

	# Nosso estudante espremido no centro segurando a barra/mochila, apoiado no piso.
	var student_y: float = 54.0 + float(_cycle) * 2.0 + jitter_y
	_draw_tiny_student(_montage_stage, Vector2(96, student_y), false, _cycle)
	_montage_stage.draw_rect(Rect2(92, student_y + 12, 10, 12), Color("#8a5c3a"))
	_montage_stage.draw_rect(Rect2(101, student_y + 12, 4, 4), Color("#f0c2a3"))


func _draw_scene_class(w: float, h: float) -> void:
	_montage_stage.draw_rect(Rect2(0, 0, w, 68), Color("#584a66"))
	_montage_stage.draw_rect(Rect2(0, 68, w, h - 68), Color("#6e533d"))

	# Quadro verde grande cheio de prazos/anotações.
	_montage_stage.draw_rect(Rect2(24, 10, 160, 46), Color("#7b5134"))
	_montage_stage.draw_rect(Rect2(27, 13, 154, 40), Color("#254a3b"))
	for row: int in range(3):
		for dash: int in range(6):
			var span: float = 10.0 + float(((row + dash) * 5) % 10)
			var gx: float = 34.0 + float(dash) * 23.0
			var gy: float = 19.0 + float(row) * 10.0
			var chalk: Color = Color("#ff8d99") if (_cycle >= 1 and dash == 4) else Color("#dce8de")
			_montage_stage.draw_rect(Rect2(gx, gy, span, 2), chalk)

	# Carteira da esquerda (colega) e carteira central (estudante).
	_montage_stage.draw_rect(Rect2(22, 62, 40, 26), Color("#7d5336"))
	_montage_stage.draw_rect(Rect2(26, 48, 22, 16), Color("#5b4a7a"))
	_montage_stage.draw_rect(Rect2(30, 36, 12, 12), Color("#f2c7a5"))
	_montage_stage.draw_rect(Rect2(29, 34, 14, 6), Color("#292b47"))

	_draw_tiny_student(_montage_stage, Vector2(94, 42 + float(_cycle) * 2.0), false, _cycle)
	# Mesa do estudante + caderno + pilha crescente de tarefas!
	_montage_stage.draw_rect(Rect2(76, 62, 64, 10), Color("#91603f"))
	_montage_stage.draw_rect(Rect2(80, 72, 6, 22), Color("#543524"))
	_montage_stage.draw_rect(Rect2(130, 72, 6, 22), Color("#543524"))
	_montage_stage.draw_rect(Rect2(86, 54, 16, 8), Color("#3c4966"))
	_montage_stage.draw_rect(Rect2(88, 55, 12, 5), Color("#9ff4ff"))

	# Pilha de papéis crescendo nos ciclos 1 e 2.
	var paper_count: int = 2 + _cycle * 4
	for paper: int in range(paper_count):
		_montage_stage.draw_rect(Rect2(116, 60 - paper * 2, 18, 2),
				Color("#faf0dd") if paper % 2 == 0 else Color("#d2c4b4"))


func _draw_scene_lunch(w: float, h: float) -> void:
	_montage_stage.draw_rect(Rect2(0, 0, w, 62), Color("#5a647a"))
	_montage_stage.draw_rect(Rect2(0, 62, w, h - 62), Color("#464254"))

	# Relógio na parede do refeitório.
	_montage_stage.draw_rect(Rect2(160, 12, 22, 22), Color("#181322"))
	_montage_stage.draw_rect(Rect2(162, 14, 18, 18), Color("#faf0dd"))
	_montage_stage.draw_rect(Rect2(170, 16, 2, 8), Color("#d64256"))
	_montage_stage.draw_rect(Rect2(170, 22, 6 + _cycle, 2), Color("#181322"))

	# Janela do RU.
	_montage_stage.draw_rect(Rect2(18, 12, 54, 34), Color("#739dc4"))
	_montage_stage.draw_rect(Rect2(44, 12, 2, 34), Color("#3d354c"))

	# Estudante atrás da mesa com bandeja.
	_draw_tiny_student(_montage_stage, Vector2(92, 42 + float(_cycle) * 2.0), false, _cycle)
	_montage_stage.draw_rect(Rect2(54, 62, 100, 12), Color("#b39674"))
	_montage_stage.draw_rect(Rect2(60, 74, 8, 22), Color("#59473a"))
	_montage_stage.draw_rect(Rect2(140, 74, 8, 22), Color("#59473a"))

	# Bandeja metálica + comida + copo d'água + celular piscando.
	_montage_stage.draw_rect(Rect2(78, 56, 36, 10), Color("#b0bac7"))
	_montage_stage.draw_rect(Rect2(81, 58, 12, 6), Color("#faf0dd"))
	_montage_stage.draw_rect(Rect2(96, 58, 9, 6), Color("#664638"))
	_montage_stage.draw_rect(Rect2(118, 53, 7, 10), Color("#7bd9f5"))
	_montage_stage.draw_rect(Rect2(130, 58, 10, 5), Color("#26293d"))
	if _cycle > 0 and fmod(_elapsed, 0.5) < 0.25:
		_montage_stage.draw_rect(Rect2(132, 55, 6, 3), Color("#ff6e84"))


func _draw_scene_sleep(w: float, h: float) -> void:
	_montage_stage.draw_rect(Rect2(0, 0, w, 66), Color("#181326"))
	_montage_stage.draw_rect(Rect2(0, 66, w, h - 66), Color("#241b30"))

	# Janela noturna com lua.
	_montage_stage.draw_rect(Rect2(136, 10, 44, 34), Color("#0d0b18"))
	_montage_stage.draw_rect(Rect2(138, 12, 40, 30), Color("#222547"))
	_montage_stage.draw_rect(Rect2(164, 16, 7, 7), Color("#f6e09a"))
	_montage_stage.draw_rect(Rect2(166, 16, 5, 5), Color("#222547"))

	# Monitor ainda aceso no canto da escrivaninha.
	_montage_stage.draw_rect(Rect2(126, 48, 30, 24), Color("#2b2136"))
	_montage_stage.draw_rect(Rect2(132, 34, 18, 12), Color("#141926"))
	_montage_stage.draw_rect(Rect2(134, 36, 14, 8), Color("#46759c") if _cycle == 0 else Color("#71b8d4"))

	# Cama + estudante deitado debaixo do cobertor.
	_montage_stage.draw_rect(Rect2(18, 48, 86, 36), Color("#1f1629"))
	_montage_stage.draw_rect(Rect2(20, 40, 8, 44), Color("#3d2824"))
	_montage_stage.draw_rect(Rect2(28, 52, 18, 8), Color("#cfc3cc"))
	_montage_stage.draw_rect(Rect2(40, 56, 60, 18), Color("#2a3757"))
	# Cabeça no travesseiro olhando pro teto.
	_montage_stage.draw_rect(Rect2(30, 46, 14, 12), Color("#e2b89b" if _cycle < 2 else "#cab0a2"))
	_montage_stage.draw_rect(Rect2(28, 44, 16, 6), Color("#a83232"))
	_montage_stage.draw_rect(Rect2(28, 42, 12, 3), Color("#1d1724"))
	if _cycle >= 1:
		# Olhos abertos na escuridão / insônia.
		_montage_stage.draw_rect(Rect2(34, 51, 3, 2), Color("#181322"))
		_montage_stage.draw_rect(Rect2(39, 51, 3, 2), Color("#181322"))
	if _cycle == 2:
		_montage_stage.draw_rect(Rect2(34, 53, 8, 1), Color("#7b538a"))


func _draw_tiny_student(canvas: CanvasItem, pos: Vector2, sitting: bool, cycle: int) -> void:
	var x: float = roundf(pos.x)
	var y: float = roundf(pos.y)
	var skin: Color = Color("#f0c2a3") if cycle == 0 else (Color("#e0b69d") if cycle == 1 else Color("#cca79b"))
	# Corpo com moletom preto e zíper claro.
	canvas.draw_rect(Rect2(x - 8, y + 10, 16, 14 if sitting else 18), Color("#24222c"))
	canvas.draw_rect(Rect2(x - 1, y + 11, 2, 12 if sitting else 16), Color("#7d8594"))
	if not sitting:
		canvas.draw_rect(Rect2(x - 6, y + 28, 5, 8), Color("#1e2336"))
		canvas.draw_rect(Rect2(x + 1, y + 28, 5, 8), Color("#1e2336"))
	# Cabeça e cabelo ruivo com raízes pretas.
	canvas.draw_rect(Rect2(x - 7, y - 4, 14, 14), skin)
	canvas.draw_rect(Rect2(x - 8, y - 8, 16, 7), Color("#b33934"))
	canvas.draw_rect(Rect2(x - 6, y - 9, 12, 3), Color("#1e1824"))
	canvas.draw_rect(Rect2(x - 8, y - 2, 3, 4), Color("#c4463b"))
	canvas.draw_rect(Rect2(x + 5, y - 2, 3, 4), Color("#c4463b"))
	# Olhos e olheiras.
	canvas.draw_rect(Rect2(x - 4, y + 2, 2, 3 if cycle < 2 else 2), Color("#181322"))
	canvas.draw_rect(Rect2(x + 2, y + 2, 2, 3 if cycle < 2 else 2), Color("#181322"))
	if cycle >= 1:
		var circle_color: Color = Color("#7d5b82") if cycle == 1 else Color("#573b66")
		canvas.draw_rect(Rect2(x - 5, y + 5, 4, 1 if cycle == 1 else 2), circle_color)
		canvas.draw_rect(Rect2(x + 1, y + 5, 4, 1 if cycle == 1 else 2), circle_color)


func _draw_portrait_face() -> void:
	# Palco lógico 36x36 ampliado 3x -> 108x108 mostrando o rosto cansar a cada ciclo!
	const S: float = 36.0
	var skin: Color = Color("#f2c4a2") if _cycle == 0 else (Color("#e0b69d") if _cycle == 1 else Color("#c9a598"))
	var skin_shade: Color = skin.darkened(0.14)
	var droop: float = float(_cycle) * 1.5
	var blink: bool = fmod(_elapsed, 3.1) > 2.94
	var tremor_x: float = roundf(sin(_elapsed * 26.0)) if _cycle == 2 else 0.0

	# Ombros / moletom preto + alças da mochila.
	_portrait_stage.draw_rect(Rect2(5, 25 + droop, 26, 11), Color("#1d1a24"))
	_portrait_stage.draw_rect(Rect2(7, 26 + droop, 22, 10), Color("#2b2736"))
	_portrait_stage.draw_rect(Rect2(10, 26 + droop, 3, 10), Color("#8a5c3a"))
	_portrait_stage.draw_rect(Rect2(23, 26 + droop, 3, 10), Color("#8a5c3a"))
	_portrait_stage.draw_rect(Rect2(17, 27 + droop, 2, 9), Color("#9aa3b2"))

	# Pescoço.
	_portrait_stage.draw_rect(Rect2(15, 22 + droop, 6, 5), skin_shade)

	# Rosto.
	var fx: float = 10.0 + tremor_x
	var fy: float = 8.0 + droop
	_portrait_stage.draw_rect(Rect2(fx - 1, fy - 1, 18, 17), Color("#181322"))
	_portrait_stage.draw_rect(Rect2(fx, fy, 16, 15), skin)
	_portrait_stage.draw_rect(Rect2(fx, fy + 13, 16, 2), skin_shade)

	# Cabelo ruivo com raízes pretas.
	_portrait_stage.draw_rect(Rect2(fx - 2, fy - 5, 20, 7), Color("#b53733"))
	_portrait_stage.draw_rect(Rect2(fx + 1, fy - 6, 14, 3), Color("#1d1724"))
	_portrait_stage.draw_rect(Rect2(fx - 2, fy + 1, 3, 7), Color("#9e2c2b"))
	_portrait_stage.draw_rect(Rect2(fx + 15, fy + 1, 3, 7), Color("#9e2c2b"))
	_portrait_stage.draw_rect(Rect2(fx + 3, fy, 4, 2), Color("#cf493e"))
	_portrait_stage.draw_rect(Rect2(fx + 10, fy, 3, 2), Color("#cf493e"))

	# Olhos e olheiras progressivas.
	var eye_y: float = fy + 6.0
	if blink:
		_portrait_stage.draw_rect(Rect2(fx + 3, eye_y + 1, 3, 1), Color("#181322"))
		_portrait_stage.draw_rect(Rect2(fx + 10, eye_y + 1, 3, 1), Color("#181322"))
	else:
		var eye_h: float = 3.0 if _cycle == 0 else (2.0 if _cycle == 1 else 2.0)
		var lid_offset: float = 0.0 if _cycle == 0 else 1.0
		_portrait_stage.draw_rect(Rect2(fx + 3, eye_y + lid_offset, 3, eye_h), Color("#181322"))
		_portrait_stage.draw_rect(Rect2(fx + 10, eye_y + lid_offset, 3, eye_h), Color("#181322"))
		if _cycle == 0:
			_portrait_stage.draw_rect(Rect2(fx + 3, eye_y, 1, 1), Color("#faf0dd"))
			_portrait_stage.draw_rect(Rect2(fx + 10, eye_y, 1, 1), Color("#faf0dd"))

	# Sobrancelhas cansadas e olheiras.
	if _cycle == 1:
		_portrait_stage.draw_rect(Rect2(fx + 2, eye_y + 3, 5, 1), Color("#7a5582"))
		_portrait_stage.draw_rect(Rect2(fx + 9, eye_y + 3, 5, 1), Color("#7a5582"))
		_portrait_stage.draw_rect(Rect2(fx + 3, eye_y - 1, 3, 1), Color("#261b2e"))
		_portrait_stage.draw_rect(Rect2(fx + 10, eye_y - 1, 3, 1), Color("#261b2e"))
	elif _cycle == 2:
		_portrait_stage.draw_rect(Rect2(fx + 2, eye_y + 3, 5, 2), Color("#593a6b"))
		_portrait_stage.draw_rect(Rect2(fx + 9, eye_y + 3, 5, 2), Color("#593a6b"))
		_portrait_stage.draw_rect(Rect2(fx + 2, eye_y - 1, 4, 1), Color("#181322"))
		_portrait_stage.draw_rect(Rect2(fx + 10, eye_y - 1, 4, 1), Color("#181322"))

	# Boca.
	if _cycle == 0:
		_portrait_stage.draw_rect(Rect2(fx + 6, fy + 12, 4, 1), Color("#8c5252"))
	elif _cycle == 1:
		_portrait_stage.draw_rect(Rect2(fx + 6, fy + 12, 4, 1), Color("#734247"))
	else:
		_portrait_stage.draw_rect(Rect2(fx + 6, fy + 12, 4, 1), Color("#5c363e"))
		_portrait_stage.draw_rect(Rect2(fx + 5, fy + 13, 1, 1), Color("#5c363e"))
		_portrait_stage.draw_rect(Rect2(fx + 10, fy + 13, 1, 1), Color("#5c363e"))


func _draw_console_scene() -> void:
	const W: float = 282.0
	const H: float = 116.0
	_console_stage.draw_rect(Rect2(0, 0, W, 82), Color("#151120"))
	_console_stage.draw_rect(Rect2(0, 82, W, H - 82), Color("#251c33"))

	# Janela noturna ao fundo.
	_console_stage.draw_rect(Rect2(20, 14, 48, 36), Color("#0b0914"))
	_console_stage.draw_rect(Rect2(22, 16, 44, 32), Color("#1d2042"))
	_console_stage.draw_rect(Rect2(50, 20, 7, 7), Color("#ffe29b"))
	_console_stage.draw_rect(Rect2(52, 20, 5, 5), Color("#1d2042"))

	# Estante + TV de tubo + Console retrô à direita.
	_console_stage.draw_rect(Rect2(168, 66, 86, 32), Color("#4f3328"))
	_console_stage.draw_rect(Rect2(168, 66, 86, 3), Color("#7a533e"))

	# Gabinete da TV CRT.
	_console_stage.draw_rect(Rect2(178, 20, 58, 46), Color("#2b2636"))
	_console_stage.draw_rect(Rect2(180, 22, 54, 42), Color("#3d364c"))
	var tv_rect: Rect2 = Rect2(184, 26, 42, 32)
	var tv_center: Vector2 = tv_rect.get_center()

	if _console_step == 0:
		_console_stage.draw_rect(tv_rect, Color("#151a26"))
		_console_stage.draw_rect(Rect2(186, 28, 38, 2), Color("#242e40"))
	else:
		# Tela ligada com miniatura colorida de "Três Turnos" + scanlines.
		_console_stage.draw_texture_rect(ROOM_MORNING_TEX, tv_rect, false, Color("#d4fff8"))
		for sy: int in range(int(tv_rect.position.y), int(tv_rect.end.y), 3):
			_console_stage.draw_rect(Rect2(tv_rect.position.x, float(sy), tv_rect.size.x, 1),
					Color(0.05, 0.08, 0.14, 0.28))
		# Feixe luminoso da TV iluminando o quarto escuro.
		var glow_strength: float = 0.22 if _console_step == 1 else clampf(0.24 + _console_elapsed * 0.24, 0.24, 0.65)
		_console_stage.draw_colored_polygon(PackedVector2Array([
			Vector2(184, 26), Vector2(184, 58), Vector2(40, 108), Vector2(40, 44),
		]), Color(0.45, 0.94, 0.96, glow_strength * 0.35))

	# Console ao lado da TV e cartucho.
	_console_stage.draw_rect(Rect2(238, 56, 14, 10), Color("#24202e"))
	_console_stage.draw_rect(Rect2(240, 54, 10, 4), Color("#7d8594") if _console_step == 0 else Color("#e8a848"))
	if _console_step >= 1:
		_console_stage.draw_rect(Rect2(248, 61, 2, 2), Color("#70ffae"))

	# Cabo do controle até o estudante no tapete.
	_console_stage.draw_rect(Rect2(84, 88, 156, 2), Color("#120f1a"))
	_console_stage.draw_rect(Rect2(56, 86, 46, 12), Color("#364561"))

	# Estudante sentado olhando a TV (ou sendo puxado para dentro da tela na etapa 2).
	var student_pos: Vector2 = Vector2(78, 63)
	var student_tint: Color = Color.WHITE
	if _console_step == 2:
		var pull: float = clampf(_console_elapsed / 2.2, 0.0, 1.0)
		student_pos = student_pos.lerp(tv_center - Vector2(0, 6), pull * pull)
		student_tint = Color.WHITE.lerp(Color("#94ffff"), pull)
		# Vórtice de anéis e partículas saindo da TV!
		for ring: int in range(5):
			var phase: float = fmod(_console_elapsed * 1.9 + float(ring) * 0.2, 1.0)
			var radius: float = lerpf(6.0, 72.0, phase)
			var ring_col: Color = Retro.MINT if ring % 2 == 0 else Retro.GOLD
			ring_col.a = sin(phase * PI) * 0.85
			_console_stage.draw_arc(tv_center, radius, 0.0, TAU, 32, ring_col, 2.0)
		for mote: int in range(12):
			var t: float = fmod(_console_elapsed * 2.4 + float(mote) / 12.0, 1.0)
			var start_p: Vector2 = Vector2(46.0 + float(mote % 4) * 18.0, 44.0 + float(mote * 6 % 56))
			var mp: Vector2 = start_p.lerp(tv_center, t).round()
			_console_stage.draw_rect(Rect2(mp, Vector2(2, 2)), Color(0.75, 1.0, 0.95, 1.0 - t * 0.4))

	if student_tint.a > 0.05:
		_console_stage.modulate = Color.WHITE
		_draw_tiny_student(_console_stage, student_pos, true, 1 if _console_step < 2 else 0)
		_console_stage.draw_rect(Rect2(roundf(student_pos.x + 7.0), roundf(student_pos.y + 17.0), 8, 4),
				Color("#2c3448"))
		_console_stage.draw_rect(Rect2(roundf(student_pos.x + 12.0), roundf(student_pos.y + 18.0), 2, 2),
				Color("#e55a74"))
		if _console_step == 2:
			_console_stage.draw_circle(student_pos + Vector2(0, 4), 14.0,
					Color(0.55, 1.0, 0.96, clampf(_console_elapsed * 0.35, 0.0, 0.55)))

	# Clarão final antes da transição para a Sala 1.
	if _console_step == 2 and _console_elapsed > 1.7:
		var flash: float = clampf((_console_elapsed - 1.7) / 0.65, 0.0, 1.0)
		_console_stage.draw_rect(Rect2(0, 0, W, H), Color(0.84, 1.0, 0.98, flash))


func _draw_ending_scene() -> void:
	const W: float = 320.0
	const H: float = 180.0
	if _dawn_bg != null:
		_ending_stage.draw_texture(_dawn_bg, Vector2.ZERO)

	# Raios suaves de sol nascente à direita.
	var pulse: float = 0.5 + 0.5 * sin(_elapsed * 2.0)
	var sun_center: Vector2 = Vector2(272, 134)
	for radius: float in [44.0, 28.0, 16.0]:
		_ending_stage.draw_circle(sun_center, radius, Color(1.0, 0.88, 0.62, 0.10 + pulse * 0.04))
	_ending_stage.draw_circle(sun_center, 8.0, Color("#fff3cf"))

	# Silhuetas de colinas ao amanhecer.
	_ending_stage.draw_colored_polygon(PackedVector2Array([
		Vector2(0, 146), Vector2(68, 128), Vector2(154, 140), Vector2(238, 124), Vector2(320, 138),
		Vector2(320, H), Vector2(0, H),
	]), Color("#261c38"))
	_ending_stage.draw_colored_polygon(PackedVector2Array([
		Vector2(0, 160), Vector2(92, 146), Vector2(198, 156), Vector2(320, 144),
		Vector2(320, H), Vector2(0, H),
	]), Color("#191326"))

	# Ramo de árvore à direita + pequeno pássaro da esperança animado.
	_ending_stage.draw_rect(Rect2(246, 86, 74, 4), Color("#181224"))
	_ending_stage.draw_rect(Rect2(262, 82, 14, 2), Color("#181224"))
	_ending_stage.draw_rect(Rect2(252, 85, 8, 2), Color("#36453c"))
	_ending_stage.draw_rect(Rect2(288, 84, 10, 2), Color("#36453c"))

	var bob: float = roundf(sin(_elapsed * 3.2) * 0.8)
	var bx: float = 270.0
	var by: float = 73.0 + bob
	# Perninhas
	_ending_stage.draw_rect(Rect2(bx + 3, 83, 1, 3), Color("#d48a46"))
	_ending_stage.draw_rect(Rect2(bx + 6, 83, 1, 3), Color("#d48a46"))
	# Corpo, asa dourada/celeste, peito quente e cabeça.
	_ending_stage.draw_rect(Rect2(bx, by + 3, 11, 8), Color("#63b8d9"))
	_ending_stage.draw_rect(Rect2(bx + 9, by + 6, 6, 3), Color("#417fa1"))
	_ending_stage.draw_rect(Rect2(bx + 1, by + 6, 5, 4), Color("#f6c580"))
	_ending_stage.draw_rect(Rect2(bx + 4, by + 4, 6, 4), Color("#8fe6f5"))
	_ending_stage.draw_rect(Rect2(bx - 1, by, 7, 6), Color("#73cbe8"))
	# Bico e olhinho piscando suavemente.
	_ending_stage.draw_rect(Rect2(bx - 4, by + 2, 3, 2), Color("#f4ba72"))
	if fmod(_elapsed, 3.6) < 3.45:
		_ending_stage.draw_rect(Rect2(bx + 1, by + 2, 1, 1), Color("#181322"))

	# Penas luminosas e partículas suaves subindo pelo céu.
	for seed_vec: Vector3 in _feather_seeds:
		var t: float = fposmod(_elapsed * 0.08 + seed_vec.z * 0.1, 1.0)
		var px: float = fposmod(seed_vec.x + sin(_elapsed * 1.4 + seed_vec.z) * 8.0, W)
		var py: float = H - t * (H + 10.0)
		var alpha: float = sin(t * PI) * 0.72
		var pcol: Color = Color("#ffe7a6" if int(seed_vec.z * 10.0) % 2 == 0 else "#a8f3e4")
		pcol.a = alpha
		_ending_stage.draw_rect(Rect2(roundf(px), roundf(py), 2, 1), pcol)
		_ending_stage.draw_rect(Rect2(roundf(px + 1.0), roundf(py - 1.0), 1, 2), pcol)


func _build_dawn_texture() -> ImageTexture:
	const W: int = 320
	const H: int = 180
	var img: Image = Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	var bayer: Array[float] = [0.0, 0.5, 0.75, 0.25]
	var stops: Array[Color] = [
		Color("#1c1836"), Color("#392852"), Color("#6b3b60"), Color("#b05e66"), Color("#e89c68"),
	]
	for y: int in range(H):
		var scaled: float = float(y) / float(H - 1) * float(stops.size() - 1)
		var band: int = mini(stops.size() - 2, int(floorf(scaled)))
		var frac: float = scaled - float(band)
		var c1: Color = stops[band]
		var c2: Color = stops[band + 1]
		for x: int in range(W):
			var thresh: float = bayer[((x & 1) * 2) + (y & 1)]
			img.set_pixel(x, y, c2 if frac > thresh else c1)
	return ImageTexture.create_from_image(img)
