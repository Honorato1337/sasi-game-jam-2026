extends Node2D

signal defeated
signal boss_pulsed

enum EnemyType { ROUTINE_PRESSURE, FATIGUE, GRIEF_GUILT, EXHAUSTION_BOSS }

const Player = preload("res://scenes/player/player.gd")
const MAX_HP: Array[int] = [30, 60, 25, 320]
const SPEEDS: Array[float] = [55.0, 35.0, 72.0, 24.0]
const COLORS: Array[Color] = [
	Color("#dc714f"), Color("#c29153"), Color("#9571cf"), Color("#bb405c"),
]
const SPRITES: Array[Texture2D] = [
	preload("res://assets/sprites/enemy_routine_sheet.png"),
	preload("res://assets/sprites/enemy_fatigue_sheet.png"),
	preload("res://assets/sprites/enemy_grief_sheet.png"),
	preload("res://assets/sprites/enemy_boss_sheet.png"),
]
const BOSS_PULSE_INTERVAL: float = 6.0
const BOSS_CONTACT_INTERVAL: float = 1.2
const PULSE_DURATION: float = 1.0
const HIT_FLASH_DURATION: float = 0.09

@export var enemy_type: EnemyType = EnemyType.ROUTINE_PRESSURE

var player: Player
var core_position: Vector2 = Vector2(320, 180)
var hp: int
var _knockback: Vector2 = Vector2.ZERO
var _slow_remaining: float = 0.0
var _slow_factor: float = 1.0
var _contact_remaining: float = BOSS_CONTACT_INTERVAL
var _pulse_remaining: float = BOSS_PULSE_INTERVAL
var _pulse_age: float = PULSE_DURATION
var _pulse_origin: Vector2
var _hit_flash: float = 0.0
var _step_time: float = 0.0


@onready var _sprite: Sprite2D = $Sprite2D
@onready var _flash_material: ShaderMaterial = _sprite.material as ShaderMaterial
@onready var _shadow: Polygon2D = $GroundShadow


func _ready() -> void:
	hp = MAX_HP[enemy_type]
	_sprite.texture = SPRITES[enemy_type]
	if player == null:
		player = get_tree().get_first_node_in_group(&"player") as Player
	_update_sprite(player.global_position if enemy_type == EnemyType.GRIEF_GUILT
			and is_instance_valid(player) else core_position)


func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING or is_queued_for_deletion():
		return

	var boss: bool = enemy_type == EnemyType.EXHAUSTION_BOSS
	if _hit_flash > 0.0:
		_hit_flash = maxf(0.0, _hit_flash - delta)
		if _hit_flash == 0.0:
			_flash_material.set_shader_parameter(&"hit_flash", 0.0)
	_step_time = fposmod(_step_time + delta, 0.64 if boss else 0.32)
	var chases_player: bool = enemy_type == EnemyType.GRIEF_GUILT
	var has_player: bool = is_instance_valid(player)
	var target: Vector2 = core_position
	if chases_player:
		target = player.global_position if has_player else global_position

	var reach: float = 16.0 if boss else 0.0
	var distance: float = global_position.distance_to(target)
	var slowed_step: float = minf(delta, _slow_remaining)
	var travel: float = SPEEDS[enemy_type] * (delta - slowed_step * (1.0 - _slow_factor))
	global_position = global_position.move_toward(target, minf(travel, maxf(0.0, distance - reach)))
	global_position += _knockback * delta
	_knockback = _knockback.move_toward(Vector2.ZERO, 850.0 * delta)
	_slow_remaining -= slowed_step

	if has_player and not boss and global_position.distance_to(player.global_position) <= 13.0:
		if chases_player:
			if player.apply_enemy_contact(global_position, 16.0):
				var retreat: Vector2 = player.global_position.direction_to(global_position)
				apply_knockback((retreat if retreat != Vector2.ZERO else player.facing_direction) * 115.0)
		else:
			player.apply_enemy_contact(global_position, 14.0)

	if boss:
		_update_boss(delta)
	elif not chases_player and global_position.distance_to(core_position) <= 13.0:
		GameManager.damage_core(8 if enemy_type == EnemyType.ROUTINE_PRESSURE else 14)
		queue_free()
	_update_sprite(target)
	queue_redraw()


func _update_sprite(target: Vector2) -> void:
	var boss: bool = enemy_type == EnemyType.EXHAUSTION_BOSS
	var half_step: float = 0.32 if boss else 0.16
	var size: Vector2 = _sprite.get_rect().size
	var pixel: Vector2 = global_position.round() - global_position
	_sprite.frame = int(_step_time >= half_step)
	var bob: float = roundf(sin(_step_time * PI / half_step) * (2.0 if boss else 1.0))
	# Keep the full sprite and its health bar visible at the north spawn.
	var ground_y: float = maxf(28.0 if boss else 10.0,
			6.0 + size.y - global_position.round().y)
	_sprite.position = pixel + Vector2(0, ground_y - size.y * 0.5 + bob)
	_shadow.position = pixel + Vector2(0, ground_y - 2.0)
	_shadow.scale = Vector2(size.x / 28.0, 1.35 if boss else 0.75)
	if target.x != global_position.x:
		_sprite.flip_h = target.x < global_position.x


func _update_boss(delta: float) -> void:
	if global_position.distance_to(core_position) <= 16.5:
		_contact_remaining -= delta
		if _contact_remaining <= 0.0:
			_contact_remaining += BOSS_CONTACT_INTERVAL
			GameManager.damage_core(12)
	else:
		_contact_remaining = BOSS_CONTACT_INTERVAL

	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	_pulse_age += delta
	_pulse_remaining -= delta
	if _pulse_remaining <= 0.0:
		_pulse_remaining += BOSS_PULSE_INTERVAL
		_pulse_age = 0.0
		_pulse_origin = global_position
		boss_pulsed.emit()
		if is_instance_valid(player) and not player.is_in_ally_aura:
			GameManager.add_bpm(10.0)


func take_damage(amount: int, is_clarity: bool = false,
		_hit_direction: Vector2 = Vector2.ZERO) -> void:
	if amount <= 0 or hp <= 0 or is_queued_for_deletion():
		return
	if is_clarity:
		match enemy_type:
			EnemyType.EXHAUSTION_BOSS:
				amount = 110
			EnemyType.FATIGUE:
				amount = maxi(amount, MAX_HP[EnemyType.FATIGUE])
	hp = maxi(0, hp - amount)
	_hit_flash = HIT_FLASH_DURATION
	_flash_material.set_shader_parameter(&"hit_flash", 1.0)
	queue_redraw()
	if hp == 0:
		queue_free()
		defeated.emit()


func apply_knockback(velocity_impulse: Vector2) -> void:
	_knockback = velocity_impulse


func apply_slow(duration: float, factor: float = 0.55) -> void:
	if duration > 0.0:
		_slow_remaining = maxf(_slow_remaining, duration)
		_slow_factor = clampf(factor, 0.0, 1.0)


func _draw() -> void:
	var boss: bool = enemy_type == EnemyType.EXHAUSTION_BOSS
	if boss and _pulse_age < PULSE_DURATION:
		var progress: float = _pulse_age / PULSE_DURATION
		var pulse_color: Color = Color(1.0, 0.3, 0.42, (1.0 - progress) * 0.65)
		draw_arc(to_local(_pulse_origin), lerpf(18.0, 750.0, progress),
				0.0, TAU, 96, pulse_color, 2.0)

	var width: float = 30.0 if boss else 16.0
	var bar: Vector2 = _sprite.position + Vector2(-width * 0.5, -_sprite.get_rect().size.y * 0.5 - 4.0)
	draw_rect(Rect2(bar, Vector2(width, 3)), Color("#211827"))
	var fill: float = roundf((width - 2) * float(hp) / MAX_HP[enemy_type])
	draw_rect(Rect2(bar + Vector2.ONE, Vector2(fill, 1)), Color("#ffedca"))
