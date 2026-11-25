extends Node2D

signal classmate_recruited

enum StationType { WATER_SNACK, REST_SPOT, ROOM_PILLAR, CLASSMATE_NPC }

const INTERACTION_RADIUS: float = 46.0
const CLASSMATE_SHEET = preload("res://assets/sprites/classmate_sheet.png")

@export var station_type: StationType = StationType.WATER_SNACK
@export_enum("CORPO", "MENTE", "DESCANSO") var pillar_name: String = "CORPO"

var _cooldown: float = 0.0
var _time: float = 0.0
var locked_by_wave: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _badge: Node2D = $Badge


func _ready() -> void:
	if station_type == StationType.CLASSMATE_NPC:
		_sprite.frame = 0
		_sprite.hframes = 2
		_sprite.texture = CLASSMATE_SHEET
		GameManager.ally_activated.connect(_update_npc_visibility)
		_update_npc_visibility(GameManager.ally_active)
	else:
		_sprite.frame = station_type
	_badge.draw.connect(_draw_badge)


func set_wave_locked(locked: bool) -> void:
	if locked_by_wave != locked:
		locked_by_wave = locked
		if is_instance_valid(_sprite):
			_sprite.modulate = Color(0.56, 0.60, 0.74, 0.88) if locked_by_wave else Color.WHITE
		queue_redraw()


func _physics_process(delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		_cooldown = maxf(0.0, _cooldown - delta)
		_time += delta
	if station_type == StationType.CLASSMATE_NPC:
		_sprite.frame = int(_time * 3.0) % 2
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	_badge.visible = is_instance_valid(player) and (
			global_position.distance_squared_to(player.global_position) <= INTERACTION_RADIUS * INTERACTION_RADIUS)
	_badge.queue_redraw()
	queue_redraw()


func can_interact() -> bool:
	return GameManager.current_state == GameManager.GameState.PLAYING and not locked_by_wave and _cooldown <= 0.0 and (
			station_type != StationType.CLASSMATE_NPC or not GameManager.ally_active)


func get_station_name() -> String:
	match station_type:
		StationType.WATER_SNACK: return "Água e Lanche"
		StationType.REST_SPOT: return "Canto de Pausa"
		StationType.CLASSMATE_NPC: return "Colega"
		_: return pillar_name


func interact(player: Node2D) -> String:
	if not can_interact() or global_position.distance_squared_to(player.global_position) > INTERACTION_RADIUS * INTERACTION_RADIUS:
		return ""
	match station_type:
		StationType.WATER_SNACK:
			_cooldown = 4.0
			GameManager.modify_body(45.0)
			GameManager.heal_player(15)
			return "+45 Corpo · +15 HP"
		StationType.REST_SPOT:
			_cooldown = 4.0
			GameManager.modify_rest(45.0)
			GameManager.modify_mind(22.0)
			GameManager.heal_player(8)
			return "+45 Descanso · +22 Mente · +8 HP"
		StationType.ROOM_PILLAR:
			_cooldown = 1.1
			match pillar_name:
				"CORPO": GameManager.modify_body(42.0)
				"MENTE": GameManager.modify_mind(42.0)
				"DESCANSO": GameManager.modify_rest(42.0)
			GameManager.heal_player(6)
			return "+42 " + pillar_name + " · +6 HP"
		StationType.CLASSMATE_NPC:
			GameManager.activate_ally()
			classmate_recruited.emit()
			return "Colega recrutado!"
	return ""


func _update_npc_visibility(active: bool) -> void:
	visible = not active


func _draw_badge() -> void:
	var prompt: String
	match station_type:
		StationType.WATER_SNACK: prompt = "[E] Beber Água"
		StationType.REST_SPOT: prompt = "[E] Descansar"
		StationType.CLASSMATE_NPC: prompt = "[E] Pedir Apoio"
		StationType.ROOM_PILLAR: prompt = "[E] Reacender " + pillar_name
	if locked_by_wave:
		prompt = "SELADO • Vença a 1ª leva"
	elif _cooldown > 0.0:
		prompt = "Aguarde %ds" % ceili(_cooldown)
	var font: Font = ThemeDB.fallback_font
	var width: float = ceilf(font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x)
	var origin := Vector2(-ceilf(width / 2.0), -38)
	var box := Rect2(origin - Vector2(5, 12), Vector2(width + 10, 17))
	var border_col: Color = Color("#e8758a") if locked_by_wave else Color("#e8b875")
	_badge.draw_rect(Rect2(box.position + Vector2(1, 0), box.size - Vector2(2, 0)), Color("#181322"))
	_badge.draw_rect(Rect2(box.position + Vector2(0, 1), box.size - Vector2(0, 2)), Color("#181322"))
	_badge.draw_rect(Rect2(box.position + Vector2(2, 1), Vector2(box.size.x - 4, 1)), border_col)
	_badge.draw_rect(Rect2(box.position + Vector2(2, box.size.y - 2), Vector2(box.size.x - 4, 1)), border_col)
	_badge.draw_rect(Rect2(box.position + Vector2(1, 2), Vector2(1, box.size.y - 4)), border_col)
	_badge.draw_rect(Rect2(box.position + Vector2(box.size.x - 2, 2), Vector2(1, box.size.y - 4)), border_col)
	_badge.draw_string(font, origin, prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#fff2ce"))


func _draw() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_time * 4.2)
	if station_type == StationType.ROOM_PILLAR:
		var level: float = GameManager.body
		var color := Color("#80f1a8")
		match pillar_name:
			"MENTE":
				level = GameManager.mind
				color = Color("#8de5ff")
			"DESCANSO":
				level = GameManager.rest
				color = Color("#ffe091")
		var p_pulse: float = 0.5 + 0.5 * sin(_time * 6.0)
		if level < 40.0:
			color = Color("#ff435b")
			p_pulse = 1.0 if fmod(_time, 0.42) < 0.21 else 0.12
		var center := Vector2(0, -24)
		draw_circle(center, 9.0 + roundf(4.0 * p_pulse), Color(color, 0.14 + p_pulse * 0.35))
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(0, -8), center + Vector2(6, 0),
			center + Vector2(0, 8), center + Vector2(-6, 0),
		]), Color(color, 0.55 + p_pulse * 0.45))
		return

	if station_type == StationType.CLASSMATE_NPC and not visible:
		return

	var base_color: Color = Color("#59e2f5")
	var tag_text: String = "ÁGUA"
	var bob: float = roundf(sin(_time * 3.5) * 1.5)
	var urgent: bool = false
	match station_type:
		StationType.WATER_SNACK:
			base_color = Color("#59e2f5")
			tag_text = "ÁGUA"
			urgent = GameManager.body < 55.0
		StationType.REST_SPOT:
			base_color = Color("#ffe091")
			tag_text = "DESCANSO"
			urgent = GameManager.rest < 65.0 or GameManager.mind < 60.0
		StationType.CLASSMATE_NPC:
			base_color = Color("#81e6c0")
			tag_text = "COLEGA"

	if locked_by_wave:
		draw_arc(Vector2(0, 10), 19.0 + pulse * 2.0, 0.0, TAU, 26, Color("#ff6f84", 0.55 + 0.30 * pulse), 2.0)
		if not _badge.visible:
			var font_lock: Font = ThemeDB.fallback_font
			var lock_txt: String = "SELADO"
			var ltw: float = ceilf(font_lock.get_string_size(lock_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x)
			var lpos := Vector2(-ceilf(ltw * 0.5), 22)
			var lpill := Rect2(lpos - Vector2(4, 9), Vector2(ltw + 8, 12))
			draw_rect(lpill, Color(0.14, 0.07, 0.14, 0.88))
			draw_rect(Rect2(lpill.position, Vector2(lpill.size.x, 1)), Color("#ff6f84", 0.85))
			draw_string(font_lock, lpos, lock_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#ff98a8"))
		return

	var aura_alpha: float = (0.34 if urgent else 0.18) + pulse * (0.28 if urgent else 0.14)
	draw_arc(Vector2(0, 10), 17.0 + pulse * 2.0, 0.0, TAU, 28, Color(base_color, aura_alpha), 1.5)

	if _cooldown <= 0.0:
		var marker_pos := Vector2(0, -34.0 + bob)
		if station_type == StationType.WATER_SNACK:
			# Gota de água ciano brilhante contornada acima da estação.
			draw_colored_polygon(PackedVector2Array([
				marker_pos + Vector2(0, -5), marker_pos + Vector2(4, 1),
				marker_pos + Vector2(2, 4), marker_pos + Vector2(-2, 4), marker_pos + Vector2(-4, 1),
			]), Color("#181224"))
			draw_colored_polygon(PackedVector2Array([
				marker_pos + Vector2(0, -4), marker_pos + Vector2(3, 1),
				marker_pos + Vector2(2, 3), marker_pos + Vector2(-2, 3), marker_pos + Vector2(-3, 1),
			]), Color("#7bf2ff"))
			draw_rect(Rect2(marker_pos + Vector2(-1, 0), Vector2(1, 2)), Color.WHITE)
		else:
			# Brilho dourado/menta suave acima do Descanso ou Colega.
			draw_circle(marker_pos, 4.5, Color(base_color, 0.28 + pulse * 0.25))
			draw_rect(Rect2(marker_pos - Vector2(2, 2), Vector2(4, 4)), Color("#181224"))
			draw_rect(Rect2(marker_pos - Vector2(1, 1), Vector2(2, 2)), base_color)

	if not _badge.visible and _cooldown <= 0.0:
		var font: Font = ThemeDB.fallback_font
		var tw: float = ceilf(font.get_string_size(tag_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x)
		var tag_pos := Vector2(-ceilf(tw * 0.5), 22)
		var pill := Rect2(tag_pos - Vector2(4, 9), Vector2(tw + 8, 12))
		draw_rect(pill, Color(0.09, 0.07, 0.14, 0.85))
		draw_rect(Rect2(pill.position, Vector2(pill.size.x, 1)), Color(base_color, 0.72))
		draw_string(font, tag_pos, tag_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, base_color)
