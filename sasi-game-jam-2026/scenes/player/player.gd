extends CharacterBody2D

signal attacked(is_clarity: bool, origin: Vector2, direction: Vector2, attack_range: float, damage: int)
signal clarity_hit
signal dashed(direction: Vector2)
signal breathing_progressed(progress: float, is_breathing: bool)
signal breathing_completed()
signal hit_taken(bpm_added: float)

const BASE_SPEED: float = 115.0
const ATTACK_COOLDOWN: float = 0.32
const EXHAUSTED_ATTACK_COOLDOWN: float = 0.65
const ATTACK_HALF_ANGLE: float = PI / 4.0
const CLARITY_HALF_ANGLE: float = PI * 0.4
const CLARITY_KNOCKBACK_SPEED: float = 220.0
const ATTACK_FLASH_DURATION: float = 0.14
const DASH_SPEED: float = 240.0
const DASH_DURATION: float = 0.18
const DASH_COOLDOWN: float = 0.75
const HIT_INVULNERABILITY: float = 0.4
const HIT_PUSH_DURATION: float = 0.10
const HIT_FLASH_DURATION: float = 0.09
const HIT_PUSH_SPEED: float = 105.0

var facing_direction: Vector2 = Vector2.RIGHT
var is_in_ally_aura: bool = false

var _attack_cooldown: float = 0.0
var _attack_flash: float = 0.0
var _attack_direction: Vector2 = Vector2.RIGHT
var _attack_range: float = 0.0
var _attack_half_angle: float = 0.0
var _attack_is_clarity: bool = false
var _dash_cooldown: float = 0.0
var _dash_remaining: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _hit_cooldown: float = 0.0
var _hit_push_remaining: float = 0.0
var _hit_direction: Vector2 = Vector2.ZERO
var _breath_elapsed: float = 0.0
var _breath_progress: float = 0.0
var _breath_completed_for_hold: bool = false
var _hit_flash: float = 0.0
var _animation_time: float = 0.0
var _alternate_frame: bool = false
var _walking: bool = false

@onready var _visual: Node2D = $Visual
@onready var _sprite: Sprite2D = $Visual/Sprite2D
@onready var _flash_material: ShaderMaterial = _sprite.material as ShaderMaterial
@onready var _shadow: Polygon2D = $GroundShadow
@onready var _breath_ring: Node2D = $BreathRing
@onready var _attack_arc: Node2D = $AttackArc


func _ready() -> void:
	_visual.draw.connect(_draw_visual)
	_breath_ring.draw.connect(_draw_breath_ring)
	_attack_arc.draw.connect(_draw_attack_arc)
	GameManager.clarity_ready_changed.connect(_on_clarity_ready_changed)
	if get_tree().current_scene == self:
		_start_standalone_run()
	elif get_parent() == get_tree().root:
		# current_scene can be assigned after this node enters the tree.
		_start_standalone_run.call_deferred()


func _start_standalone_run() -> void:
	if get_tree().current_scene == self and GameManager.current_state == GameManager.GameState.MENU:
		position = get_viewport_rect().get_center()
		GameManager.start_new_run()


func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		velocity = Vector2.ZERO
		_reset_breathing()
		return

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_dash_cooldown = maxf(0.0, _dash_cooldown - delta)
	_hit_cooldown = maxf(0.0, _hit_cooldown - delta)
	if _hit_flash > 0.0:
		_hit_flash = maxf(0.0, _hit_flash - delta)
		if _hit_flash == 0.0:
			_flash_material.set_shader_parameter(&"hit_flash", 0.0)
	if _attack_flash > 0.0:
		_attack_flash = maxf(0.0, _attack_flash - delta)
		_attack_arc.queue_redraw()

	var move_input: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if move_input != Vector2.ZERO and _dash_remaining <= 0.0:
		facing_direction = move_input.normalized()

	var breathe_held: bool = Input.is_action_pressed(&"breathe")
	_update_breathing(delta, breathe_held)
	var exhausted: bool = GameManager.signal_level == GameManager.SignalLevel.EXHAUSTED
	if Input.is_action_just_pressed(&"dash") and _dash_cooldown <= 0.0 and not exhausted:
		_dash_direction = facing_direction
		_dash_remaining = DASH_DURATION
		_dash_cooldown = DASH_COOLDOWN
		GameManager.add_bpm(9.0)
		dashed.emit(_dash_direction)

	if Input.is_action_just_pressed(&"attack") and _attack_cooldown <= 0.0:
		_attack()

	var speed: float = BASE_SPEED * GameManager.get_move_speed_multiplier()
	if breathe_held:
		speed *= 0.40
	velocity = move_input * speed
	var dash_step: float = minf(delta, _dash_remaining)
	velocity = velocity.lerp(_dash_direction * DASH_SPEED, dash_step / delta)
	velocity += _hit_direction * HIT_PUSH_SPEED * minf(delta, _hit_push_remaining) / delta
	move_and_slide()
	_dash_remaining -= dash_step
	_hit_push_remaining = maxf(0.0, _hit_push_remaining - delta)

	GameManager.tick_bpm(delta, _attack_cooldown <= 0.0 and dash_step <= 0.0)
	if is_in_ally_aura:
		GameManager.reduce_bpm(4.0 * delta)
	_update_visual_tremor()
	_update_visual_animation(delta, move_input != Vector2.ZERO)


func reset_run() -> void:
	velocity = Vector2.ZERO
	facing_direction = Vector2.RIGHT
	_attack_cooldown = 0.0
	_attack_flash = 0.0
	_dash_cooldown = 0.0
	_dash_remaining = 0.0
	_hit_cooldown = 0.0
	_hit_push_remaining = 0.0
	_hit_flash = 0.0
	_animation_time = 0.0
	_alternate_frame = false
	_walking = false
	_sprite.frame = 0
	_sprite.flip_h = false
	_flash_material.set_shader_parameter(&"hit_flash", 0.0)
	_update_visual_tremor()
	_visual.queue_redraw()
	_reset_breathing()
	_attack_arc.queue_redraw()


func apply_enemy_contact(from_position: Vector2, bpm_cost: float = 14.0) -> bool:
	if _hit_cooldown > 0.0 or GameManager.current_state != GameManager.GameState.PLAYING:
		return false
	_hit_cooldown = HIT_INVULNERABILITY
	_hit_flash = HIT_FLASH_DURATION
	_flash_material.set_shader_parameter(&"hit_flash", 1.0)
	_hit_push_remaining = HIT_PUSH_DURATION
	_hit_direction = from_position.direction_to(global_position)
	if _hit_direction == Vector2.ZERO:
		_hit_direction = -facing_direction
	var previous_bpm: float = GameManager.bpm
	GameManager.add_bpm(bpm_cost)
	hit_taken.emit(GameManager.bpm - previous_bpm)
	return true


func _attack() -> void:
	_attack_cooldown = ATTACK_COOLDOWN
	if GameManager.signal_level == GameManager.SignalLevel.EXHAUSTED:
		_attack_cooldown = EXHAUSTED_ATTACK_COOLDOWN

	_attack_is_clarity = GameManager.consume_clarity_strike()
	var damage: int = 55 if _attack_is_clarity else 20
	_attack_range = 54.0 if _attack_is_clarity else 36.0
	_attack_half_angle = CLARITY_HALF_ANGLE if _attack_is_clarity else ATTACK_HALF_ANGLE
	_attack_direction = facing_direction
	_attack_flash = ATTACK_FLASH_DURATION
	_attack_arc.queue_redraw()

	var origin: Vector2 = global_position
	var min_dot: float = cos(_attack_half_angle)
	var hit_enemy: bool = false
	for member: Node in get_tree().get_nodes_in_group(&"enemies"):
		if not is_instance_valid(member) or member.is_queued_for_deletion():
			continue
		var enemy: Node2D = member as Node2D
		if enemy == null or not enemy.has_method(&"take_damage"):
			continue
		var offset: Vector2 = enemy.global_position - origin
		if offset.length_squared() > _attack_range * _attack_range:
			continue
		if offset != Vector2.ZERO and offset.normalized().dot(_attack_direction) < min_dot:
			continue
		enemy.call(&"take_damage", damage, _attack_is_clarity, _attack_direction)
		hit_enemy = true
		# Enemies can accept a knockback velocity without exposing their movement state.
		if _attack_is_clarity and is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			if enemy.has_method(&"apply_knockback"):
				enemy.call(&"apply_knockback", _attack_direction * CLARITY_KNOCKBACK_SPEED)

	if not _attack_is_clarity:
		GameManager.add_bpm(4.5)
	elif hit_enemy:
		clarity_hit.emit()
	attacked.emit(_attack_is_clarity, origin, _attack_direction, _attack_range, damage)


func _update_breathing(delta: float, breathe_held: bool) -> void:
	if not breathe_held:
		_reset_breathing()
		return
	if _breath_completed_for_hold:
		return
	var duration: float = GameManager.get_breathe_duration()
	var channel_step: float = minf(delta, maxf(0.0, duration - _breath_elapsed))
	_breath_elapsed += channel_step
	_breath_progress = clampf(_breath_elapsed / duration, 0.0, 1.0)
	GameManager.reduce_bpm(28.0 * channel_step)
	_breath_ring.queue_redraw()
	breathing_progressed.emit(_breath_progress, true)
	if _breath_elapsed >= duration:
		_breath_completed_for_hold = true
		GameManager.complete_breathing()
		breathing_completed.emit()
		breathing_progressed.emit(1.0, false)


func _reset_breathing() -> void:
	if _breath_elapsed <= 0.0:
		return
	_breath_elapsed = 0.0
	_breath_progress = 0.0
	_breath_completed_for_hold = false
	_breath_ring.queue_redraw()
	breathing_progressed.emit(0.0, false)


func _update_visual_tremor() -> void:
	var amplitude: int = 0
	match GameManager.signal_level:
		GameManager.SignalLevel.OVERLOAD:
			amplitude = 1
		GameManager.SignalLevel.EXHAUSTED:
			amplitude = 2
	var tremor: Vector2 = Vector2(randi_range(-amplitude, amplitude), randi_range(-amplitude, amplitude))
	var pixel: Vector2 = global_position.round() - global_position
	_shadow.position = pixel + Vector2(0, 8)
	_visual.position = pixel + tremor


func _update_visual_animation(delta: float, walking: bool) -> void:
	if walking != _walking:
		_walking = walking
		_animation_time = 0.0
		_visual.queue_redraw()
	var frame_duration: float = 0.12 if walking else 0.55
	_animation_time = fposmod(_animation_time + delta, frame_duration * 2.0)
	var alternate: bool = _animation_time >= frame_duration
	_sprite.frame = (2 if walking else 0) + int(alternate)
	if facing_direction.x != 0.0:
		_sprite.flip_h = facing_direction.x < 0.0
	if alternate != _alternate_frame:
		_alternate_frame = alternate
		_visual.queue_redraw()


func _on_clarity_ready_changed(_is_ready: bool) -> void:
	_visual.queue_redraw()


func _draw_visual() -> void:
	if GameManager.clarity_ready:
		var aura: Color = Color(0.45, 1.0, 0.95, 0.48 if _alternate_frame else 0.30)
		for index: int in range(20):
			var point: Vector2 = (Vector2.from_angle(index * TAU / 20) * Vector2(17, 17)).round() + Vector2(0, -6)
			_visual.draw_rect(Rect2(point - Vector2(1, 2), Vector2(2, 2)), aura)


func _draw_breath_ring() -> void:
	if _breath_progress <= 0.0:
		return
	var center: Vector2 = Vector2(0, -7)
	_breath_ring.draw_arc(center, 18.0, 0.0, TAU, 32, Color("#294d50"), 1.0)
	_breath_ring.draw_arc(center, 18.0, -PI / 2.0,
			-PI / 2.0 + TAU * _breath_progress, 32, Color("#89ffe0"), 2.0)


func _draw_attack_arc() -> void:
	if _attack_flash <= 0.0:
		return
	var angle: float = _attack_direction.angle()
	var color: Color = Color("#89ffe0") if _attack_is_clarity else Color("#ffda8e")
	color.a = _attack_flash / ATTACK_FLASH_DURATION
	var width: float = 4.0 if _attack_is_clarity else 2.0
	_attack_arc.draw_arc(Vector2.ZERO, _attack_range, angle - _attack_half_angle,
			angle + _attack_half_angle, 24, color, width)
	color.a *= 0.45
	_attack_arc.draw_arc(Vector2.ZERO, _attack_range - 5.0, angle - _attack_half_angle,
			angle + _attack_half_angle, 24, color, 1.0)
