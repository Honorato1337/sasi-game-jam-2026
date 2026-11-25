extends Node2D

const Player = preload("res://scenes/player/player.gd")
const HIT_RADIUS: float = 9.0
const LIFETIME: float = 5.0

var direction: Vector2 = Vector2.RIGHT
var is_stress: bool = false
var player: Player
var _remaining: float = LIFETIME


func _ready() -> void:
	if is_stress:
		add_to_group(&"stress_projectiles")
	add_to_group(&"enemy_projectiles")


func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING or is_queued_for_deletion():
		return
	_remaining -= delta
	if _remaining <= 0.0 or not is_instance_valid(player):
		queue_free()
		return
	var previous: Vector2 = global_position
	global_position += direction * (96.0 if is_stress else 68.0) * delta
	var closest: Vector2 = Geometry2D.get_closest_point_to_segment(player.global_position, previous, global_position)
	if closest.distance_squared_to(player.global_position) <= HIT_RADIUS * HIT_RADIUS:
		if player.apply_enemy_contact(previous, 7 if is_stress else 5, 8.0 if is_stress else 9.0, 0.0):
			queue_free()


func _draw() -> void:
	var color := Color("#f44762") if is_stress else Color("#ab71ed")
	draw_set_transform(global_position.round() - global_position)
	draw_rect(Rect2(-5, -3, 10, 6), color)
	draw_rect(Rect2(-3, -5, 6, 10), color)
	draw_rect(Rect2(-2, -2, 4, 4), Color("#fff0df"))
