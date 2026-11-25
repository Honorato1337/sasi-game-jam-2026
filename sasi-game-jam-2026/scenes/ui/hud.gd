extends CanvasLayer

const Retro = preload("res://scenes/ui/retro_window.gd")
const Player = preload("res://scenes/player/player.gd")
const TURNS: Array[String] = ["MANHÃ", "TARDE", "NOITE"]
const NAMES: Array[String] = ["HP", "CORPO", "MENTE", "DESCANSO"]
const COLORS: Array[Color] = [Color("#ff8998"), Retro.MINT, Color("#8de5ff"), Color("#ffe091")]
const VIGNETTE_STRENGTH: Array[float] = [0.0, 0.28, 0.58]
const VIGNETTE_SHADER: String = """
shader_type canvas_item;
uniform float strength = 0.0;

void fragment() {
	vec2 pixel_uv = (floor(UV * vec2(320.0, 180.0)) + 0.5) / vec2(320.0, 180.0);
	vec2 offset = abs(pixel_uv - vec2(0.5)) * 2.0;
	float edge = smoothstep(0.36, 1.0, length(offset));
	COLOR = vec4(0.035, 0.02, 0.06, edge * strength);
}
"""

var _meters: Array[ProgressBar] = []
var _names: Array[Label] = []
var _alert: Label
var _room: Label
var _objective: Label
var _score: Label
var _ally: Label
var _breathing: Panel
var _breath: ProgressBar
var _clarity: Panel
var _vignette: ShaderMaterial
var _transition_veil: ColorRect
var _banner_box: Panel
var _banner_lbl: Label
var _banner_timer: float = 0.0
var _player_ref: Player
var _pulse: float


func _ready() -> void:
	var shade: ColorRect = Retro.block(self, Rect2(0, 0, 640, 360), Color.WHITE)
	var shader: Shader = Shader.new()
	shader.code = VIGNETTE_SHADER
	_vignette = ShaderMaterial.new()
	_vignette.shader = shader
	shade.material = _vignette

	_transition_veil = Retro.block(self, Rect2(0, 0, 640, 360), Color(0.06, 0.04, 0.11, 0.0))
	_transition_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vitals: Panel = Retro.panel(self, Rect2(8, 8, 192, 82), true)
	for index: int in range(NAMES.size()):
		var y: int = 6 + index * 14
		_names.append(Retro.label(vitals, Rect2(8, y, 90, 14), NAMES[index], 10, COLORS[index]))
		_meters.append(Retro.meter(vitals, Rect2(100, y + 4, 84, 6), COLORS[index]))
	_alert = Retro.label(vitals, Rect2(8, 63, 176, 13), "", 10, Color("#ff9aab"))

	var info: Panel = Retro.panel(self, Rect2(404, 8, 228, 72), true)
	_room = Retro.label(info, Rect2(9, 6, 210, 14), "", 10, Retro.CREAM)
	Retro.divider(info, Rect2(9, 22, 210, 1))
	_objective = Retro.label(info, Rect2(9, 25, 210, 14), "", 10, Retro.GOLD)
	_score = Retro.label(info, Rect2(9, 39, 210, 14), "", 10, Retro.MUTED)
	_ally = Retro.label(info, Rect2(9, 53, 210, 14), "", 10, Retro.CREAM)

	var survival_panel: Panel = Retro.panel(self, Rect2(214, 8, 176, 28), true)
	survival_panel.name = "SurvivalBox"
	var survival_lbl: Label = Retro.label(survival_panel, Rect2(8, 3, 160, 13), "TURNO • 28s",
			10, Retro.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	var survival_bar: ProgressBar = Retro.meter(survival_panel, Rect2(10, 18, 156, 5), Retro.GOLD)
	survival_bar.max_value = 28.0
	survival_panel.hide()
	set_meta(&"_survival_panel", survival_panel)
	set_meta(&"_survival_lbl", survival_lbl)
	set_meta(&"_survival_bar", survival_bar)

	_banner_box = Retro.panel(self, Rect2(190, 94, 260, 24), true)
	_banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_lbl = Retro.label(_banner_box, Rect2(8, 4, 244, 16), "", 10, Retro.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_banner_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_box.hide()

	_breathing = Retro.panel(self, Rect2(8, 320, 174, 32), true)
	Retro.label(_breathing, Rect2(8, 4, 158, 14), "Segure [R] Respirar", 10)
	_breath = Retro.meter(_breathing, Rect2(8, 21, 158, 5), Retro.MINT)
	_breath.max_value = 1.0
	_clarity = Retro.panel(self, Rect2(342, 320, 290, 32), true, true)
	Retro.label(_clarity, Rect2(8, 8, 274, 16), "GOLPE DE CLAREZA PRONTO [ESPAÇO/CLIQUE]",
			10, Retro.GOLD, HORIZONTAL_ALIGNMENT_CENTER)

	GameManager.state_changed.connect(_on_state_changed)
	GameManager.hp_changed.connect(_on_hp_changed)
	GameManager.pillars_changed.connect(_on_pillars_changed)
	GameManager.room_changed.connect(_on_room_changed)
	GameManager.respite_changed.connect(_on_respite_changed)
	GameManager.mind_state_changed.connect(_on_mind_state_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.combo_changed.connect(_on_combo_changed)
	GameManager.ally_activated.connect(_on_ally_activated)
	GameManager.habits_updated.connect(_on_habits_updated)
	GameManager.clarity_ready_changed.connect(_on_clarity_ready_changed)
	_on_hp_changed(GameManager.hp, GameManager.max_hp)
	_on_pillars_changed(GameManager.body, GameManager.mind, GameManager.rest)
	_on_room_changed(GameManager.room)
	_on_mind_state_changed(GameManager.mind_state)
	_on_score_changed(GameManager.score)
	_on_ally_activated(GameManager.ally_active)
	_on_state_changed(GameManager.current_state)


func bind_player(player: Player) -> void:
	_player_ref = player
	player.breathing_progressed.connect(_on_breathing_progressed)


func set_objective(message: String) -> void:
	_objective.text = message


func set_survival_status(active: bool, remaining: float = 0.0, duration: float = 28.0) -> void:
	var panel: Panel = get_meta(&"_survival_panel") as Panel
	var lbl: Label = get_meta(&"_survival_lbl") as Label
	var bar: ProgressBar = get_meta(&"_survival_bar") as ProgressBar
	set_meta(&"_survival_active", active)
	if panel == null:
		return
	panel.visible = active and GameManager.current_state in [
			GameManager.GameState.PLAYING, GameManager.GameState.DIALOGUE, GameManager.GameState.PAUSED]
	if active:
		lbl.text = "TURNO • %02ds" % maxi(0, ceili(remaining))
		lbl.add_theme_color_override(&"font_color", Color("#ff8998") if remaining <= 6.0 else Retro.GOLD)
		bar.max_value = maxf(1.0, duration)
		bar.value = clampf(remaining, 0.0, duration)


func is_survival_hud_visible() -> bool:
	var panel: Panel = get_meta(&"_survival_panel", null) as Panel
	return panel != null and panel.visible


func _on_state_changed(state: GameManager.GameState) -> void:
	visible = state in [GameManager.GameState.PLAYING, GameManager.GameState.DIALOGUE, GameManager.GameState.PAUSED]
	_breathing.visible = state != GameManager.GameState.DIALOGUE
	var panel: Panel = get_meta(&"_survival_panel", null) as Panel
	if panel != null:
		panel.visible = bool(get_meta(&"_survival_active", false)) and visible
	_on_clarity_ready_changed(GameManager.clarity_ready)


func _on_clarity_ready_changed(ready: bool) -> void:
	_clarity.visible = ready and GameManager.current_state != GameManager.GameState.DIALOGUE


func _on_hp_changed(current: int, maximum: int) -> void:
	_meters[0].max_value = maximum
	_meters[0].value = current
	_names[0].text = "HP %d/%d" % [current, maximum]


func _on_pillars_changed(body: float, mind: float, rest: float) -> void:
	var values: Array[float] = [body, mind, rest]
	for index: int in range(values.size()):
		var row: int = index + 1
		_meters[row].value = values[index]
		_names[row].text = "%s %d%%" % [NAMES[row], floori(values[index])]


func _on_respite_changed(_active: bool) -> void:
	_on_room_changed(GameManager.room)


func _on_room_changed(_room_index: int) -> void:
	if GameManager.in_respite_room:
		_room.text = "INTERLÚDIO %d/2 • RESPIRO" % GameManager.get_cycle()
	else:
		_room.text = "CICLO %d/3 • %s" % [GameManager.get_cycle(), TURNS[GameManager.get_turn() - 1]]


func _on_mind_state_changed(state: GameManager.MindState) -> void:
	_vignette.set_shader_parameter(&"strength", VIGNETTE_STRENGTH[state])


func _on_score_changed(score: int) -> void:
	var focus_tag: String = " [FOCO+]" if GameManager.combo >= 3 else ""
	_score.text = "Score %d   •   Combo x%d%s" % [score, maxi(1, GameManager.combo), focus_tag]
	_score.add_theme_color_override(&"font_color", Retro.GOLD if GameManager.combo >= 3 else Retro.MUTED)


func _on_combo_changed(_combo: int) -> void:
	_on_score_changed(GameManager.score)


func _refresh_ally_status() -> void:
	var status: String = "Apoio: ATIVO" if GameManager.ally_active else "Apoio: Sozinho"
	if GameManager.sleep_rank + GameManager.nutrition_rank + GameManager.ally_count > 0:
		status += "  •  S%d N%d R%d" % [GameManager.sleep_rank, GameManager.nutrition_rank, GameManager.ally_count]
	_ally.text = status
	_ally.modulate = Retro.MINT if GameManager.ally_active else Color.WHITE


func _on_ally_activated(_active: bool) -> void:
	_refresh_ally_status()


func _on_habits_updated(_sleep_rank: int, _nutrition_rank: int, _ally_count: int) -> void:
	_refresh_ally_status()


func show_room_transition(banner_text: String) -> void:
	if not is_inside_tree():
		return
	_transition_veil.color.a = 0.36
	if banner_text.is_empty():
		_banner_box.hide()
		_banner_timer = 0.0
		return
	_banner_lbl.text = banner_text
	_banner_box.modulate.a = 1.0
	_banner_box.show()
	_banner_timer = 1.85


func _on_breathing_progressed(progress: float, _breathing: bool) -> void:
	_breath.value = progress


func _process(delta: float) -> void:
	if not visible:
		return
	if _transition_veil != null and _transition_veil.color.a > 0.0:
		_transition_veil.color.a = maxf(0.0, _transition_veil.color.a - delta * 0.95)
	if _banner_timer > 0.0:
		if GameManager.current_state not in [GameManager.GameState.PLAYING, GameManager.GameState.DIALOGUE]:
			_banner_timer = 0.0
			_banner_box.hide()
		else:
			_banner_timer = maxf(0.0, _banner_timer - delta)
			_banner_box.modulate.a = clampf(_banner_timer / 0.45, 0.0, 1.0)
			if _banner_timer == 0.0:
				_banner_box.hide()
	_pulse = fposmod(_pulse + delta, 2.0)
	var blink: bool = fmod(_pulse, 0.6) < 0.3
	var low: bool = false
	for row: int in range(1, _meters.size()):
		var critical: bool = _meters[row].value < 40.0
		low = low or critical
		_meters[row].modulate.a = 0.45 if critical and blink else 1.0
		_names[row].modulate = Color("#ff8c9d") if critical and blink else Color.WHITE
	var status_msg: String = ""
	var slowed: bool = is_instance_valid(_player_ref) and _player_ref.has_slow_debuff()
	if GameManager.is_exhausted:
		status_msg = "OFEGANTE! [R]"
	elif GameManager.mind_state == GameManager.MindState.OVERLOAD:
		status_msg = "SOBRECARGA • LENTO"
	elif GameManager.body < 40.0:
		status_msg = "CORPO FRACO • DANO -"
	elif GameManager.mind_state == GameManager.MindState.ANXIOUS:
		status_msg = "ANSIOSO • ATAQUE -"
	elif slowed:
		status_msg = "LENTIDÃO"
	elif low:
		status_msg = "PILAR BAIXO"
	_alert.text = status_msg
	_alert.modulate.a = 1.0 if blink else 0.62
	var glow: float = 1.03 + 0.16 * sin(_pulse * TAU)
	_clarity.modulate = Color(glow, glow, 1.0)
