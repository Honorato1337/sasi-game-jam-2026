extends Node2D

const Enemy = preload("res://scenes/enemies/enemy_base.gd")
const PULSE_INTERVAL: float = 2.0
const PULSE_RADIUS: float = 76.0
const PULSE_VISUAL_DURATION: float = 0.38

var core_position: Vector2 = Vector2(320, 180)
var orbit_slot: int = 0
var _orbit_time: float = 0.0
var _pulse_remaining: float = PULSE_INTERVAL
var _pulse_age: float = PULSE_VISUAL_DURATION
var _pulse_origin: Vector2
var _prev_x: float = 0.0


@onready var _sprite: Sprite2D = $Sprite2D
@onready var _shadow: Polygon2D = $GroundShadow


func _ready() -> void:
	_sprite.frame = orbit_slot % 2
	_update_position()
	_prev_x = global_position.x


func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	_orbit_time += delta
	_update_position(delta)
	_pulse_age += delta
	_pulse_remaining -= delta
	if _pulse_remaining <= 0.0:
		var pulse_interval: float = PULSE_INTERVAL * pow(0.82, GameManager.ally_count)
		var pulse_damage: int = 18 + 10 * GameManager.ally_count
		_pulse_remaining += pulse_interval
		_pulse_age = 0.0
		_pulse_origin = global_position
		var hit_any: bool = false
		for member: Node in get_tree().get_nodes_in_group(&"enemies"):
			var enemy: Enemy = member as Enemy
			if enemy == null or enemy.is_queued_for_deletion():
				continue
			if _pulse_origin.distance_squared_to(enemy.global_position) <= PULSE_RADIUS * PULSE_RADIUS:
				enemy.take_damage(pulse_damage)
				enemy.apply_slow(1.2, 0.55)
				hit_any = true
		if hit_any:
			AudioManager.play_ally_pulse()
	queue_redraw()


func _update_position(delta: float = 0.0) -> void:
	var angle: float = orbit_slot * TAU / GameManager.MAX_ALLIES + _orbit_time * 0.65
	global_position = core_position + Vector2.from_angle(angle) * 34.0
	var dx: float = global_position.x - _prev_x
	_prev_x = global_position.x
	_sprite.frame = (int(_orbit_time / 0.24) + orbit_slot) % 2
	var bob: float = roundf(sin(_orbit_time * 3.0 + orbit_slot))
	var pixel: Vector2 = global_position.round() - global_position
	_shadow.position = pixel + Vector2(0, 8)
	_shadow.scale = Vector2(0.95 - bob * 0.04, 0.95)
	_sprite.position = pixel + Vector2(0, -9 + bob)
	var target_rot: float = clampf(dx * 0.08, -0.08, 0.08)
	_sprite.rotation = lerpf(_sprite.rotation, target_rot, 1.0 - exp(-maxf(delta, 0.016) * 10.0))


func _draw() -> void:
	var aura_r: float = PULSE_RADIUS * 0.45 + sin(_orbit_time * 3.0) * 2.0
	draw_arc(Vector2(0, 6), aura_r, 0.0, TAU, 36, Color(0.50, 1.0, 0.82, 0.14), 1.5)
	if _pulse_age < PULSE_VISUAL_DURATION:
		var progress: float = _pulse_age / PULSE_VISUAL_DURATION
		var radius: float = lerpf(8.0, PULSE_RADIUS, progress)
		var color: Color = Color(0.5, 1.0, 0.79, 1.0 - progress)
		draw_arc(to_local(_pulse_origin), radius, 0.0, TAU, 36, Color(color, (1.0 - progress) * 0.45), 1.5)
		for index: int in range(48):
			var point: Vector2 = _pulse_origin + Vector2.from_angle(index * TAU / 48) * radius
			draw_rect(Rect2(to_local(point.round()), Vector2(2, 2)), color)


func is_player_near(player: Node2D) -> bool:
	return global_position.distance_squared_to(player.global_position) <= PULSE_RADIUS * PULSE_RADIUS
