extends Node2D

signal defeated
signal boss_pulsed
signal pillar_drained(pillar_name: String)

enum EnemyType {
	PROCRASTINATION, DEADLINE, SELF_CRITICISM, BURNOUT_BOSS,
	# Serialized IDs and names used by the prototype arena.
	ROUTINE_PRESSURE = 0, FATIGUE = 1, GRIEF_GUILT = 2, EXHAUSTION_BOSS = 3,
}

const Player = preload("res://scenes/player/player.gd")
const Projectile = preload("res://scenes/enemies/enemy_projectile.gd")
const Puddle = preload("res://scenes/enemies/slow_puddle.gd")
const MAX_HP: Array[int] = [35, 30, 45, 380]
const SPEEDS: Array[float] = [42.0, 76.0, 50.0, 26.0]
const COLORS: Array[Color] = [
	Color("#9c75ba"), Color("#ff9b52"), Color("#ca83ff"), Color("#ff586d"),
]
const SPRITES: Array[Texture2D] = [
	preload("res://assets/sprites/enemy_procrastination_sheet.png"),
	preload("res://assets/sprites/enemy_deadline_sheet.png"),
	preload("res://assets/sprites/enemy_selfcriticism_sheet.png"),
	preload("res://assets/sprites/boss_burnout_sheet.png"),
]
const ATTACK_INTERVALS: Array[float] = [4.0, 2.4, 3.2, 3.8]
const WARNING_DURATIONS: Array[float] = [0.0, 0.35, 0.6, 0.85]
const HIT_FLASH_DURATION: float = 0.09
const DRAIN_VISUAL_DURATION: float = 0.65

@export var enemy_type: EnemyType = EnemyType.PROCRASTINATION

var player: Player
var core_position: Vector2 = Vector2(320, 180)
var hp: int
var _knockback: Vector2 = Vector2.ZERO
var _slow_remaining: float = 0.0
var _slow_factor: float = 1.0
var _attack_elapsed: float = 0.0
var _aim: Vector2 = Vector2.RIGHT
var _charge_remaining: float = 0.0
var _drain_elapsed: float = 0.0
var _drain_visual: float = 0.0
var _drain_origin: Vector2
var _next_pillar: int = 0
var _hit_flash: float = 0.0
var _step_time: float = 0.0
var _motion_time: float = 0.0
var _trail_remaining: float = 0.0
var _trail: Array[Vector2] = []


@onready var _sprite: Sprite2D = $Sprite2D
@onready var _flash_material: ShaderMaterial = _sprite.material as ShaderMaterial
@onready var _shadow: Polygon2D = $GroundShadow


func _ready() -> void:
	hp = MAX_HP[enemy_type]
	_sprite.texture = SPRITES[enemy_type]
	if player == null:
		player = get_tree().get_first_node_in_group(&"player") as Player
	_update_sprite(core_position)


func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING or is_queued_for_deletion():
		return

	if _hit_flash > 0.0:
		_hit_flash = maxf(0.0, _hit_flash - delta)
		if _hit_flash == 0.0:
			_flash_material.set_shader_parameter(&"hit_flash", 0.0)
	_step_time = fposmod(_step_time + delta, _half_step_duration() * 2.0)
	_motion_time += delta
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group(&"player") as Player
	if is_instance_valid(player):
		var target: Vector2 = player.global_position
		_update_attack(delta, target)
		_move(delta, target)
		_check_contact()
		_update_sprite(target)
	else:
		_update_sprite(core_position)

	if enemy_type == EnemyType.SELF_CRITICISM:
		_trail_remaining -= delta
		if _trail_remaining <= 0.0:
			_trail_remaining += 0.065
			_trail.push_front(_sprite.global_position)
			if _trail.size() > 4:
				_trail.pop_back()
	queue_redraw()


func _move(delta: float, target: Vector2) -> void:
	var distance: float = global_position.distance_to(target)
	var direction: Vector2 = global_position.direction_to(target)
	var speed: float = SPEEDS[enemy_type]
	if enemy_type == EnemyType.SELF_CRITICISM and distance <= 115.0:
		speed = -speed if distance < 85.0 else 0.0
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT
	elif is_boss():
		speed = minf(speed, maxf(0.0, distance - 32.0) / delta)
	elif enemy_type == EnemyType.DEADLINE and _warning_strength() > 0.0:
		speed = 0.0
	elif enemy_type == EnemyType.PROCRASTINATION:
		# Each hop averages the base speed over one cycle.
		speed *= 1.0 - cos(_motion_time * TAU / 0.62)
	var slowed_step: float = minf(delta, _slow_remaining)
	var charge_step: float = minf(delta, _charge_remaining)
	var travel: Vector2 = direction * speed * (delta - charge_step) + _aim * 165.0 * charge_step
	global_position += travel * (1.0 - slowed_step / delta * (1.0 - _slow_factor))
	global_position += _knockback * delta
	_knockback = _knockback.move_toward(Vector2.ZERO, 850.0 * delta)
	_slow_remaining -= slowed_step
	_charge_remaining -= charge_step


func _check_contact() -> void:
	if global_position.distance_squared_to(player.global_position) > 13.0 * 13.0:
		return
	match enemy_type:
		EnemyType.PROCRASTINATION:
			player.apply_enemy_contact(global_position, 8, 0.0, 10.0)
		EnemyType.DEADLINE:
			player.apply_enemy_contact(global_position, 10, 8.0, 0.0)


func _attack_interval() -> float:
	return 2.8 if is_phase_two() else ATTACK_INTERVALS[enemy_type]


func is_phase_two() -> bool:
	return is_boss() and hp <= 190


func _update_attack(delta: float, target: Vector2) -> void:
	var interval: float = _attack_interval()
	var warning_start: float = interval - WARNING_DURATIONS[enemy_type]
	if _attack_elapsed < warning_start:
		_aim = global_position.direction_to(target)
		if _aim == Vector2.ZERO:
			_aim = Vector2.RIGHT
	_attack_elapsed += delta
	if _attack_elapsed >= interval:
		_attack_elapsed = 0.0
		match enemy_type:
			EnemyType.PROCRASTINATION: _spawn_puddle()
			EnemyType.DEADLINE: _charge_remaining = 0.28
			EnemyType.SELF_CRITICISM: _spawn_projectile(_aim)
			EnemyType.BURNOUT_BOSS:
				var half_count: int = 2 if is_phase_two() else 1
				for index: int in range(-half_count, half_count + 1):
					_spawn_projectile(_aim.rotated(index * 0.25))

	if is_boss():
		_drain_visual = maxf(0.0, _drain_visual - delta)
		_drain_elapsed += delta
		if _drain_elapsed >= (5.5 if is_phase_two() else 7.0):
			_drain_elapsed = 0.0
			_drain_visual = DRAIN_VISUAL_DURATION
			_drain_origin = global_position
			_drain_pillar()


func _drain_pillar() -> void:
	const PILLARS: Array[String] = ["CORPO", "MENTE", "DESCANSO"]
	match _next_pillar:
		0: GameManager.modify_body(-22.0)
		1: GameManager.modify_mind(-22.0)
		2: GameManager.modify_rest(-22.0)
	pillar_drained.emit(PILLARS[_next_pillar])
	_next_pillar = (_next_pillar + 1) % PILLARS.size()
	boss_pulsed.emit()


func _spawn_projectile(direction: Vector2) -> void:
	var projectile := Projectile.new()
	projectile.player = player
	projectile.direction = direction
	projectile.is_stress = is_boss()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + direction * 12.0


func _spawn_puddle() -> void:
	var puddle := Puddle.new()
	get_parent().add_child(puddle)
	puddle.global_position = global_position

func _update_sprite(target: Vector2) -> void:
	var boss: bool = is_boss()
	var half_step: float = _half_step_duration()
	var size: Vector2 = _sprite.get_rect().size
	var pixel: Vector2 = global_position.round() - global_position
	_sprite.frame = int(_step_time >= half_step)
	var bob: float = roundf(sin(_step_time * PI / half_step) * (2.0 if boss else 1.0))
	var sway: float = 0.0
	var scale_factor: Vector2 = Vector2.ONE
	match enemy_type:
		EnemyType.PROCRASTINATION:
			var hop: float = sin(fposmod(_motion_time, 0.62) * PI / 0.62)
			bob = -roundf(hop * 5.0)
			scale_factor = Vector2(1.12 - hop * 0.23, 0.88 + hop * 0.25)
		EnemyType.DEADLINE:
			var step: float = sin(_motion_time * TAU / 0.80)
			bob = -roundf(absf(step) * 2.0)
			sway = step * 0.05
		EnemyType.SELF_CRITICISM:
			bob = -3.0 + sin(_motion_time * TAU / 0.95) * 3.0
	_sprite.rotation = sway
	_sprite.scale = scale_factor
	var warning_color := Color("#ff586d")
	if enemy_type == EnemyType.DEADLINE:
		warning_color = Color("#ff9b52")
	elif enemy_type == EnemyType.SELF_CRITICISM:
		warning_color = Color("#ca83ff")
	_sprite.self_modulate = Color.WHITE.lerp(warning_color, _warning_strength())
	# Keep the full sprite and its health bar visible at the north spawn.
	var ground_y: float = maxf(28.0 if boss else 10.0,
			6.0 + size.y - global_position.round().y)
	_sprite.position = pixel + Vector2(0, ground_y - size.y * 0.5 + bob)
	_shadow.position = pixel + Vector2(0, ground_y - 2.0)
	_shadow.scale = Vector2(size.x / 28.0, 1.35 if boss else 0.75)
	if target.x != global_position.x:
		_sprite.flip_h = target.x < global_position.x


func _half_step_duration() -> float:
	match enemy_type:
		EnemyType.DEADLINE:
			return 0.40
		EnemyType.BURNOUT_BOSS:
			return 0.32
		_:
			return 0.16


func is_boss() -> bool:
	return enemy_type == EnemyType.BURNOUT_BOSS


func _warning_strength() -> float:
	var duration: float = WARNING_DURATIONS[enemy_type]
	var remaining: float = _attack_interval() - _attack_elapsed
	if duration <= 0.0 or remaining > duration:
		return 0.0
	return 0.55 + 0.35 * sin(_motion_time * 24.0)


func get_effective_damage(amount: int, is_clarity: bool) -> int:
	if amount > 0 and is_clarity and is_boss():
		return 120
	return maxi(0, amount)

func take_damage(amount: int, is_clarity: bool = false,
		_hit_direction: Vector2 = Vector2.ZERO) -> void:
	var effective_damage: int = get_effective_damage(amount, is_clarity)
	if effective_damage == 0 or hp <= 0 or is_queued_for_deletion():
		return
	hp = maxi(0, hp - effective_damage)
	_hit_flash = HIT_FLASH_DURATION
	_flash_material.set_shader_parameter(&"hit_flash", 1.0)
	queue_redraw()
	if hp == 0:
		if enemy_type == EnemyType.PROCRASTINATION:
			_spawn_puddle()
		queue_free()
		defeated.emit()


func apply_knockback(velocity_impulse: Vector2) -> void:
	_knockback = velocity_impulse


func apply_slow(duration: float, factor: float = 0.55) -> void:
	if duration > 0.0:
		_slow_remaining = maxf(_slow_remaining, duration)
		_slow_factor = clampf(factor, 0.0, 1.0)


func _draw() -> void:
	var boss: bool = is_boss()
	if enemy_type == EnemyType.SELF_CRITICISM:
		var size: Vector2 = _sprite.get_rect().size
		var source: Rect2 = Rect2(Vector2(_sprite.frame * size.x, 0), size)
		for index: int in range(_trail.size() - 1, -1, -1):
			draw_set_transform(to_local(_trail[index]), 0.0, Vector2(-1 if _sprite.flip_h else 1, 1))
			draw_texture_rect_region(_sprite.texture, Rect2(-size * 0.5, size), source,
					Color(0.78, 0.49, 1.0, 0.20 - index * 0.045), false, true)
		draw_set_transform(Vector2.ZERO)
	var warning: float = _warning_strength()
	if warning > 0.0:
		if boss:
			var remaining: float = _attack_interval() - _attack_elapsed
			var radius: float = lerpf(26.0, 56.0, clampf(remaining / 0.85, 0.0, 1.0))
			draw_circle(Vector2.ZERO, radius, Color(0.94, 0.13, 0.30, warning * 0.14))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1.0, 0.22, 0.37, warning), 2.0)
		else:
			var color := Color("#ffa354") if enemy_type == EnemyType.DEADLINE else Color("#d7a0ff")
			draw_line(_aim * 12.0, _aim * 36.0, Color(color, warning), 2.0)
	if _drain_visual > 0.0:
		var progress: float = 1.0 - _drain_visual / DRAIN_VISUAL_DURATION
		var pulse_color := Color(0.75, 0.22, 0.63, 1.0 - progress)
		draw_arc(to_local(_drain_origin), lerpf(22.0, 165.0, progress),
				0.0, TAU, 64, pulse_color, 3.0)

	var width: float = 30.0 if boss else 16.0
	var bar: Vector2 = _sprite.position + Vector2(-width * 0.5, -_sprite.get_rect().size.y * 0.5 - 4.0)
	draw_rect(Rect2(bar, Vector2(width, 3)), Color("#211827"))
	var fill: float = roundf((width - 2) * float(hp) / MAX_HP[enemy_type])
	draw_rect(Rect2(bar + Vector2.ONE, Vector2(fill, 1)), Color("#ffedca"))
