extends Node
## Run after --import with --headless --path sasi-game-jam-2026 res://tools/validate_t012.tscn.

const Arena = preload("res://scenes/levels/arena.gd")
const Enemy = preload("res://scenes/enemies/enemy_base.gd")
const Player = preload("res://scenes/player/player.gd")
const Screens = preload("res://scenes/ui/title_end_screens.gd")
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
	var screens: Screens = arena.get_node("TitleEndScreens")

	_check(GameManager.current_state == GameManager.GameState.MENU and screens.visible, "MENU")
	_sprite(courtyard, "arena_bg", 1)
	_sprite(core, "care_core_sheet", 4)
	_sprite(antonio, "seu_antonio_sheet", 8)
	_check(antonio.get_rect().size == Vector2(32, 32), "Antônio frame size")
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
	player._update_visual_animation(0.02, false, true)
	_check(antonio.frame == 7 and player._breathing_visual, "Breathing pose and particles")
	player._dash_direction = Vector2.LEFT
	player._update_visual_animation(0.02, false, false, true)
	_check(antonio.frame == 6 and antonio.scale.x > 1.0 and player._effects.get_child_count() > 0,
			"Dash pose, stretch and ghost")

	var hits: Array[Array] = []
	player.enemy_hit.connect(func(at: Vector2, damage: int, clarity: bool, is_boss: bool) -> void:
		hits.append([at, damage, clarity, is_boss]))

	var routine: Enemy = arena._spawn_enemy(Enemy.EnemyType.ROUTINE_PRESSURE,
			player.global_position + Vector2(-20, 0))
	var other: Enemy = arena._spawn_enemy(Enemy.EnemyType.FATIGUE, Vector2(520, 190))
	var grief: Enemy = arena._spawn_enemy(Enemy.EnemyType.GRIEF_GUILT, Vector2(540, 210))
	for enemy: Enemy in [routine, other, grief]:
		_sprite(enemy.get_node("Sprite2D"), "enemy_%s_sheet" % ENEMY_SHEETS[enemy.enemy_type], 2)
	_check_enemy_animation(other)
	player._attack()
	player._update_visual_animation(0.01, false)
	_check(antonio.frame == 4, "Attack windup pose")
	_check(hits == [[routine.global_position, 20, false, false]]
			and routine._knockback == Vector2.LEFT * 95.0, "Normal hit signal and knockback")
	_check(routine.hp == 10 and _flash(routine.get_node("Sprite2D")) == 1.0, "Attack and enemy flash")
	_check(_flash(other.get_node("Sprite2D")) == 0.0, "Flash isolated per enemy")
	routine._physics_process(0.10)
	_check(_flash(routine.get_node("Sprite2D")) == 0.0, "Enemy flash expires")
	_check(player.apply_enemy_contact(routine.global_position) and _flash(antonio) == 1.0,
			"Contact hit and player flash")
	player._physics_process(0.10)
	_check(antonio.frame == 5, "Attack swing pose")
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
	boss._update_boss(4.99)
	_check(boss._boss_warning_strength() == 0.0, "No boss warning outside the final second")
	boss._update_boss(0.02)
	_check(boss._boss_warning_strength() > 0.0, "Boss warns during the final second")
	boss._update_boss(1.0)
	_check(boss._pulse_age == 0.0 and arena._shake_remaining > 0.0, "Boss pulse and shake")
	boss.global_position = player.global_position + Vector2(20, 0)
	player.facing_direction = Vector2.RIGHT
	GameManager.complete_breathing()
	player._attack()
	_check(hits.back() == [boss.global_position, 110, true, true] and boss.hp == 210
			and boss._knockback == Vector2.RIGHT * 220.0, "Boss Clarity hit signal and knockback")
	for hit: int in range(1, 3):
		boss.take_damage(55, true)
		_check(boss.hp == maxi(0, 320 - 110 * (hit + 1)), "Boss Clarity hit %d" % (hit + 1))
	_check(GameManager.current_state == GameManager.GameState.VICTORY and screens.visible, "VICTORY")
	_check_summary(screens)
	_key(KEY_ENTER)
	_check(GameManager.current_state == GameManager.GameState.PLAYING and GameManager.wave == 1
			and GameManager.ally_count == 0 and arena._camera.offset == Vector2.ZERO, "Restart")
	for impact: int in range(13):
		arena._spawn_enemy(Enemy.EnemyType.ROUTINE_PRESSURE, core.global_position)._physics_process(0.01)
	_check(GameManager.current_state == GameManager.GameState.GAME_OVER and screens.visible,
			"GAME_OVER via enemy impacts")
	_check_summary(screens)
	_key(KEY_RIGHT)
	_key(KEY_ENTER)
	_check(GameManager.current_state == GameManager.GameState.MENU, "End screen returns to menu")
	await _check_menus(arena, screens)

	# Let the audio mixer release streams before headless shutdown.
	AudioManager.stop_music()
	for voice: AudioStreamPlayer in AudioManager.sfx_players:
		voice.stop()
	await get_tree().create_timer(0.15).timeout
	print("%d passed, %d failed" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func _check_summary(screens: Screens) -> void:
	var actions: Array = screens._buttons[screens._end_window]
	_check(screens._stats.text.contains("Onda") and screens._stats.text.contains("Núcleo")
			and screens._stats.text.contains("Rede de Apoio") and actions.size() == 2
			and actions[0].position.y == actions[1].position.y, "Summary and side-by-side end actions")


func _check_menus(arena: Arena, screens: Screens) -> void:
	var title_actions: Array = screens._buttons[screens._title_window]
	var title_thumbnails: int = 0
	for child: Node in screens._title_window.get_children():
		var thumbnail: TextureRect = child as TextureRect
		if thumbnail == null:
			continue
		var atlas: AtlasTexture = thumbnail.texture as AtlasTexture
		var frame_size: Vector2 = Vector2(32, 32) if title_thumbnails == 0 else Vector2(48, 56)
		_check(atlas != null and atlas.region.position == Vector2.ZERO
				and atlas.region.size == frame_size
				and thumbnail.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Nearest thumbnail frame 0")
		title_thumbnails += 1
	_check(title_thumbnails == 2 and title_actions.size() == (4 if OS.has_feature("web") else 5),
			"Title thumbnails and platform-specific actions")

	_key(KEY_S)
	_key(KEY_ENTER)
	_check(screens._help_window.visible and not screens._title_window.visible, "Open help via S and Enter")
	_key(KEY_ESCAPE)
	_check(screens._title_window.visible and get_viewport().gui_get_focus_owner() == title_actions[1],
			"Escape returns from help and restores focus")
	_click(title_actions[3])
	_check(screens._credits_window.visible, "Open credits via mouse")
	_key(KEY_ENTER)
	_check(screens._title_window.visible, "Credits back button via Enter")
	_key(KEY_W)
	_key(KEY_ENTER)
	_check(screens._settings_window.visible and not screens._title_window.visible, "Open settings from title")
	await _check_settings(screens)
	_key(KEY_ESCAPE)
	_check(screens._title_window.visible and get_viewport().gui_get_focus_owner() == title_actions[2],
			"Settings return to title")
	_key(KEY_UP)
	_key(KEY_UP)
	_key(KEY_ENTER)
	_check(not screens.visible and GameManager.current_state == GameManager.GameState.PLAYING,
			"Start from title via arrow keys and Enter")

	arena._start_shake(3.0, 0.2)
	arena._process(0.01)
	var time_left: float = arena._time_left
	_key(KEY_P)
	arena._physics_process(1.0)
	_check(screens._pause_window.visible and GameManager.current_state == GameManager.GameState.PAUSED
			and arena._time_left == time_left, "P pauses and freezes wave timer")
	_key(KEY_DOWN)
	_key(KEY_ENTER)
	_check(screens._settings_window.visible and not screens._pause_window.visible
			and GameManager.current_state == GameManager.GameState.PAUSED, "Open settings from pause")
	_click(screens._shake_button)
	arena._process(0.01)
	_check(not GameManager.screen_shake_enabled and arena._camera.offset == Vector2.ZERO
			and arena._shake_remaining == 0.0, "Disable an active shake from pause settings")
	arena._start_shake(3.0, 0.2)
	_check(arena._shake_remaining == 0.0 and arena._camera.offset == Vector2.ZERO, "Disabled shake cannot start")
	_click(screens._shake_button)
	arena._start_shake(3.0, 0.2)
	arena._process(0.01)
	_check(GameManager.screen_shake_enabled and arena._camera.offset != Vector2.ZERO, "Re-enable shake")
	_key(KEY_ESCAPE)
	_check(screens._pause_window.visible and GameManager.current_state == GameManager.GameState.PAUSED,
			"Settings Escape returns to pause without resuming")
	_key(KEY_ESCAPE)
	_check(not screens.visible and arena._time_left == time_left
			and GameManager.current_state == GameManager.GameState.PLAYING, "Escape resumes the existing run")

	GameManager.damage_core(10)
	arena._physics_process(2.0)
	var player: Player = arena.get_node("Player")
	player.position = Vector2(100, 100)
	_key(KEY_ESCAPE)
	_check(screens._pause_window.visible, "Escape opens pause")
	_key(KEY_ENTER)
	_check(GameManager.current_state == GameManager.GameState.PLAYING and GameManager.core_hp == 90,
			"Continue button preserves progress")
	_key(KEY_P)
	_key(KEY_DOWN)
	_key(KEY_DOWN)
	_key(KEY_ENTER)
	_check(GameManager.current_state == GameManager.GameState.PLAYING and GameManager.wave == 1
			and GameManager.core_hp == GameManager.max_core_hp and arena._time_left == Arena.WAVE_DURATION
			and player.position == Vector2(320, 219) and arena._camera.offset == Vector2.ZERO,
			"Restart from pause resets wave one, health, player and camera")
	_key(KEY_P)
	_key(KEY_UP)
	_key(KEY_ENTER)
	_check(screens._title_window.visible and GameManager.current_state == GameManager.GameState.MENU,
			"Pause menu returns to title")


func _check_settings(screens: Screens) -> void:
	for _frame: int in range(120):
		if AudioManager._effects.has(&"habit_select"):
			break
		await get_tree().process_frame
	var actions: Array = screens._buttons[screens._settings_window]
	_key(KEY_ENTER)
	_check(screens._music_value.text == "90%" and is_equal_approx(AudioManager.music_volume, 0.9)
			and is_equal_approx(AudioManager.music_player.volume_db,
					AudioManager._music_volume_db + linear_to_db(0.9)), "Music decrement applies immediately")
	_click(actions[1])
	_check(screens._music_value.text == "100%" and AudioManager.music_volume == 1.0, "Music increment")
	var voice_index: int = AudioManager._next_sfx_player_index
	_click(actions[2])
	_check(screens._sfx_value.text == "90%" and is_equal_approx(AudioManager.sfx_volume, 0.9)
			and AudioManager.sfx_players[voice_index].stream == AudioManager._effects.get(&"habit_select")
			and AudioManager._next_sfx_player_index != voice_index, "SFX decrement previews cue")
	_click(screens._mute_button)
	_check(AudioManager.muted and screens._mute_button.text == "MUDO"
			and AudioManager.music_player.volume_db == -80.0
			and AudioManager.sfx_players[voice_index].volume_db == -80.0, "Mute applies to music and SFX")
	_click(screens._mute_button)
	_check(not AudioManager.muted and screens._mute_button.text == "ATIVO"
			and is_equal_approx(AudioManager.music_player.volume_db, AudioManager._music_volume_db)
			and is_equal_approx(AudioManager.sfx_players[voice_index].volume_db,
					AudioManager._sfx_volumes_db[voice_index] + linear_to_db(0.9)), "Unmute restores individual gains")
	_click(actions[3])
	_check(screens._sfx_value.text == "100%" and AudioManager.sfx_volume == 1.0, "SFX increment")
	AudioManager.set_music_volume(-1.0)
	AudioManager.set_sfx_volume(-1.0)
	_check(AudioManager.music_volume == 0.0 and AudioManager.sfx_volume == 0.0
			and AudioManager.music_player.volume_db == -80.0
			and AudioManager.sfx_players[voice_index].volume_db == -80.0, "Zero gain and lower clamp")
	AudioManager.set_music_volume(2.0)
	AudioManager.set_sfx_volume(2.0)
	_check(AudioManager.music_volume == 1.0 and AudioManager.sfx_volume == 1.0, "Upper volume clamp")
	if DisplayServer.get_name() == "headless":
		_check(screens._fullscreen_button.disabled and screens._fullscreen_button.text == "JANELA",
				"Fullscreen disabled on headless display")
	else:
		var was_fullscreen: bool = screens._is_fullscreen()
		_click(screens._fullscreen_button)
		await get_tree().process_frame
		_check(screens._is_fullscreen() != was_fullscreen, "Fullscreen switches display mode")
		_click(screens._fullscreen_button)
		await get_tree().process_frame
		_check(screens._is_fullscreen() == was_fullscreen, "Fullscreen restores previous display mode")


func _click(button: Button) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button.get_global_rect().get_center()
		event.pressed = pressed
		get_viewport().push_input(event, true)


func _check_enemy_animation(enemy: Enemy) -> void:
	enemy._physics_process(0.42)
	var sprite: Sprite2D = enemy.get_node("Sprite2D")
	_check(sprite.frame == 1 and sprite.flip_h and absf(sprite.rotation) > 0.0,
			"Fatigue step, sway and target facing")


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
