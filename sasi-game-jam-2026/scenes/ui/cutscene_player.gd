extends CanvasLayer

const Retro = preload("res://scenes/ui/retro_window.gd")
const STUDENT_SHEET: Texture2D = preload("res://assets/sprites/student_sheet.png")
const STUDENT_CUTSCENE_SHEET: Texture2D = preload("res://assets/sprites/student_cutscene_sheet.png")
const ROOM_MORNING_TEX: Texture2D = preload("res://assets/sprites/room_morning.png")
const PORTRAITS_TEX: Texture2D = preload("res://assets/sprites/cutscene_portraits.png")
const CONSOLE_TEX: Texture2D = preload("res://assets/sprites/cutscene_console.png")
const DAWN_TEX: Texture2D = preload("res://assets/sprites/cutscene_dawn.png")
const SCENE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/cutscene_wake.png"),
	preload("res://assets/sprites/cutscene_bus_day.png"),
	preload("res://assets/sprites/cutscene_class.png"),
	preload("res://assets/sprites/cutscene_lunch.png"),
	preload("res://assets/sprites/cutscene_bus_night.png"),
	preload("res://assets/sprites/cutscene_sleep.png"),
]
const HAPPY_SCENE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/cutscene_happy_wake.png"),
	preload("res://assets/sprites/cutscene_happy_bus.png"),
	preload("res://assets/sprites/cutscene_happy_class.png"),
	preload("res://assets/sprites/cutscene_happy_lunch.png"),
	preload("res://assets/sprites/cutscene_happy_sunset.png"),
	preload("res://assets/sprites/cutscene_happy_sleep.png"),
]

enum Phase { NONE, MONTAGE, INTRO_POEM, CONSOLE_ENTRY, CONSOLE_EXIT, HAPPY_MONTAGE, ENDING_POEM }

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
const HAPPY_SCENE_NAMES: Array[String] = [
	"BEBENDO ÁGUA", "ACEITANDO A ROTINA", "FOCO NA AULA", "ALMOÇO COM CALMA", "HORA DO TREINO", "DORMIR BEM",
]
const HAPPY_TIMES: Array[String] = ["07:00", "07:35", "08:30", "12:15", "17:45", "22:30"]
const HAPPY_CAPTIONS: Array[String] = [
	"O despertador ainda toca cedo, mas agora o dia começa com calma e um copo d'água.",
	"O mesmo busão de sempre — só que sem carregar o peso do mundo na mochila.",
	"Uma matéria de cada vez, anotando no meu ritmo e sem esquecer da garrafinha.",
	"Almoço sem pressa no RU, jogando conversa fora com o pessoal da turma.",
	"Fim de tarde pra suar a camisa, soltar o corpo e deixar o estresse ir embora.",
	"Celular longe e cabeça tranquila. Amanhã tem mais, e tá tudo bem.",
]
const EXIT_CAPTIONS: Array[String] = [
	"Acordo no susto no tapete do quarto, coração acelerado... eu dormi com o controle na mão?",
	"A rotina puxada não vai sumir sozinha... mas eu tinha esquecido de mim no meio dela.",
	"Um copo d'água, um treino, uma noite bem dormida. Um dia de cada vez já basta.",
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
]
const CONSOLE_CAPTIONS: Array[String] = [
	"Minha cabeça não para... vou ligar o videogame um pouco pra ver se desligo.",
	"A TV acende no quarto escuro. Os olhos pesam na frente da tela...",
	"E num piscar de olhos... parece que a tela me puxou pra dentro.",
]
const HOPE_LINES: Array[String] = [
	"A vida é uns deveres que nós trouxemos para fazer em casa.",
	"Quando se vê, já são 6 horas: há tempo...",
	"Quando se vê, já é 6ª-feira...",
	"Quando se vê, passaram 60 anos!",
	"Agora, é tarde demais para ser reprovado...",
	"E se me dessem — um dia — uma outra oportunidade,",
	"eu nem olhava o relógio",
	"seguia sempre em frente...",
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
var _intro_poem_schedule: Array[float] = []
var _ending_poem_schedule: Array[float] = []

var _backdrop: ColorRect
var _montage_root: Control
var _montage_cycle_lbl: Label
var _montage_scene_lbl: Label
var _montage_caption: Label
var _montage_fatigue_lbl: Label
var _montage_sub_lbl: Label
var _montage_bar_fill: ColorRect
var _montage_stage: Node2D
var _portrait_stage: Node2D

var _intro_poem_root: Control
var _intro_poem_stage: Node2D
var _intro_poem_labels: Array[Label] = []
var _intro_poem_author: Label
var _intro_poem_prompt: RichTextLabel

var _console_root: Control
var _console_stage: Node2D
var _console_caption: Label

var _ending_poem_root: Control
var _ending_stage: Node2D
var _ending_poem_labels: Array[Label] = []
var _ending_poem_author: Label
var _ending_poem_prompt: RichTextLabel

var _feather_seeds: Array[Vector3] = []


func _ready() -> void:
	for index: int in range(14):
		_feather_seeds.append(Vector3(
			fmod(float(index) * 23.7 + 14.0, 310.0),
			fmod(float(index) * 19.3 + 12.0, 170.0),
			float(index) * 0.85
		))

	_backdrop = Retro.block(self, Rect2(0, 0, 640, 360), Color("#050408"))
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP

	_build_montage_ui()
	_build_intro_poem_ui()
	_build_console_ui()
	_build_ending_poem_ui()
	GameManager.state_changed.connect(_on_state_changed)
	hide()


func _build_poem_schedule(lines: Array[String], first_delay: float, base_step: float,
		stanza_pause: float) -> Array[float]:
	var schedule: Array[float] = []
	var t: float = first_delay
	for line: String in lines:
		if line.is_empty():
			t += stanza_pause
			continue
		schedule.append(t)
		t += base_step + clampf(float(line.length() - 18) * 0.018, 0.0, 0.42)
	schedule.append(t + 1.40)
	return schedule


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
	_portrait_stage.position = Vector2(490, 72)
	_portrait_stage.scale = Vector2(2, 2)
	_portrait_stage.draw.connect(_draw_portrait_face)
	_montage_root.add_child(_portrait_stage)

	_montage_fatigue_lbl = Retro.label(_montage_root, Rect2(476, 184, 124, 16), "", 11, Retro.MINT,
			HORIZONTAL_ALIGNMENT_CENTER)
	Retro.block(_montage_root, Rect2(484, 206, 108, 10), Retro.INK)
	_montage_bar_fill = Retro.block(_montage_root, Rect2(486, 208, 104, 6), Retro.MINT)
	_montage_sub_lbl = Retro.label(_montage_root, Rect2(476, 224, 124, 16), "Cansaço acumulado", 10,
			Retro.MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	var caption_box: Panel = Retro.panel(_montage_root, Rect2(32, 266, 576, 80), false, false)
	_montage_caption = Retro.label(caption_box, Rect2(14, 10, 548, 40), "", 13, Retro.CREAM)
	_montage_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_montage_caption.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	Retro.rich_label(caption_box, Rect2(14, 56, 548, 16),
			"[ESPAÇO / CLIQUE] Avançar    •    [ESC] Pular", 10, Retro.MUTED)


func _build_intro_poem_ui() -> void:
	_intro_poem_root = Control.new()
	_intro_poem_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Retro.place(_intro_poem_root, self, Rect2(0, 0, 640, 360))
	_intro_poem_root.hide()

	_intro_poem_stage = Node2D.new()
	_intro_poem_stage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_intro_poem_stage.scale = Vector2(2, 2)
	_intro_poem_stage.draw.connect(_draw_intro_poem_scene)
	_intro_poem_root.add_child(_intro_poem_stage)

	var title: Label = Retro.label(_intro_poem_root, Rect2(60, 64, 520, 20), "CANSAÇO", 14,
			Retro.GOLD, HORIZONTAL_ALIGNMENT_CENTER, false)
	title.add_theme_font_override(&"font", Retro.FONT_BOLD)
	Retro.block(_intro_poem_root, Rect2(260, 88, 120, 1), Color("#3b324a"))

	_intro_poem_labels.clear()
	var cursor_y: int = 112
	for line: String in CANSACO_LINES:
		if line.is_empty():
			cursor_y += 10
			continue
		var lbl: Label = Retro.label(_intro_poem_root, Rect2(48, cursor_y, 544, 18), line, 12,
				Retro.CREAM, HORIZONTAL_ALIGNMENT_CENTER, false)
		lbl.modulate.a = 0.0
		_intro_poem_labels.append(lbl)
		cursor_y += 22

	_intro_poem_schedule = _build_poem_schedule(CANSACO_LINES, 0.65, 1.60, 1.05)

	_intro_poem_author = Retro.label(_intro_poem_root, Rect2(48, 244, 544, 18),
			"— Álvaro de Campos (Fernando Pessoa, 1934)", 11, Retro.BEVEL_LIGHT,
			HORIZONTAL_ALIGNMENT_CENTER, false)
	_intro_poem_author.modulate.a = 0.0
	_intro_poem_prompt = Retro.rich_label(_intro_poem_root, Rect2(48, 328, 544, 18),
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
	Retro.rich_label(box, Rect2(14, 50, 548, 16),
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

	Retro.panel(_ending_poem_root, Rect2(20, 16, 452, 328), true, true)
	var title: Label = Retro.label(_ending_poem_root, Rect2(32, 28, 428, 18),
			"O TEMPO  •  SEGUIR EM FRENTE", 13, Retro.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override(&"font", Retro.FONT_BOLD)
	Retro.divider(_ending_poem_root, Rect2(52, 50, 388, 1))

	_ending_poem_labels.clear()
	var cursor_y: int = 68
	for line: String in HOPE_LINES:
		if line.is_empty():
			cursor_y += 10
			continue
		var lbl: Label = Retro.label(_ending_poem_root, Rect2(28, cursor_y, 436, 18), line, 11,
				Retro.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		lbl.modulate.a = 0.0
		_ending_poem_labels.append(lbl)
		cursor_y += 22

	_ending_poem_schedule = _build_poem_schedule(HOPE_LINES, 0.65, 1.60, 1.05)

	_ending_poem_author = Retro.label(_ending_poem_root, Rect2(32, 260, 428, 18),
			"— Mário Quintana", 11, Retro.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_ending_poem_author.modulate.a = 0.0
	_ending_poem_prompt = Retro.rich_label(_ending_poem_root, Rect2(32, 314, 428, 16),
			"[ESPAÇO / CLIQUE] Continuar    •    [ESC] Pular", 10, Retro.MUTED,
			HORIZONTAL_ALIGNMENT_CENTER)


func play_intro(on_finished: Callable = Callable()) -> void:
	_finishing = false
	_on_finished = on_finished
	_elapsed = 0.0
	show()
	GameManager.set_state(GameManager.GameState.CUTSCENE)
	_enter_phase(Phase.MONTAGE)


func play_outro(on_finished: Callable = Callable()) -> void:
	_finishing = false
	_on_finished = on_finished
	_elapsed = 0.0
	show()
	GameManager.set_state(GameManager.GameState.CUTSCENE)
	_enter_phase(Phase.CONSOLE_EXIT)


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
		Phase.CONSOLE_EXIT: return "CONSOLE_EXIT"
		Phase.HAPPY_MONTAGE: return "HAPPY_MONTAGE"
		Phase.ENDING_POEM: return "ENDING_POEM"
		_: return "NONE"


func _enter_phase(next_phase: Phase) -> void:
	_phase = next_phase
	_montage_root.visible = next_phase in [Phase.MONTAGE, Phase.HAPPY_MONTAGE]
	_intro_poem_root.visible = (next_phase == Phase.INTRO_POEM)
	_console_root.visible = next_phase in [Phase.CONSOLE_ENTRY, Phase.CONSOLE_EXIT]
	_ending_poem_root.visible = (next_phase == Phase.ENDING_POEM)
	match next_phase:
		Phase.MONTAGE:
			_cycle = 0
			_scene_idx = 0
			_beat_elapsed = 0.0
			_pause_before_poem = false
			_pause_elapsed = 0.0
			AudioManager.play_track(&"beethoven", -7.5, CYCLE_PITCHES[0])
			AudioManager.play_alarm_beep()
			_refresh_montage_labels()
		Phase.INTRO_POEM:
			AudioManager.play_track(&"poem", -7.5, 1.0)
			_poem_elapsed = 0.0
			_poem_reveal_count = 0
			for lbl: Label in _intro_poem_labels:
				lbl.modulate.a = 0.0
			_intro_poem_author.modulate.a = 0.0
		Phase.CONSOLE_ENTRY:
			AudioManager.play_track(&"poem", -10.5, 1.0)
			_console_step = 0
			_console_elapsed = 0.0
			_console_caption.text = CONSOLE_CAPTIONS[0]
		Phase.CONSOLE_EXIT:
			AudioManager.stop_music()
			_console_step = 0
			_console_elapsed = 0.0
			_console_caption.text = EXIT_CAPTIONS[0]
		Phase.HAPPY_MONTAGE:
			_cycle = 0
			_scene_idx = 0
			_beat_elapsed = 0.0
			_pause_before_poem = false
			_pause_elapsed = 0.0
			if AudioManager.music_player.stream != AudioManager._music.get(&"morning") or not AudioManager.music_player.playing:
				AudioManager.play_track(&"morning", -8.0, 1.0)
			_refresh_montage_labels()
		Phase.ENDING_POEM:
			AudioManager.play_track(&"hope", -7.5, 1.0)
			_poem_elapsed = 0.0
			_poem_reveal_count = 0
			for lbl: Label in _ending_poem_labels:
				lbl.modulate.a = 0.0
			_ending_poem_author.modulate.a = 0.0


func _refresh_montage_labels() -> void:
	if _phase == Phase.HAPPY_MONTAGE:
		_montage_cycle_lbl.text = "NOVA ROTINA  •  EQUILÍBRIO"
		_montage_cycle_lbl.add_theme_color_override(&"font_color", Retro.MINT)
		_montage_scene_lbl.text = "%s  •  %s" % [HAPPY_TIMES[_scene_idx], HAPPY_SCENE_NAMES[_scene_idx]]
		_montage_caption.text = HAPPY_CAPTIONS[_scene_idx]
		_montage_fatigue_lbl.text = "FELIZ E EM PAZ"
		_montage_fatigue_lbl.add_theme_color_override(&"font_color", Retro.MINT)
		_montage_bar_fill.size = Vector2(104.0, 6.0)
		_montage_bar_fill.set_deferred(&"size", Vector2(104.0, 6.0))
		_montage_bar_fill.color = Retro.MINT
		_montage_sub_lbl.text = "Bem-estar cultivado"
		return
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
	_montage_sub_lbl.text = "Cansaço acumulado"


func _process(delta: float) -> void:
	if _phase == Phase.NONE or _finishing or GameManager.current_state != GameManager.GameState.CUTSCENE:
		return
	_elapsed += delta
	match _phase:
		Phase.MONTAGE:
			_tick_montage(delta)
			_montage_stage.queue_redraw()
			_portrait_stage.queue_redraw()
		Phase.HAPPY_MONTAGE:
			_tick_happy_montage(delta)
			_montage_stage.queue_redraw()
			_portrait_stage.queue_redraw()
		Phase.INTRO_POEM:
			_tick_poem(delta, _intro_poem_labels, _intro_poem_author, _intro_poem_schedule)
			_intro_poem_stage.queue_redraw()
		Phase.CONSOLE_ENTRY:
			_tick_console(delta)
			_console_stage.queue_redraw()
		Phase.CONSOLE_EXIT:
			_tick_console_exit(delta)
			_console_stage.queue_redraw()
		Phase.ENDING_POEM:
			_tick_poem(delta, _ending_poem_labels, _ending_poem_author, _ending_poem_schedule)
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


func _tick_happy_montage(delta: float) -> void:
	if _pause_before_poem:
		_pause_elapsed += delta
		if _pause_elapsed >= 0.35:
			_enter_phase(Phase.ENDING_POEM)
		return
	_beat_elapsed += delta
	if _beat_elapsed >= 1.32:
		_beat_elapsed -= 1.32
		_scene_idx += 1
		if _scene_idx >= 6:
			_scene_idx = 5
			_pause_before_poem = true
			_pause_elapsed = 0.0
			return
		_refresh_montage_labels()


func _tick_poem(delta: float, labels: Array[Label], author: Label, schedule: Array[float]) -> void:
	_poem_elapsed += delta
	var target: int = 0
	for threshold: float in schedule:
		if _poem_elapsed >= threshold:
			target += 1
		else:
			break
	_poem_reveal_count = maxi(_poem_reveal_count, target)
	for index: int in range(labels.size()):
		var desired: float = 1.0 if index < _poem_reveal_count else 0.0
		labels[index].modulate.a = move_toward(labels[index].modulate.a, desired, delta * 0.90)
	var author_target: float = 1.0 if _poem_reveal_count > labels.size() else 0.0
	author.modulate.a = move_toward(author.modulate.a, author_target, delta * 0.85)


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
		AudioManager.stop_music()
		AudioManager.play_console_boot()


func _tick_console_exit(delta: float) -> void:
	_console_elapsed += delta
	if _console_elapsed >= 2.7:
		_advance_console_exit()


func _advance_console_exit() -> void:
	_console_step += 1
	_console_elapsed = 0.0
	if _console_step >= 3:
		_enter_phase(Phase.HAPPY_MONTAGE)
		return
	_console_caption.text = EXIT_CAPTIONS[_console_step]
	if _console_step == 1:
		AudioManager.play_track(&"morning", -8.0, 1.0)


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
		Phase.CONSOLE_EXIT:
			_advance_console_exit()
		Phase.HAPPY_MONTAGE:
			_enter_phase(Phase.ENDING_POEM)
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


# --- Renderização com assets 32-bit do jogo e animação ao vivo sincronizada ---

func _draw_intro_poem_scene() -> void:
	# Moldura minimalista com cantoneiras e poeira noturna flutuando suavemente no preto.
	var frame_col: Color = Color("#241d32")
	var corner_col: Color = Color("#4a3b61")
	_intro_poem_stage.draw_rect(Rect2(14, 12, 292, 1), frame_col)
	_intro_poem_stage.draw_rect(Rect2(14, 167, 292, 1), frame_col)
	_intro_poem_stage.draw_rect(Rect2(14, 12, 1, 155), frame_col)
	_intro_poem_stage.draw_rect(Rect2(306, 12, 1, 155), frame_col)
	for cpos: Vector2 in [Vector2(13, 11), Vector2(303, 11), Vector2(13, 164), Vector2(303, 164)]:
		_intro_poem_stage.draw_rect(Rect2(cpos, Vector2(4, 4)), corner_col)
	for idx: int in range(_feather_seeds.size()):
		var seed_v: Vector3 = _feather_seeds[idx]
		var t: float = fposmod(_elapsed * 0.045 + seed_v.z * 0.09, 1.0)
		var px: float = 20.0 + fposmod(seed_v.x + sin(_elapsed * 0.9 + seed_v.z) * 5.0, 280.0)
		var py: float = 18.0 + t * 144.0
		var a: float = sin(t * PI) * 0.22
		var mcol: Color = Color("#c8b6e0" if idx % 2 == 0 else "#f4cf88")
		mcol.a = a
		_intro_poem_stage.draw_rect(Rect2(roundf(px), roundf(py), 1, 1), mcol)


func _draw_montage_scene() -> void:
	const W: float = 208.0
	const H: float = 103.0
	var happy: bool = _phase == Phase.HAPPY_MONTAGE
	var beat: float = sin(_elapsed * TAU * (1.8 if happy else (2.6 + float(_cycle) * 0.6)))
	var jitter_y: float = roundf(beat * (0.4 if happy else 1.0)) if ((happy and _scene_idx == 1) or (not happy and _scene_idx in [1, 4])) else 0.0
	var tex: Texture2D = HAPPY_SCENE_TEXTURES[_scene_idx] if happy else SCENE_TEXTURES[_scene_idx]
	_montage_stage.draw_texture_rect(tex, Rect2(0.0, jitter_y, W, H), false)

	if happy:
		match _scene_idx:
			0:
				var sun_a: float = 0.09 + 0.04 * beat
				_montage_stage.draw_colored_polygon(PackedVector2Array([
					Vector2(138, 12), Vector2(182, 12), Vector2(126, 98), Vector2(70, 98),
				]), Color(1.0, 0.92, 0.65, sun_a))
				# Gotas e brilhos de hidratação subindo ao beber água fresca.
				for drop_i: int in range(3):
					var dt: float = fmod(_elapsed * 1.1 + float(drop_i) * 0.33, 1.0)
					var dx: float = 96.0 + float(drop_i) * 7.0 + sin(_elapsed * 3.2 + float(drop_i)) * 1.5
					var dy: float = 47.0 - dt * 11.0
					var dcol := Color("#8de5ff" if drop_i % 2 == 0 else "#80f1a8")
					dcol.a = sin(dt * PI) * 0.85
					_montage_stage.draw_rect(Rect2(roundf(dx), roundf(dy), 2, 2), dcol)
			1:
				var scroll: float = fmod(_elapsed * 42.0, 220.0)
				for pane: Vector2i in [Vector2i(9, 63), Vector2i(75, 131), Vector2i(143, 197)]:
					for idx: int in range(3):
						var raw_x: float = fposmod(float(idx) * 74.0 - scroll, 220.0) - 14.0
						var left_x: float = clampf(roundf(raw_x), float(pane.x), float(pane.y))
						var right_x: float = clampf(roundf(raw_x) + 12.0, float(pane.x), float(pane.y))
						if right_x > left_x:
							_montage_stage.draw_rect(Rect2(left_x, 22 + (idx % 2) * 5, right_x - left_x, 3), Color(1.0, 1.0, 1.0, 0.42))
				for strap_x: int in range(28, 190, 32):
					var sway: float = roundf(sin(_elapsed * 3.0 + float(strap_x)) * 1.2)
					_montage_stage.draw_rect(Rect2(strap_x, 14 + jitter_y, 2, 7), Color("#d49b39"))
					_montage_stage.draw_rect(Rect2(strap_x - 2 + sway, 21 + jitter_y, 6, 5), Color("#f4cf6e"))
			2:
				_montage_stage.draw_circle(Vector2(186, 18), 3.0, Color(0.55, 1.0, 0.86, 0.25 + 0.15 * beat))
			3:
				for steam: int in range(4):
					var phase: float = fmod(_elapsed * 0.9 + float(steam) * 0.25, 1.0)
					var sx: float = 76.0 + float(steam % 2) * 52.0 + sin(_elapsed * 3.0 + float(steam)) * 2.0
					var sy: float = 54.0 - phase * 12.0
					_montage_stage.draw_rect(Rect2(roundf(sx), roundf(sy), 2, 2), Color(1.0, 0.96, 0.88, (1.0 - phase) * 0.65))
			4:
				# Rosca direta na academia: antebraços conectados aos ombros erguendo a barra com anilhas (sem duplicata!).
				var curl_t: float = 0.5 - 0.5 * cos(_elapsed * 4.0)
				var bar_y: float = roundf(lerpf(73.0, 66.0, curl_t))
				var arm_top: float = 68.0
				var arm_bot: float = maxf(arm_top + 1.0, bar_y)
				# Antebraços esquerdo (x=86) e direito (x=94) conectados aos ombros do sprite em (78, 52).
				for ax: float in [86.0, 94.0]:
					_montage_stage.draw_rect(Rect2(ax - 1.0, arm_top, 4.0, arm_bot - arm_top + 2.0), Retro.INK)
					_montage_stage.draw_rect(Rect2(ax, arm_top, 2.0, arm_bot - arm_top + 1.0), Color("#ffdfb5"))
				# Barra olímpica horizontal.
				_montage_stage.draw_rect(Rect2(74.0, bar_y, 34.0, 3.0), Retro.INK)
				_montage_stage.draw_rect(Rect2(75.0, bar_y + 1.0, 32.0, 1.0), Color("#c2d1de"))
				# Mãos segurando a barra.
				_montage_stage.draw_rect(Rect2(86.0, bar_y, 2.0, 2.0), Color("#ffdfb5"))
				_montage_stage.draw_rect(Rect2(94.0, bar_y, 2.0, 2.0), Color("#ffdfb5"))
				# Anilhas duplas nas duas pontas da barra.
				for side_x: float in [76.0, 103.0]:
					_montage_stage.draw_rect(Rect2(side_x, bar_y - 3.0, 3.0, 9.0), Retro.INK)
					_montage_stage.draw_rect(Rect2(side_x + 1.0, bar_y - 2.0, 1.0, 7.0), Color("#6c7d94"))
				for outer_x: float in [74.0, 106.0]:
					_montage_stage.draw_rect(Rect2(outer_x, bar_y - 2.0, 2.0, 7.0), Retro.INK)
					_montage_stage.draw_rect(Rect2(outer_x, bar_y - 1.0, 1.0, 5.0), Color("#4a566e"))
				# Haltere firme na mão do colega (x=132..134 em sporty_buddy espelhado em 122, 48).
				var mate_y: float = roundf(66.0 - curl_t * 2.0)
				_montage_stage.draw_rect(Rect2(130.0, mate_y, 7.0, 3.0), Retro.INK)
				_montage_stage.draw_rect(Rect2(131.0, mate_y + 1.0, 1.0, 1.0), Color("#6c7d94"))
				_montage_stage.draw_rect(Rect2(133.0, mate_y + 1.0, 1.0, 1.0), Color("#ffd3a1"))
				_montage_stage.draw_rect(Rect2(135.0, mate_y + 1.0, 1.0, 1.0), Color("#6c7d94"))
			5:
				for z_idx: int in range(3):
					var t: float = fmod(_elapsed * 0.55 + float(z_idx) * 0.33, 1.0)
					var zx: float = 42.0 + float(z_idx) * 6.0 + t * 8.0
					var zy: float = 38.0 - t * 18.0
					var zcol: Color = Color(0.65, 0.96, 0.92, sin(t * PI) * 0.85)
					_montage_stage.draw_rect(Rect2(roundf(zx), roundf(zy), 4, 1), zcol)
					_montage_stage.draw_rect(Rect2(roundf(zx + 2), roundf(zy + 1), 1, 1), zcol)
					_montage_stage.draw_rect(Rect2(roundf(zx), roundf(zy + 2), 4, 1), zcol)
		return

	match _scene_idx:
		0:
			var shake_x: float = roundf(beat * 1.4)
			_montage_stage.draw_rect(Rect2(117 + shake_x, 45, 14, 11), Retro.INK)
			_montage_stage.draw_rect(Rect2(118 + shake_x, 46, 12, 9), Color("#d64256"))
			_montage_stage.draw_rect(Rect2(120 + shake_x, 48, 8, 5), Color("#181322"))
			_montage_stage.draw_rect(Rect2(121 + shake_x, 49, 6, 3),
					Color("#ff98a4" if beat > 0.0 else "#ffe091"))
			if beat > 0.15:
				_montage_stage.draw_rect(Rect2(113, 42, 3, 2), Color("#ffd38a"))
				_montage_stage.draw_rect(Rect2(132, 42, 3, 2), Color("#ffd38a"))
		1, 4:
			var is_night: bool = _scene_idx == 4
			var speed: float = 82.0 if is_night else 64.0
			var scroll: float = fmod(_elapsed * speed, 224.0)
			for pane: Vector2i in [Vector2i(9, 63), Vector2i(75, 131), Vector2i(143, 197)]:
				for idx: int in range(5):
					var px: float = fposmod(float(idx) * 46.0 - scroll, 224.0) - 8.0
					if px >= float(pane.x) and px + 2.0 <= float(pane.y):
						if is_night:
							_montage_stage.draw_rect(Rect2(roundf(px), 23, 3, 2), Color("#ffd275"))
							_montage_stage.draw_rect(Rect2(roundf(px) - 2, 43, 6, 1), Color(1.0, 0.42, 0.42, 0.55))
						else:
							_montage_stage.draw_rect(Rect2(roundf(px), 22, 6, 2), Color(1.0, 1.0, 1.0, 0.35))
				if is_night and _cycle >= 1:
					for drop: int in range(5):
						var rx: float = float(pane.x) + fmod(float(drop) * 13.0 + _elapsed * 32.0, float(pane.y - pane.x - 2))
						var ry: float = 19.0 + fmod(float(drop) * 9.0 + _elapsed * 58.0, 34.0)
						_montage_stage.draw_rect(Rect2(roundf(rx), roundf(ry), 1, 3), Color(0.62, 0.78, 0.98, 0.48))
			for strap_x: int in range(28, 190, 32):
				var sway: float = roundf(sin(_elapsed * 5.0 + float(strap_x)) * 2.0)
				_montage_stage.draw_rect(Rect2(strap_x, 14 + jitter_y, 2, 7), Color("#c48f31"))
				_montage_stage.draw_rect(Rect2(strap_x - 2 + sway, 21 + jitter_y, 6, 5), Color("#f4cf6e"))
		2:
			var paper_count: int = 1 + _cycle * 4
			for paper: int in range(paper_count):
				_montage_stage.draw_rect(Rect2(142, 63 - paper * 2, 18, 2),
						Color("#faf0dd") if paper % 2 == 0 else Color("#d2c4b4"))
		3:
			_montage_stage.draw_rect(Rect2(128, 57, 10, 6), Retro.INK)
			_montage_stage.draw_rect(Rect2(129, 58, 8, 4), Color("#26293d"))
			if _cycle > 0 and fmod(_elapsed, 0.5) < 0.25:
				_montage_stage.draw_rect(Rect2(130, 54, 6, 3), Color("#ff6e84"))
		5:
			if _cycle >= 1:
				_montage_stage.draw_rect(Rect2(32, 49, 2, 2), Retro.INK)
				_montage_stage.draw_rect(Rect2(37, 49, 2, 2), Retro.INK)
			if _cycle == 2:
				_montage_stage.draw_rect(Rect2(31, 51, 8, 1), Color("#6e497a"))

	if _cycle > 0:
		var shade_alpha: float = 0.14 if _cycle == 1 else 0.28
		_montage_stage.draw_rect(Rect2(0, 0, W, H), Color(0.06, 0.04, 0.12, shade_alpha))
		if _cycle == 2 and beat > 0.2:
			_montage_stage.draw_rect(Rect2(0, 0, W, 3), Color(0.75, 0.22, 0.32, 0.28))
			_montage_stage.draw_rect(Rect2(0, H - 3, W, 3), Color(0.75, 0.22, 0.32, 0.28))


func _draw_portrait_face() -> void:
	var frame_idx: int = 3 if _phase == Phase.HAPPY_MONTAGE else _cycle
	var tremor_x: float = roundf(sin(_elapsed * 26.0)) if (_phase == Phase.MONTAGE and _cycle == 2) else 0.0
	var bg_top: Array[Color] = [Color("#181930"), Color("#1f162b"), Color("#1a1021"), Color("#20344d")]
	var bg_bot: Array[Color] = [Color("#292b4a"), Color("#33223b"), Color("#2d182b"), Color("#3a5975")]
	var halo_cols: Array[Color] = [Color(0.55, 0.78, 0.96, 0.14), Color(0.92, 0.68, 0.44, 0.12), Color(0.84, 0.28, 0.42, 0.14), Color(1.0, 0.88, 0.56, 0.22)]
	_portrait_stage.draw_rect(Rect2(0, 0, 48, 25), bg_top[frame_idx])
	_portrait_stage.draw_rect(Rect2(0, 25, 48, 23), bg_bot[frame_idx])
	_portrait_stage.draw_circle(Vector2(24, 21), 18.0, halo_cols[frame_idx])
	_portrait_stage.draw_rect(Rect2(1, 1, 46, 1), Color(1, 1, 1, 0.10))

	var src := Rect2(float(frame_idx * 48), 0.0, 48.0, 48.0)
	_portrait_stage.draw_texture_rect_region(PORTRAITS_TEX, Rect2(tremor_x, 0.0, 48.0, 48.0), src)
	if fmod(_elapsed, 3.2) > 3.04:
		var droop: int = 0 if frame_idx in [0, 3] else (1 if frame_idx == 1 else 2)
		var ey: float = 19.0 + float(droop)
		var lid_col: Color = Color("#ffd9b3") if frame_idx == 3 else Color("#dfb096")
		_portrait_stage.draw_rect(Rect2(16.0 + tremor_x, ey, 5.0, 3.0), lid_col)
		_portrait_stage.draw_rect(Rect2(27.0 + tremor_x, ey, 5.0, 3.0), lid_col)
		_portrait_stage.draw_rect(Rect2(16.0 + tremor_x, ey + 2.0, 5.0, 1.0), Retro.INK)
		_portrait_stage.draw_rect(Rect2(27.0 + tremor_x, ey + 2.0, 5.0, 1.0), Retro.INK)


func _draw_console_scene() -> void:
	const W: float = 282.0
	const H: float = 116.0
	_console_stage.draw_texture_rect(CONSOLE_TEX, Rect2(0, 0, W, H), false)

	var tv_rect: Rect2 = Rect2(185, 27, 40, 30)
	var tv_center: Vector2 = tv_rect.get_center()

	if _phase == Phase.CONSOLE_EXIT:
		var student_pos: Vector2 = Vector2(78, 74)
		var pose_frame: int = 1
		if _console_step == 0:
			var emerge: float = clampf(_console_elapsed / 1.9, 0.0, 1.0)
			student_pos = tv_center.lerp(Vector2(78, 74), 1.0 - pow(1.0 - emerge, 2.0))
			_console_stage.draw_texture_rect(ROOM_MORNING_TEX, tv_rect, false, Color("#d4fff8"))
			for ring: int in range(5):
				var phase: float = fmod(_console_elapsed * 1.7 + float(ring) * 0.2, 1.0)
				var radius: float = lerpf(8.0, 74.0, phase)
				var ring_col: Color = Retro.GOLD if ring % 2 == 0 else Retro.MINT
				ring_col.a = sin(phase * PI) * (1.0 - emerge * 0.5) * 0.85
				_console_stage.draw_arc(tv_center, radius, 0.0, TAU, 32, ring_col, 2.0)
			_console_stage.draw_colored_polygon(PackedVector2Array([
				Vector2(185, 27), Vector2(185, 57), Vector2(44, 108), Vector2(44, 44),
			]), Color(0.58, 0.96, 0.92, (1.0 - emerge * 0.65) * 0.25))
		elif _console_step == 1:
			pose_frame = 0
			_console_stage.draw_rect(tv_rect, Color("#151a26"))
			_console_stage.draw_colored_polygon(PackedVector2Array([
				Vector2(20, 14), Vector2(68, 14), Vector2(150, 114), Vector2(12, 114),
			]), Color(0.95, 0.84, 0.58, 0.12))
		else:
			pose_frame = 3
			_console_stage.draw_rect(tv_rect, Color("#151a26"))
			var sun_alpha: float = clampf(0.16 + _console_elapsed * 0.04, 0.16, 0.28)
			_console_stage.draw_rect(Rect2(20, 14, 48, 34), Color(0.55, 0.80, 0.96, 0.45))
			_console_stage.draw_colored_polygon(PackedVector2Array([
				Vector2(20, 14), Vector2(68, 14), Vector2(170, 116), Vector2(10, 116),
			]), Color(1.0, 0.90, 0.58, sun_alpha))
			_console_stage.draw_circle(student_pos + Vector2(6, 0), 16.0, Color(0.56, 1.0, 0.86, 0.24))

		_console_stage.draw_texture_rect_region(
				STUDENT_CUTSCENE_SHEET,
				Rect2((student_pos - Vector2(16.0, 18.0)).round(), Vector2(32, 32)),
				Rect2(pose_frame * 32, 0, 32, 32)
		)
		return

	if _console_step >= 1:
		# Tela CRT liga exibindo miniatura da Sala da Manhã + scanlines + LED verde.
		_console_stage.draw_texture_rect(ROOM_MORNING_TEX, tv_rect, false, Color("#d4fff8"))
		for sy: int in range(int(tv_rect.position.y), int(tv_rect.end.y), 3):
			_console_stage.draw_rect(Rect2(tv_rect.position.x, float(sy), tv_rect.size.x, 1),
					Color(0.05, 0.08, 0.14, 0.28))
		_console_stage.draw_rect(Rect2(249, 60, 2, 2), Color("#70ffae"))
		var glow_strength: float = 0.22 if _console_step == 1 else clampf(0.24 + _console_elapsed * 0.24, 0.24, 0.65)
		_console_stage.draw_colored_polygon(PackedVector2Array([
			Vector2(185, 27), Vector2(185, 57), Vector2(40, 108), Vector2(40, 44),
		]), Color(0.45, 0.94, 0.96, glow_strength * 0.35))

	var student_pos: Vector2 = Vector2(78, 74)
	if _console_step == 2:
		var pull: float = clampf(_console_elapsed / 2.2, 0.0, 1.0)
		student_pos = student_pos.lerp(tv_center, pull * pull)
		for ring: int in range(5):
			var phase: float = fmod(_console_elapsed * 1.9 + float(ring) * 0.2, 1.0)
			var radius: float = lerpf(6.0, 72.0, phase)
			var ring_col: Color = Retro.MINT if ring % 2 == 0 else Retro.GOLD
			ring_col.a = sin(phase * PI) * 0.85
			_console_stage.draw_arc(tv_center, radius, 0.0, TAU, 32, ring_col, 2.0)
		for mote: int in range(12):
			var t: float = fmod(_console_elapsed * 2.4 + float(mote) / 12.0, 1.0)
			var start_p: Vector2 = Vector2(46.0 + float(mote % 4) * 18.0, 44.0 + float((mote * 6) % 56))
			var mp: Vector2 = start_p.lerp(tv_center, t).round()
			_console_stage.draw_rect(Rect2(mp, Vector2(2, 2)), Color(0.75, 1.0, 0.95, 1.0 - t * 0.4))

	_console_stage.draw_texture_rect_region(
			STUDENT_CUTSCENE_SHEET,
			Rect2((student_pos - Vector2(16.0, 18.0)).round(), Vector2(32, 32)),
			Rect2(32 if _console_step == 0 else 64, 0, 32, 32)
	)
	_console_stage.draw_rect(Rect2(roundf(student_pos.x + 8.0), roundf(student_pos.y + 3.0), 8, 4),
			Color("#2c3448"))
	_console_stage.draw_rect(Rect2(roundf(student_pos.x + 13.0), roundf(student_pos.y + 4.0), 2, 2),
			Color("#e55a74"))
	if _console_step == 2:
		_console_stage.draw_circle(student_pos, 14.0,
				Color(0.55, 1.0, 0.96, clampf(_console_elapsed * 0.35, 0.0, 0.52)))

	if _console_step == 2 and _console_elapsed > 1.7:
		var flash: float = clampf((_console_elapsed - 1.7) / 0.65, 0.0, 1.0)
		_console_stage.draw_rect(Rect2(0, 0, W, H), Color(0.84, 1.0, 0.98, flash))


func _draw_ending_scene() -> void:
	const W: float = 320.0
	const H: float = 180.0
	_ending_stage.draw_texture_rect(DAWN_TEX, Rect2(0, 0, W, H), false)

	var pulse: float = 0.5 + 0.5 * sin(_elapsed * 2.0)
	var sun_center: Vector2 = Vector2(252, 118)
	for radius: float in [42.0, 26.0, 15.0]:
		_ending_stage.draw_circle(sun_center, radius, Color(1.0, 0.88, 0.62, 0.10 + pulse * 0.04))
	_ending_stage.draw_circle(sun_center, 8.0, Color("#fff3cf"))

	# Pequeno pássaro da esperança em pixel art contornada sobre o galho direito.
	var bob: float = roundf(sin(_elapsed * 3.2) * 0.8)
	var bx: float = 268.0
	var by: float = 71.0 + bob
	_ending_stage.draw_rect(Rect2(bx + 3, 81, 1, 3), Color("#d48a46"))
	_ending_stage.draw_rect(Rect2(bx + 6, 81, 1, 3), Color("#d48a46"))
	_ending_stage.draw_rect(Rect2(bx - 1, by + 2, 13, 10), Retro.INK)
	_ending_stage.draw_rect(Rect2(bx - 2, by - 1, 9, 7), Retro.INK)
	_ending_stage.draw_rect(Rect2(bx, by + 3, 11, 8), Color("#63b8d9"))
	_ending_stage.draw_rect(Rect2(bx + 9, by + 6, 6, 3), Color("#417fa1"))
	_ending_stage.draw_rect(Rect2(bx + 1, by + 6, 5, 4), Color("#f6c580"))
	_ending_stage.draw_rect(Rect2(bx + 4, by + 4, 6, 4), Color("#8fe6f5"))
	_ending_stage.draw_rect(Rect2(bx - 1, by, 7, 6), Color("#73cbe8"))
	_ending_stage.draw_rect(Rect2(bx - 4, by + 2, 3, 2), Color("#f4ba72"))
	if fmod(_elapsed, 3.6) < 3.45:
		_ending_stage.draw_rect(Rect2(bx + 1, by + 2, 1, 1), Retro.INK)

	for seed_vec: Vector3 in _feather_seeds:
		var t: float = fposmod(_elapsed * 0.08 + seed_vec.z * 0.1, 1.0)
		var px: float = fposmod(seed_vec.x + sin(_elapsed * 1.4 + seed_vec.z) * 8.0, W)
		var py: float = H - t * (H + 10.0)
		var alpha: float = sin(t * PI) * 0.72
		var pcol: Color = Color("#ffe7a6" if int(seed_vec.z * 10.0) % 2 == 0 else "#a8f3e4")
		pcol.a = alpha
		_ending_stage.draw_rect(Rect2(roundf(px), roundf(py), 2, 1), pcol)
		_ending_stage.draw_rect(Rect2(roundf(px + 1.0), roundf(py - 1.0), 1, 2), pcol)
