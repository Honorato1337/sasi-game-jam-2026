extends Node
## Run after --import with --headless --path sasi-game-jam-2026 res://tools/validate_t012.tscn.

const Arena = preload("res://scenes/levels/arena.gd")
const Enemy = preload("res://scenes/enemies/enemy_base.gd")
const Player = preload("res://scenes/player/player.gd")
const ARENA: PackedScene = preload("res://scenes/levels/arena.tscn")
const TURN_COLORS: Array[String] = ["c8d6eb", "e8bc8e", "7c86be", "96688a"]
const ENEMY_SHEETS: Array[String] = ["routine", "fatigue", "grief", "boss"]

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var arena: Arena = ARENA.instantiate() as Arena
	add_child(arena)
	var player: Player = arena.get_node("Player")
	var courtyard: Sprite2D = arena.get_node("Courtyard")
	var core: Sprite2D = arena.get_node("CareCore/Sprite2D")
	var antonio: Sprite2D = player.get_node("Visual/Sprite2D")
	var enemies: Node2D = arena.get_node("Enemies")
	var allies: Node2D = arena.get_node("Allies")
	var habits: CanvasLayer = arena.get_node("HabitTerminal")
	var screens: CanvasLayer = arena.get_node("TitleEndScreens")

	_check(GameManager.current_state == GameManager.GameState.MENU and screens.visible, "MENU")
	_sprite(courtyard, "arena_bg", 1)
	_sprite(core, "care_core_sheet", 4)
	_sprite(antonio, "seu_antonio_sheet", 4)
	_check(not courtyard.centered and courtyard.z_index < 0, "Backdrop alignment and layer")
	_check(arena._dust_origins.size() == 18, "18 ambient particles")
	_key(KEY_ENTER)
	_check(GameManager.current_state == GameManager.GameState.PLAYING and not screens.visible,
			"PLAYING via Enter")

	Input.action_press(&"move_left")
	for frame: int in range(10):
		await get_tree().physics_frame
	Input.action_release(&"move_left")
	_check(player.position.x < 320.0 and antonio.frame == 3 and antonio.flip_h, "Walk left")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(antonio.frame == 0 and antonio.flip_h, "Idle preserves horizontal facing")
	player._update_visual_animation(0.55, false)
	_check(antonio.frame == 1, "Second idle frame")

	var routine: Enemy = arena._spawn_enemy(Enemy.EnemyType.ROUTINE_PRESSURE,
			player.global_position + Vector2(-20, 0))
	var other: Enemy = arena._spawn_enemy(Enemy.EnemyType.FATIGUE, Vector2(520, 190))
	var grief: Enemy = arena._spawn_enemy(Enemy.EnemyType.GRIEF_GUILT, Vector2(540, 210))
	for enemy: Enemy in [routine, other, grief]:
		_sprite(enemy.get_node("Sprite2D"), "enemy_%s_sheet" % ENEMY_SHEETS[enemy.enemy_type], 2)
	_check_enemy_animation(other)
	player._attack()
	_check(routine.hp == 10 and _flash(routine.get_node("Sprite2D")) == 1.0, "Attack and enemy flash")
	_check(_flash(other.get_node("Sprite2D")) == 0.0, "Flash isolated per enemy")
	routine._physics_process(0.10)
	_check(_flash(routine.get_node("Sprite2D")) == 0.0, "Enemy flash expires")
	_check(player.apply_enemy_contact(routine.global_position) and _flash(antonio) == 1.0,
			"Contact hit and player flash")
	player._physics_process(0.10)
	_check(_flash(antonio) == 0.0, "Player flash expires")
	player._update_breathing(GameManager.get_breathe_duration(), true)
	_check(GameManager.clarity_ready and not arena._sparks.is_empty(), "Breathing prepares Clarity")
	player._attack()
	_check(not GameManager.clarity_ready and routine.is_queued_for_deletion(), "Clarity defeats enemy")
	arena._process(0.03)
	_check(arena._camera.offset != Vector2.ZERO, "Clarity screen shake")
	arena._process(0.50)
	_check(arena._camera.offset == Vector2.ZERO and arena._sparks.is_empty(), "Shake and sparks expire")

	var before: int = GameManager.core_hp
	arena._spawn_enemy(Enemy.EnemyType.ROUTINE_PRESSURE, core.global_position)._physics_process(0.01)
	arena._process(0.01)
	_check(GameManager.core_hp == before - 8 and _flash(core) > 0.0, "Core impact and white flash")
	_check(core.self_modulate != Color.WHITE and not arena._sparks.is_empty(), "Core damage tint and sparks")
	arena._process(0.50)
	GameManager.heal_core(8)
	arena._process(0.0)
	_check(_flash(core) == 0.0 and core.self_modulate == Color.WHITE, "Core healing has no flash")
	var core_frames: Dictionary = {}
	for frame: int in range(4):
		arena._process(0.20)
		core_frames[core.frame] = true
	_check(core_frames.size() == 4, "Core animates all four frames")

	for wave: int in range(1, 5):
		_check(GameManager.wave == wave and courtyard.self_modulate == Color(TURN_COLORS[wave - 1]),
				"Wave %d and turn tint" % wave)
		if wave == 4:
			break
		var spawn_index: int = arena._spawn_index
		arena._physics_process(arena._spawn_remaining + 0.01)
		_check(arena._spawn_index == spawn_index + 1, "Wave %d reinforcement" % wave)
		arena._physics_process(arena._time_left)
		_check(GameManager.current_state == GameManager.GameState.HABIT_SELECT and habits.visible,
				"Wave %d timer opens HABIT_SELECT" % wave)
		_key(KEY_3)
		_check(GameManager.current_state == GameManager.GameState.PLAYING and not habits.visible,
				"Wave %d starts via habit UI" % (wave + 1))
		var ally: Sprite2D = allies.get_child(wave - 1).get_node("Sprite2D")
		_sprite(ally, "allies_sheet", 3)
		_check(ally.frame == wave - 1 and player.is_in_ally_aura, "Ally slot %d and aura" % wave)

	var boss: Enemy = enemies.get_child(enemies.get_child_count() - 1)
	_check(boss.enemy_type == Enemy.EnemyType.EXHAUSTION_BOSS, "Boss spawns in wave 4")
	_sprite(boss.get_node("Sprite2D"), "enemy_boss_sheet", 2)
	boss._update_boss(6.0)
	_check(boss._pulse_age == 0.0 and arena._shake_remaining > 0.0, "Boss pulse and shake")
	for hit: int in range(3):
		boss.take_damage(55, true)
		_check(boss.hp == maxi(0, 320 - 110 * (hit + 1)), "Boss Clarity hit %d" % (hit + 1))
	_check(GameManager.current_state == GameManager.GameState.VICTORY and screens.visible, "VICTORY")
	_key(KEY_ENTER)
	_check(GameManager.current_state == GameManager.GameState.PLAYING and GameManager.wave == 1
			and GameManager.ally_count == 0 and arena._camera.offset == Vector2.ZERO, "Restart")
	for impact: int in range(13):
		arena._spawn_enemy(Enemy.EnemyType.ROUTINE_PRESSURE, core.global_position)._physics_process(0.01)
	_check(GameManager.current_state == GameManager.GameState.GAME_OVER and screens.visible,
			"GAME_OVER via enemy impacts")

	# Let the audio mixer release streams before headless shutdown.
	AudioManager.stop_music()
	for voice: AudioStreamPlayer in AudioManager.sfx_players:
		voice.stop()
	await get_tree().create_timer(0.15).timeout
	print("%d passed, %d failed" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func _check_enemy_animation(enemy: Enemy) -> void:
	enemy._physics_process(0.18)
	var sprite: Sprite2D = enemy.get_node("Sprite2D")
	_check(sprite.frame == 1 and sprite.flip_h, "Enemy step animation and target facing")


func _key(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	get_viewport().push_input(event)


func _flash(sprite: Sprite2D) -> float:
	var material: ShaderMaterial = sprite.material as ShaderMaterial
	return material.get_shader_parameter(&"hit_flash")


func _sprite(sprite: Sprite2D, file: String, frames: int) -> void:
	_check(sprite.texture != null and sprite.texture.resource_path.ends_with("/%s.png" % file)
			and sprite.hframes == frames and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
			"Texture, frames and Nearest for " + file)


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("PASS ", description)
	else:
		_failed += 1
		push_error("FAIL " + description)
