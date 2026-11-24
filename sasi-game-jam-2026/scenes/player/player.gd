extends CharacterBody2D

signal attacked(is_clarity: bool, origin: Vector2, direction: Vector2, attack_range: float, damage: int)
signal clarity_hit
signal dashed(direction: Vector2)
signal breathing_progressed(progress: float, is_breathing: bool)
signal breathing_completed()
signal hit_taken(bpm_added: float)
signal enemy_hit(enemy_position: Vector2, damage: int, is_clarity: bool, is_boss: bool)

const BASE_SPEED: float = 115.0
const ATTACK_COOLDOWN: float = 0.32
const EXHAUSTED_ATTACK_COOLDOWN: float = 0.65
const ATTACK_HALF_ANGLE: float = PI / 4.0
const CLARITY_HALF_ANGLE: float = PI * 0.4
const CLARITY_KNOCKBACK_SPEED: float = 220.0
const NORMAL_KNOCKBACK_SPEED: float = 95.0
const ATTACK_FLASH_DURATION: float = 0.20
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
var _visual_time: float = 0.0
var _ghost_remaining: float = 0.0
var _breathing_visual: bool = false
var _effects: Node2D

@onready var _visual: Node2D = $Visual
@onready var _sprite: Sprite2D = $Visual/Sprite2D
@onready var _flash_material: ShaderMaterial = _sprite.material as ShaderMaterial
@onready var _shadow: Polygon2D = $GroundShadow
@onready var _breath_ring: Node2D = $BreathRing
@onready var _attack_arc: Node2D = $AttackArc


func _ready() -> void:
	_effects = Node2D.new()
	_effects.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_effects)
	move_child(_effects, _visual.get_index())
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
		if _breathing_visual:
			_breathing_visual = false
			_visual.queue_redraw()
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
		_ghost_remaining = 0.0
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
	_update_visual_animation(delta, move_input != Vector2.ZERO and get_position_delta().length_squared() > 0.001,
			breathe_held, dash_step > 0.0)


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
	_visual_time = 0.0
	_breathing_visual = false
	for effect: Node in _effects.get_children():
		effect.queue_free()
	_sprite.frame = 0
	_sprite.flip_h = false
	_sprite.scale = Vector2.ONE
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
		var enemy_position: Vector2 = enemy.global_position
		var is_boss: bool = enemy.has_method(&"is_boss") and bool(enemy.call(&"is_boss"))
		var effective_damage: int = damage
		if enemy.has_method(&"get_effective_damage"):
			effective_damage = int(enemy.call(&"get_effective_damage", damage, _attack_is_clarity))
		if enemy.has_method(&"apply_knockback"):
			var impulse: float = CLARITY_KNOCKBACK_SPEED if _attack_is_clarity else NORMAL_KNOCKBACK_SPEED
			enemy.call(&"apply_knockback", _attack_direction * impulse)
		enemy.call(&"take_damage", damage, _attack_is_clarity, _attack_direction)
		enemy_hit.emit(enemy_position, effective_damage, _attack_is_clarity, is_boss)
		hit_enemy = true

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


func _update_visual_animation(delta: float, moving: bool, breathe_held: bool = false,
		dashing: bool = false) -> void:
	var walking: bool = moving and not (dashing or breathe_held or _attack_flash > 0.0)
	_visual_time += delta
	_breathing_visual = breathe_held
	if walking != _walking:
		_walking = walking
		_animation_time = 0.0
	var frame_duration: float = 0.12 if walking else 0.55
	_animation_time = fposmod(_animation_time + delta, frame_duration * 2.0)
	var alternate: bool = _animation_time >= frame_duration
	_sprite.frame = (2 if walking else 0) + int(alternate)
	var pose_direction: Vector2 = _attack_direction if _attack_flash > 0.0 else facing_direction
	var target_scale: Vector2 = Vector2.ONE
	if dashing:
		_sprite.frame = 6
		pose_direction = _dash_direction
		target_scale = Vector2(1.22, 0.84)
	elif _attack_flash > 0.0:
		_sprite.frame = 4 if _attack_flash > ATTACK_FLASH_DURATION * 0.60 else 5
		target_scale = Vector2(0.94, 1.07) if _sprite.frame == 4 else Vector2(1.15, 0.92)
	elif breathe_held:
		_sprite.frame = 7
		target_scale.y += sin(_visual_time * 5.0) * 0.035
	elif walking:
		target_scale = Vector2(1.04, 0.96) if alternate else Vector2(0.98, 1.04)
	if pose_direction.x != 0.0:
		_sprite.flip_h = pose_direction.x < 0.0
	_sprite.scale = _sprite.scale.lerp(target_scale, 1.0 - exp(-delta * 22.0))
	if dashing:
		_ghost_remaining -= delta
		if _ghost_remaining <= 0.0:
			_ghost_remaining += 0.045
			_spawn_dash_ghost()
	if alternate != _alternate_frame:
		_alternate_frame = alternate
		if walking:
			_spawn_step_dust()
	_visual.queue_redraw()


func _spawn_dash_ghost() -> void:
	var ghost: Sprite2D = Sprite2D.new()
	ghost.texture = _sprite.texture
	ghost.hframes = _sprite.hframes
	ghost.frame = 6
	ghost.flip_h = _sprite.flip_h
	ghost.top_level = true
	ghost.z_index = -1
	ghost.modulate = Color(0.75, 1.0, 0.98, 0.44)
	_effects.add_child(ghost)
	ghost.global_transform = _sprite.global_transform
	var fade: Tween = ghost.create_tween()
	fade.tween_property(ghost, "modulate:a", 0.0, 0.14)
	fade.tween_callback(ghost.queue_free)


func _spawn_step_dust() -> void:
	for index: int in range(3):
		var dust: Polygon2D = Polygon2D.new()
		dust.polygon = PackedVector2Array([Vector2.ZERO, Vector2(2, 0), Vector2(2, 2), Vector2(0, 2)])
		dust.color = Color(0.86, 0.72, 0.55, 0.55)
		dust.top_level = true
		dust.z_index = -1
		_effects.add_child(dust)
		dust.global_position = global_position.round() + Vector2(index * 3 - 3, 8)
		var fade: Tween = dust.create_tween().set_parallel()
		fade.tween_property(dust, "global_position", dust.global_position - facing_direction * 6.0
				+ Vector2(index - 1, -4), 0.22)
		fade.tween_property(dust, "modulate:a", 0.0, 0.22)
		fade.chain().tween_callback(dust.queue_free)


func _on_clarity_ready_changed(_is_ready: bool) -> void:
	_visual.queue_redraw()


func _draw_visual() -> void:
	if _breathing_visual:
		for index: int in range(9):
			var phase: float = fposmod(_visual_time * 1.4 + index / 9.0, 1.0)
			var angle: float = index * TAU / 9.0 + phase * 0.65
			var point: Vector2 = (Vector2.from_angle(angle) * lerpf(25.0, 3.0, phase)).round()
			var color: Color = Color(0.56, 1.0, 0.86, sin(phase * PI) * 0.85)
			_visual.draw_rect(Rect2(point + Vector2(0, -7), Vector2(2, 2)), color)
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
	var life: float = _attack_flash / ATTACK_FLASH_DURATION
	var angle: float = _attack_direction.angle() + (0.5 - life) * 0.40
	var radius: float = _attack_range * lerpf(1.0, 0.84, life)
	var width: float = 15.0 if _attack_is_clarity else 9.0
	var glow: Color = Color("#39dcec") if _attack_is_clarity else Color("#fca34d")
	var edge: Color = Color("#edffff") if _attack_is_clarity else Color("#fff3c8")
	glow.a = life * 0.9
	edge.a = life
	_draw_slash_layer(angle, radius, width, glow)
	_draw_slash_layer(angle, radius - 1.0, width * 0.42, edge)


func _draw_slash_layer(angle: float, radius: float, width: float, color: Color) -> void:
	const SEGMENTS: int = 24
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(SEGMENTS + 1):
		var fraction: float = float(index) / SEGMENTS
		var direction: Vector2 = Vector2.from_angle(angle + lerpf(-_attack_half_angle, _attack_half_angle, fraction))
		points.append(direction * radius)
	for index: int in range(SEGMENTS - 1, 0, -1):
		var fraction: float = float(index) / SEGMENTS
		var direction: Vector2 = Vector2.from_angle(angle + lerpf(-_attack_half_angle, _attack_half_angle, fraction))
		points.append(direction * (radius - width * sin(fraction * PI)))
	_attack_arc.draw_colored_polygon(points, color)
