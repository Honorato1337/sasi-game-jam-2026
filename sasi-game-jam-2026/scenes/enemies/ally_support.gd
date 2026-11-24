extends Node2D

const Enemy = preload("res://scenes/enemies/enemy_base.gd")
const PULSE_INTERVAL: float = 1.8
const PULSE_RADIUS: float = 68.0
const PULSE_VISUAL_DURATION: float = 0.38

var core_position: Vector2 = Vector2(320, 180)
var orbit_slot: int = 0
var _orbit_time: float = 0.0
var _pulse_remaining: float = PULSE_INTERVAL
var _pulse_age: float = PULSE_VISUAL_DURATION
var _pulse_origin: Vector2


func _ready() -> void:
	_update_position()


func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	_orbit_time += delta
	_update_position()
	_pulse_age += delta
	_pulse_remaining -= delta
	if _pulse_remaining <= 0.0:
		_pulse_remaining += PULSE_INTERVAL
		_pulse_age = 0.0
		_pulse_origin = global_position
		for member: Node in get_tree().get_nodes_in_group(&"enemies"):
			var enemy: Enemy = member as Enemy
			if enemy == null or enemy.is_queued_for_deletion():
				continue
			if _pulse_origin.distance_squared_to(enemy.global_position) <= PULSE_RADIUS * PULSE_RADIUS:
				enemy.take_damage(15)
				enemy.apply_slow(1.2, 0.55)
	queue_redraw()


func _update_position() -> void:
	var angle: float = orbit_slot * TAU / GameManager.MAX_ALLIES + _orbit_time * 0.65
	global_position = core_position + Vector2.from_angle(angle) * 34.0


func _draw() -> void:
	if _pulse_age < PULSE_VISUAL_DURATION:
		var progress: float = _pulse_age / PULSE_VISUAL_DURATION
		var radius: float = lerpf(8.0, PULSE_RADIUS, progress)
		var color: Color = Color(0.5, 1.0, 0.79, 1.0 - progress)
		for index: int in range(48):
			var point: Vector2 = _pulse_origin + Vector2.from_angle(index * TAU / 48) * radius
			draw_rect(Rect2(to_local(point.round()), Vector2(2, 2)), color)

	var pixel: Vector2 = global_position.round() - global_position
	draw_rect(Rect2(pixel + Vector2(-5, -4), Vector2(10, 11)), Color("#20404a"))
	draw_rect(Rect2(pixel + Vector2(-4, 0), Vector2(8, 6)), Color("#58c6a0"))
	draw_rect(Rect2(pixel + Vector2(-3, -6), Vector2(6, 6)), Color("#eac695"))
	draw_rect(Rect2(pixel + Vector2(-2, -7), Vector2(4, 2)), Color("#e9f9e1"))
	draw_rect(Rect2(pixel + Vector2(-2, -3), Vector2(1, 1)), Color("#20404a"))
	draw_rect(Rect2(pixel + Vector2(1, -3), Vector2(1, 1)), Color("#20404a"))
