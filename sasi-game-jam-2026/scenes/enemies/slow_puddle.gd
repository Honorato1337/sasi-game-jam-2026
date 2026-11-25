extends Node2D

const RADIUS: float = 13.0
const LIFETIME: float = 2.8
const slow_multiplier: float = 0.60

var _remaining: float = LIFETIME


func _ready() -> void:
	add_to_group(&"slow_puddles")
	z_index = -1


func contains_point(point: Vector2) -> bool:
	return global_position.distance_squared_to(point) <= RADIUS * RADIUS


func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var opacity: float = minf(_remaining / 0.35, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.72))
	draw_circle(Vector2.ZERO, RADIUS, Color(0.48, 0.34, 0.67, opacity * 0.65))
	draw_rect(Rect2(-8, -3, 8, 2), Color(0.76, 0.62, 0.89, opacity * 0.8))
