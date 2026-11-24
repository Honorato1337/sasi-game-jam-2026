extends CanvasLayer

const Retro = preload("res://scenes/ui/retro_window.gd")
const Player = preload("res://scenes/player/player.gd")
const SIGNAL_NAMES: Array[String] = ["CALMO", "ALERTA", "SOBRECARGA", "EXAUSTO"]
const SIGNAL_COLORS: Array[Color] = [
	Color("#81e6c0"), Color("#f4ba72"), Color("#ec626a"), Color("#e892ca"),
]
const TURNS: Array[String] = ["MANHÃ", "TARDE", "NOITE", "MADRUGADA"]
const HEART: Array[String] = [
	".##.##.", "#######", "#######", ".#####.", "..###..", "...#...",
]
const VIGNETTE_SHADER: String = """
shader_type canvas_item;
uniform float strength = 0.0;

void fragment() {
	vec2 pixel_uv = (floor(UV * vec2(320.0, 180.0)) + 0.5) / vec2(320.0, 180.0);
	vec2 offset = abs(pixel_uv - vec2(0.5)) * 2.0;
	float edge = smoothstep(0.47, 0.98, length(offset));
	COLOR = vec4(0.09, 0.055, 0.12, edge * strength);
}
"""

var _bpm_label: Label
var _signal_badge: Label
var _badge_background: ColorRect
var _hp_label: Label
var _habits_label: Label
var _wave_label: Label
var _timer_label: Label
var _clarity_badge: Panel
var _health: ProgressBar
var _breath: ProgressBar
var _heart: Control
var _vignette: ShaderMaterial
var _beat_phase: float = 0.0
var _pulse_time: float = 0.0


func _ready() -> void:
	var shade: ColorRect = Retro.block(self, Rect2(0, 0, 640, 360), Color.WHITE)
	var shader: Shader = Shader.new()
	shader.code = VIGNETTE_SHADER
	_vignette = ShaderMaterial.new()
	_vignette.shader = shader
	shade.material = _vignette

	var monitor: Panel = Retro.window(self, Rect2(8, 8, 151, 59), "SINAIS")
	_heart = Control.new()
	_heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Retro.place(_heart, monitor, Rect2(8, 24, 32, 29))
	_heart.draw.connect(_draw_heart)
	_bpm_label = Retro.label(monitor, Rect2(47, 21, 97, 19), "", 15)
	_badge_background = Retro.block(monitor, Rect2(47, 41, 96, 13), Retro.MINT)
	_signal_badge = Retro.label(monitor, Rect2(47, 40, 96, 15), "", 10,
			Retro.INK, HORIZONTAL_ALIGNMENT_CENTER)

	var clock: Panel = Retro.window(self, Rect2(246, 8, 148, 58), "TURNO")
	_wave_label = Retro.label(clock, Rect2(4, 20, 140, 17), "", 11,
			Retro.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	_timer_label = Retro.label(clock, Rect2(4, 35, 140, 19), "", 15,
			Retro.GOLD, HORIZONTAL_ALIGNMENT_CENTER)

	var core: Panel = Retro.window(self, Rect2(446, 8, 182, 62), "NÚCLEO DO LAR")
	_hp_label = Retro.label(core, Rect2(8, 20, 166, 15), "", 11)
	_health = Retro.meter(core, Rect2(8, 36, 166, 6), Retro.MINT)
	_habits_label = Retro.label(core, Rect2(8, 43, 166, 15), "", 10, Retro.MUTED)

	var breathing: Panel = Retro.window(self, Rect2(8, 304, 185, 47), "FÔLEGO")
	Retro.label(breathing, Rect2(8, 21, 169, 15), "Segure [R] Respirar", 11)
	_breath = Retro.meter(breathing, Rect2(8, 37, 169, 5), Retro.MINT)

	_clarity_badge = Retro.window(self, Rect2(300, 304, 328, 47), "EQUILÍBRIO")
	Retro.label(_clarity_badge, Rect2(8, 22, 312, 19),
			"GOLPE DE CLAREZA PRONTO [ESPAÇO/CLIQUE]", 12, Retro.GOLD, HORIZONTAL_ALIGNMENT_CENTER)

	GameManager.state_changed.connect(_on_state_changed)
	GameManager.bpm_changed.connect(_on_bpm_changed)
	GameManager.core_hp_changed.connect(_on_core_hp_changed)
	GameManager.habits_updated.connect(_on_habits_updated)
	GameManager.clarity_ready_changed.connect(_on_clarity_ready_changed)
	_on_state_changed(GameManager.current_state)
	_on_bpm_changed(GameManager.bpm, GameManager.signal_level)
	_on_core_hp_changed(GameManager.core_hp, GameManager.max_core_hp)
	_on_habits_updated(GameManager.sleep_rank, GameManager.nutrition_rank, GameManager.ally_count)
	_on_clarity_ready_changed(GameManager.clarity_ready)


func bind_player(player: Player) -> void:
	player.breathing_progressed.connect(_on_breathing_progressed)


func update_wave(time_left: float, wave: int) -> void:
	_wave_label.text = "%d/%d %s" % [wave, GameManager.MAX_WAVES, TURNS[wave - 1]]
	_timer_label.text = "%ds" % ceili(time_left)


func _process(delta: float) -> void:
	if not visible:
		return
	_beat_phase = fposmod(_beat_phase + delta * GameManager.bpm / 60.0, 1.0)
	_pulse_time = fposmod(_pulse_time + delta * TAU * 2.0, TAU)
	_heart.queue_redraw()
	_update_vignette()
	if _clarity_badge.visible:
		var glow: float = 0.93 + 0.07 * cos(_pulse_time)
		_clarity_badge.modulate = Color(glow, glow, glow)


func _draw_heart() -> void:
	var pixel_size: int = 4 if _beat_phase < 0.20 else 3
	var origin: Vector2 = ((_heart.size - Vector2(7, 6) * pixel_size) / 2.0).floor()
	var color: Color = SIGNAL_COLORS[GameManager.signal_level]
	for y: int in range(HEART.size()):
		var row: String = HEART[y]
		for x: int in range(row.length()):
			if row[x] == "#":
				var tone: Color = color.lightened(0.35) if y == 1 and x == 1 else color
				_heart.draw_rect(Rect2(origin + Vector2(x, y) * pixel_size,
						Vector2.ONE * pixel_size), tone)


func _update_vignette() -> void:
	var strength: float = 0.0
	match GameManager.signal_level:
		GameManager.SignalLevel.WARNING:
			strength = 0.25
		GameManager.SignalLevel.OVERLOAD:
			strength = 0.55
		GameManager.SignalLevel.EXHAUSTED:
			strength = 0.65 + 0.05 * cos(_pulse_time)
	_vignette.set_shader_parameter(&"strength", strength)


func _on_state_changed(state: GameManager.GameState) -> void:
	visible = state == GameManager.GameState.PLAYING
	if not visible:
		_breath.value = 0.0
		_beat_phase = 0.0
		_pulse_time = 0.0


func _on_bpm_changed(bpm: float, level: GameManager.SignalLevel) -> void:
	_bpm_label.text = "%d BPM" % floori(bpm)
	_signal_badge.text = SIGNAL_NAMES[level]
	_badge_background.color = SIGNAL_COLORS[level]
	_update_vignette()
	_heart.queue_redraw()


func _on_core_hp_changed(hp: int, max_hp: int) -> void:
	_hp_label.text = "%d / %d HP" % [hp, max_hp]
	_health.max_value = max_hp
	_health.value = hp


func _on_habits_updated(sleep_rank: int, nutrition_rank: int, allies: int) -> void:
	_habits_label.text = "Sono %d   Nutrição %d   Apoio %d" % [sleep_rank, nutrition_rank, allies]


func _on_breathing_progressed(progress: float, _is_breathing: bool) -> void:
	_breath.value = progress * 100.0


func _on_clarity_ready_changed(is_ready: bool) -> void:
	_clarity_badge.visible = is_ready
