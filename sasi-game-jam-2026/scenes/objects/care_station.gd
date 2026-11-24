extends Node2D

signal classmate_recruited

enum StationType { WATER_SNACK, REST_SPOT, ROOM_PILLAR, CLASSMATE_NPC }

const INTERACTION_RADIUS: float = 46.0
const CLASSMATE_SHEET = preload("res://assets/sprites/classmate_sheet.png")

@export var station_type: StationType = StationType.WATER_SNACK
@export_enum("CORPO", "MENTE", "DESCANSO") var pillar_name: String = "CORPO"

var _cooldown: float = 0.0
var _time: float = 0.0

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
	if station_type == StationType.ROOM_PILLAR:
		queue_redraw()


func can_interact() -> bool:
	return GameManager.current_state == GameManager.GameState.PLAYING and _cooldown <= 0.0 and (
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
			_cooldown = 5.0
			GameManager.modify_body(45.0)
			GameManager.heal_player(10)
			return "+45 Corpo · +10 HP"
		StationType.REST_SPOT:
			_cooldown = 5.0
			GameManager.modify_rest(45.0)
			GameManager.modify_mind(20.0)
			return "+45 Descanso · +20 Mente"
		StationType.ROOM_PILLAR:
			_cooldown = 1.2
			match pillar_name:
				"CORPO": GameManager.modify_body(40.0)
				"MENTE": GameManager.modify_mind(40.0)
				"DESCANSO": GameManager.modify_rest(40.0)
			return "+40 " + pillar_name
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
		StationType.REST_SPOT: prompt = "[E] Pausar"
		StationType.CLASSMATE_NPC: prompt = "[E] Pedir Apoio"
		StationType.ROOM_PILLAR: prompt = "[E] Reacender " + pillar_name
	if _cooldown > 0.0:
		prompt = "Aguarde %ds" % ceili(_cooldown)
	var font: Font = ThemeDB.fallback_font
	var width: float = ceilf(font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x)
	var origin := Vector2(-ceilf(width / 2.0), -38)
	var box := Rect2(origin - Vector2(5, 12), Vector2(width + 10, 17))
	_badge.draw_rect(box, Color("#1e1729"))
	_badge.draw_rect(box, Color("#e8b875"), false, 1.0)
	_badge.draw_string(font, origin, prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#fff2ce"))


func _draw() -> void:
	if station_type != StationType.ROOM_PILLAR:
		return
	var level: float = GameManager.body
	var color := Color("#80f1a8")
	match pillar_name:
		"MENTE":
			level = GameManager.mind
			color = Color("#8de5ff")
		"DESCANSO":
			level = GameManager.rest
			color = Color("#ffe091")
	var pulse: float = 0.5 + 0.5 * sin(_time * 6.0)
	if level < 40.0:
		color = Color("#ff435b")
		pulse = 1.0 if fmod(_time, 0.42) < 0.21 else 0.12
	var center := Vector2(0, -24)
	draw_circle(center, 9.0 + roundf(4.0 * pulse), Color(color, 0.14 + pulse * 0.35))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -8), center + Vector2(6, 0),
		center + Vector2(0, 8), center + Vector2(-6, 0),
	]), Color(color, 0.55 + pulse * 0.45))
