extends Node2D

signal wave_timer_updated(time_left: float, wave: int)
signal wave_intermission_requested(completed_wave: int)

const Player = preload("res://scenes/player/player.gd")
const Enemy = preload("res://scenes/enemies/enemy_base.gd")
const Ally = preload("res://scenes/enemies/ally_support.gd")
const HUD = preload("res://scenes/ui/hud.gd")
const HabitTerminal = preload("res://scenes/ui/habit_terminal.gd")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy_base.tscn")
const ALLY_SCENE: PackedScene = preload("res://scenes/enemies/ally_support.tscn")
const WAVE_DURATION: float = 45.0
const ALLY_AURA_RADIUS: float = 78.0
const PLAYFIELD: Rect2 = Rect2(16, 16, 608, 328)
const SPAWN_INTERVALS: Array[float] = [3.4, 3.0, 2.6, 5.8]
const SPAWN_POINTS: Array[Vector2] = [
	Vector2(490, 330), Vector2(22, 112), Vector2(618, 248), Vector2(150, 30),
	Vector2(542, 30), Vector2(22, 260), Vector2(618, 92), Vector2(168, 330),
]
const TURN_TINTS: Array[Color] = [
	Color("#c8d6eb"), Color("#e8bc8e"), Color("#7c86be"), Color("#96688a"),
]
const HALO_STRENGTHS: Array[float] = [0.45, 0.39, 1.0, 1.15]
const LANTERNS: Array[Vector2] = [
	Vector2(30, 56), Vector2(610, 56), Vector2(30, 326), Vector2(610, 326),
]
const WINDOWS: Array[Vector2] = [Vector2(216, 18), Vector2(424, 18)]
const AMBIENT_PARTICLE_COUNT: int = 18
const HALO_STEPS: int = 8
const CORE_HEALTHY: Color = Color("#81e6c0")
const CORE_CRITICAL: Color = Color("#ec626a")
const CORE_FLASH_DURATION: float = 0.12
const MAX_SPARKS: int = 96

class Spark:
	var point: Vector2
	var velocity: Vector2
	var color: Color
	var remaining: float
	var size: int

var _time_left: float = WAVE_DURATION
var _spawn_remaining: float = 0.0
var _spawn_index: int = 0
var _palette_index: int = 0
var _allies: Array[Ally] = []
var _last_core_hp: int
var _core_flash: float = 0.0
var _core_pulse: float = 0.0
var _shake_remaining: float = 0.0
var _shake_strength: float = 0.0
var _sparks: Array[Spark] = []
var _effects_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _camera: Camera2D
var _ambient_time: float = 0.0
var _dust_origins: PackedVector2Array = PackedVector2Array()

@onready var _player: Player = $Player
@onready var _courtyard: Sprite2D = $Courtyard
@onready var _atmosphere: Node2D = $Atmosphere
@onready var _core: Node2D = $CareCore
@onready var _core_sprite: Sprite2D = $CareCore/Sprite2D
@onready var _core_flash_material: ShaderMaterial = _core_sprite.material as ShaderMaterial
@onready var _enemy_container: Node2D = $Enemies
@onready var _ally_container: Node2D = $Allies
@onready var _hud: HUD = $HUD
@onready var _habit_terminal: HabitTerminal = $HabitTerminal


func _ready() -> void:
	_camera = Camera2D.new()
	_camera.position = PLAYFIELD.get_center()
	add_child(_camera)
	var dust_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	dust_rng.seed = 1212
	for index: int in range(AMBIENT_PARTICLE_COUNT):
		var cell: Vector2 = Vector2(index % 6, floorf(index / 6.0))
		var jitter: Vector2 = Vector2(dust_rng.randf_range(12, 78), dust_rng.randf_range(10, 62))
		_dust_origins.append(Vector2(38, 67) + cell * Vector2(94, 85) + jitter)
	_atmosphere.draw.connect(_draw_atmosphere)
	_core.draw.connect(_draw_core)
	_last_core_hp = GameManager.core_hp
	GameManager.core_hp_changed.connect(_on_core_hp_changed)
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.habits_updated.connect(_on_habits_updated)
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.run_started.connect(_on_run_started)
	_hud.bind_player(_player)
	_player.attacked.connect(_on_player_attacked)
	_player.clarity_hit.connect(_start_shake.bind(2.0, 0.14))
	_player.breathing_completed.connect(_on_breathing_completed)
	wave_timer_updated.connect(_hud.update_wave)
	_habit_terminal.bind_arena(choose_habit_and_continue)
	_on_wave_changed(GameManager.wave)
	_sync_allies()


func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	_update_ally_aura()
	_time_left = maxf(0.0, _time_left - delta)
	wave_timer_updated.emit(_time_left, GameManager.wave)
	if _time_left <= 0.0:
		_finish_wave()
		return

	_spawn_remaining -= delta
	if _spawn_remaining <= 0.0:
		_spawn_reinforcement(GameManager.wave)
		_spawn_remaining += SPAWN_INTERVALS[_palette_index]


func _process(delta: float) -> void:
	_core_pulse = fposmod(_core_pulse + delta, 2.4)
	_core_flash = maxf(0.0, _core_flash - delta)
	_update_core_sprite()
	_core.queue_redraw()
	_ambient_time = fposmod(_ambient_time + delta, TAU * 5.0)
	_atmosphere.queue_redraw()
	if not GameManager.screen_shake_enabled:
		_shake_remaining = 0.0
		_camera.offset = Vector2.ZERO
	elif _shake_remaining > 0.0:
		_shake_remaining = maxf(0.0, _shake_remaining - delta)
		var phase: int = ceili(_shake_remaining * 30.0)
		var strength: float = minf(_shake_strength, float(phase))
		_camera.offset = Vector2(strength, floorf(strength * 0.5)) * (-1 if phase % 2 == 0 else 1)
	if _sparks.is_empty():
		return
	for index: int in range(_sparks.size() - 1, -1, -1):
		var spark: Spark = _sparks[index]
		spark.remaining -= delta
		if spark.remaining <= 0.0:
			_sparks.remove_at(index)
			continue
		spark.point += spark.velocity * delta
		spark.velocity.y += 80.0 * delta
	queue_redraw()


func _start_shake(strength: float, duration: float) -> void:
	if not GameManager.screen_shake_enabled:
		_shake_remaining = 0.0
		_camera.offset = Vector2.ZERO
		return
	_shake_strength = maxf(strength, _shake_strength if _shake_remaining > 0.0 else 0.0)
	_shake_remaining = maxf(_shake_remaining, duration)


func _burst(origin: Vector2, color: Color, count: int, direction: Vector2 = Vector2.ZERO) -> void:
	for index: int in range(mini(count, MAX_SPARKS - _sparks.size())):
		var spark: Spark = Spark.new()
		var angle: float = _effects_rng.randf_range(-PI, PI)
		var heading: Vector2 = Vector2.from_angle(angle)
		if direction != Vector2.ZERO:
			heading = direction.rotated(angle * 0.28)
		spark.point = to_local(origin) + heading * 4.0
		spark.velocity = heading * _effects_rng.randf_range(28.0, 100.0)
		spark.color = color.lightened(0.35) if index % 3 == 0 else color
		spark.remaining = _effects_rng.randf_range(0.16, 0.36)
		spark.size = 3 if index % 3 == 0 else 2
		_sparks.append(spark)
	queue_redraw()


func _on_player_attacked(is_clarity: bool, origin: Vector2, direction: Vector2,
		attack_range: float, _damage: int) -> void:
	if is_clarity:
		_burst(origin + direction * attack_range * 0.65, Color("#89ffe0"), 16, direction)


func _on_breathing_completed() -> void:
	_burst(_player.global_position, Color("#a6f9f2"), 12)


func choose_habit_and_continue(choice: String) -> void:
	if GameManager.current_state != GameManager.GameState.HABIT_SELECT:
		return
	if choice not in ["sleep", "nutrition", "connection"]:
		return
	if choice == "connection" and GameManager.ally_count >= GameManager.MAX_ALLIES:
		return
	GameManager.apply_habit_choice(choice)
	GameManager.advance_wave()


func _finish_wave() -> void:
	var completed_wave: int = GameManager.wave
	if completed_wave == GameManager.MAX_WAVES:
		if GameManager.core_hp > 0:
			GameManager.set_state(GameManager.GameState.VICTORY)
		return
	_clear_enemies()
	GameManager.set_state(GameManager.GameState.HABIT_SELECT)
	wave_intermission_requested.emit(completed_wave)


func _on_wave_changed(new_wave: int) -> void:
	_clear_enemies()
	_palette_index = clampi(new_wave - 1, 0, TURN_TINTS.size() - 1)
	_time_left = WAVE_DURATION
	_spawn_remaining = 3.0 if new_wave == GameManager.MAX_WAVES else 0.8
	_spawn_index = 0
	_courtyard.self_modulate = TURN_TINTS[_palette_index]
	wave_timer_updated.emit(_time_left, new_wave)
	if new_wave == GameManager.MAX_WAVES:
		var boss: Enemy = _spawn_enemy(Enemy.EnemyType.EXHAUSTION_BOSS, Vector2(320, 34))
		boss.defeated.connect(_on_boss_defeated)
		boss.boss_pulsed.connect(_start_shake.bind(2.0, 0.18))


func _on_state_changed(new_state: GameManager.GameState) -> void:
	if new_state in [GameManager.GameState.MENU, GameManager.GameState.VICTORY,
			GameManager.GameState.GAME_OVER]:
		_clear_enemies()


func _on_run_started() -> void:
	_sparks.clear()
	queue_redraw()
	_shake_remaining = 0.0
	_camera.offset = Vector2.ZERO
	_core_flash = 0.0
	_player.position = Vector2(320, 219)
	_player.reset_run()
	_on_wave_changed(GameManager.wave)


func _on_boss_defeated() -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING and GameManager.core_hp > 0:
		GameManager.set_state(GameManager.GameState.VICTORY)


func _spawn_reinforcement(wave: int) -> void:
	var enemy_type: Enemy.EnemyType = Enemy.EnemyType.ROUTINE_PRESSURE
	match wave:
		2:
			if _spawn_index % 3 == 2:
				enemy_type = Enemy.EnemyType.FATIGUE
		3:
			match _spawn_index % 4:
				1:
					enemy_type = Enemy.EnemyType.GRIEF_GUILT
				3:
					enemy_type = Enemy.EnemyType.FATIGUE
		4:
			if _spawn_index % 3 == 1:
				enemy_type = Enemy.EnemyType.GRIEF_GUILT
	_spawn_enemy(enemy_type, SPAWN_POINTS[_spawn_index % SPAWN_POINTS.size()])
	_spawn_index += 1


func _spawn_enemy(enemy_type: Enemy.EnemyType, point: Vector2) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.enemy_type = enemy_type
	enemy.position = point
	enemy.core_position = _core.global_position
	enemy.player = _player
	enemy.defeated.connect(_on_enemy_defeated.bind(enemy))
	_enemy_container.add_child(enemy)
	return enemy


func _on_enemy_defeated(enemy: Enemy) -> void:
	_burst(enemy.global_position, Enemy.COLORS[enemy.enemy_type], 16)


func _clear_enemies() -> void:
	for enemy: Node in _enemy_container.get_children():
		enemy.queue_free()


func _on_habits_updated(_sleep_rank: int, _nutrition_rank: int, _ally_count: int) -> void:
	_sync_allies()


func _sync_allies() -> void:
	while _allies.size() > GameManager.ally_count:
		var ally: Ally = _allies.pop_back()
		ally.queue_free()
	while _allies.size() < GameManager.ally_count:
		var ally: Ally = ALLY_SCENE.instantiate() as Ally
		ally.core_position = _core.global_position
		ally.orbit_slot = _allies.size()
		_ally_container.add_child(ally)
		_allies.append(ally)
	_update_ally_aura()


func _update_ally_aura() -> void:
	var distance: float = _player.global_position.distance_to(_core.global_position)
	_player.is_in_ally_aura = GameManager.ally_count > 0 and distance <= ALLY_AURA_RADIUS


func _on_core_hp_changed(new_hp: int, _max_hp: int) -> void:
	if new_hp < _last_core_hp and GameManager.current_state == GameManager.GameState.PLAYING:
		_core_flash = CORE_FLASH_DURATION
		_update_core_sprite()
		_burst(_core.global_position, CORE_CRITICAL, 18)
		_start_shake(3.0, 0.18)
	_last_core_hp = new_hp
	_core.queue_redraw()


func _draw() -> void:
	for spark: Spark in _sparks:
		var color: Color = spark.color
		color.a = minf(1.0, spark.remaining / 0.12)
		draw_rect(Rect2(spark.point.round(), Vector2(spark.size, spark.size)), color)


func _draw_atmosphere() -> void:
	var warmth: Color = Color("#ffc370")
	for point: Vector2 in LANTERNS:
		_draw_halo(point, 31.0, warmth, 0.028)
	for point: Vector2 in WINDOWS:
		_draw_halo(point, 27.0, warmth, 0.028)
	_draw_halo(_core.position, 40.0, Color("#72e9bb"), 0.023)

	for index: int in range(_dust_origins.size()):
		var phase: float = index * 2.39996
		var drift: Vector2 = Vector2(sin(_ambient_time * 0.4 + phase) * 11.0,
				cos(_ambient_time * 0.6 + phase) * 8.0)
		var point: Vector2 = (_dust_origins[index] + drift).round()
		var alpha: float = (0.11 + 0.08 * sin(_ambient_time * 1.2 + phase))
		warmth.a = alpha * HALO_STRENGTHS[_palette_index]
		_atmosphere.draw_rect(Rect2(point, Vector2.ONE), warmth)


func _draw_halo(center: Vector2, radius: float, color: Color, opacity: float) -> void:
	color.a = opacity * HALO_STRENGTHS[_palette_index]
	for ring: int in range(HALO_STEPS, 0, -1):
		_atmosphere.draw_circle(center, radius * float(ring) / HALO_STEPS, color)


func _update_core_sprite() -> void:
	var ratio: float = float(GameManager.core_hp) / GameManager.max_core_hp
	_core_sprite.frame = int(_core_pulse * 5.0) % _core_sprite.hframes
	_core_sprite.position.y = -8.0 - roundf(sin(_core_pulse * TAU / 2.4) * 2.0)
	_core_sprite.self_modulate = Color("#f0808b").lerp(Color.WHITE, ratio)
	_core_flash_material.set_shader_parameter(&"hit_flash", _core_flash / CORE_FLASH_DURATION)


func _draw_core() -> void:
	var ratio: float = float(GameManager.core_hp) / GameManager.max_core_hp
	var pulse: float = 0.5 - 0.5 * cos(_core_pulse * TAU / 2.4)
	if GameManager.ally_count > 0:
		var aura: Color = Color(0.55, 1.0, 0.80, 0.23 + pulse * 0.12)
		for index: int in range(64):
			var point: Vector2 = (Vector2.from_angle(index * TAU / 64) * ALLY_AURA_RADIUS).round()
			_core.draw_rect(Rect2(point - Vector2.ONE, Vector2(2, 2)), aura)
	var health_color: Color = CORE_CRITICAL.lerp(CORE_HEALTHY, ratio)
	_core.draw_rect(Rect2(-17, 24, 34, 4), Color("#32263a"))
	_core.draw_rect(Rect2(-16, 25, roundf(32.0 * ratio), 2), health_color)
