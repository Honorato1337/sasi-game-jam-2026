extends Node2D

const Player = preload("res://scenes/player/player.gd")
const HIT_RADIUS: float = 9.0
const LIFETIME: float = 5.0

var direction: Vector2 = Vector2.RIGHT
var is_stress: bool = false
var player: Player
var _remaining: float = LIFETIME
var _traveled: float = 0.0
var _age: float = 0.0
var _trail: Array[Vector2] = []
var _trail_timer: float = 0.0


func _ready() -> void:
	if is_stress:
		add_to_group(&"stress_projectiles")
	add_to_group(&"enemy_projectiles")


func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING or is_queued_for_deletion():
		return
	_remaining -= delta
	_age += delta
	if _remaining <= 0.0 or not is_instance_valid(player):
		queue_free()
		return
	_trail_timer -= delta
	if _trail_timer <= 0.0:
		_trail_timer += 0.035
		_trail.push_front(global_position)
		if _trail.size() > 3:
			_trail.pop_back()
	var previous: Vector2 = global_position
	var cycle: int = GameManager.get_cycle()
	var speed: float = (128.0 if GameManager.room == 9 else 112.0) if is_stress else (78.0 + 10.0 * float(cycle - 1))
	var step: Vector2 = direction * speed * delta
	global_position += step
	_traveled += step.length()
	if _traveled >= 18.0:
		for obstacle: Node in get_tree().get_nodes_in_group(&"room_obstacles"):
			var obs_node: Node2D = obstacle as Node2D
			if obs_node == null or not is_instance_valid(obs_node):
				continue
			var half: Vector2 = obs_node.get_meta(&"half_extents", Vector2(18.0, 14.0))
			var diff: Vector2 = global_position - obs_node.global_position
			if absf(diff.x) <= half.x + 3.0 and absf(diff.y) <= half.y + 3.0:
				AudioManager.play_pillar_block()
				queue_free()
				return
	var dmg: int = (13 if GameManager.room == 9 else 10) if is_stress else (7 + maxi(0, cycle - 1) * 3)
	var closest: Vector2 = Geometry2D.get_closest_point_to_segment(player.global_position, previous, global_position)
	if closest.distance_squared_to(player.global_position) <= HIT_RADIUS * HIT_RADIUS:
		if player.apply_enemy_contact(previous, dmg, 14.0,
				8.0 if is_stress else 0.0, 0.0 if is_stress else 6.0):
			queue_free()
	queue_redraw()


func _draw() -> void:
	var color := Color("#f44762") if is_stress else Color("#ab71ed")
	var glow := Color("#ff8ea3") if is_stress else Color("#d2a8ff")
	for idx: int in range(_trail.size()):
		var pt: Vector2 = to_local(_trail[idx]).round()
		var sz: float = 3.0 - float(idx) * 0.6
		var alpha: float = 0.42 - float(idx) * 0.12
		draw_rect(Rect2(pt - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), Color(glow, alpha))
	var pulse: float = 0.5 + 0.5 * sin(_age * 16.0)
	draw_set_transform(global_position.round() - global_position, _age * (5.0 if is_stress else 3.5))
	draw_circle(Vector2.ZERO, 6.0 + pulse * 1.5, Color(color, 0.22))
	draw_rect(Rect2(-5, -2, 10, 4), color)
	draw_rect(Rect2(-2, -5, 4, 10), color)
	draw_rect(Rect2(-3, -3, 6, 6), glow)
	draw_rect(Rect2(-2, -2, 4, 4), Color("#fff0df"))
