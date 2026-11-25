extends Node2D

const Player = preload("res://scenes/player/player.gd")
const Enemy = preload("res://scenes/enemies/enemy_base.gd")
const Ally = preload("res://scenes/enemies/ally_support.gd")
const Station = preload("res://scenes/objects/care_station.gd")
const HUD = preload("res://scenes/ui/hud.gd")
const StoryDialog = preload("res://scenes/ui/story_dialog.gd")
const CutscenePlayer = preload("res://scenes/ui/cutscene_player.gd")
const ENEMY_SCENE = preload("res://scenes/enemies/enemy_base.tscn")
const ALLY_SCENE = preload("res://scenes/enemies/ally_support.tscn")
const STATION_SCENE = preload("res://scenes/objects/care_station.tscn")
const ROOM_ART: Array[Texture2D] = [
	preload("res://assets/sprites/room_morning.png"),
	preload("res://assets/sprites/room_afternoon.png"),
	preload("res://assets/sprites/room_night.png"),
	preload("res://assets/sprites/room_c2_morning.png"),
	preload("res://assets/sprites/room_c2_afternoon.png"),
	preload("res://assets/sprites/room_c2_night.png"),
	preload("res://assets/sprites/room_c3_morning.png"),
	preload("res://assets/sprites/room_c3_afternoon.png"),
	preload("res://assets/sprites/room_c3_night.png"),
]
const ROOM_DIALOGUES: Array[String] = [
	"room_1_morning", "room_2_afternoon", "room_3_night",
	"room_4_c2_morning", "room_5_c2_afternoon", "room_6_c2_night",
	"room_7_c3_morning", "room_8_c3_afternoon", "room_9_c3_night",
]
const ROOM_LIGHT: Array[Color] = [Color("#ffc370"), Color("#f1a875"), Color("#9599ff")]
const MORNING_C1: Array[Enemy.EnemyType] = [
	Enemy.EnemyType.PROCRASTINATION, Enemy.EnemyType.DEADLINE, Enemy.EnemyType.PROCRASTINATION,
	Enemy.EnemyType.DEADLINE, Enemy.EnemyType.PROCRASTINATION, Enemy.EnemyType.SELF_CRITICISM,
]
const AFTERNOON_C1: Array[Enemy.EnemyType] = [
	Enemy.EnemyType.DEADLINE, Enemy.EnemyType.PROCRASTINATION, Enemy.EnemyType.SELF_CRITICISM,
	Enemy.EnemyType.PROCRASTINATION, Enemy.EnemyType.SELF_CRITICISM, Enemy.EnemyType.DEADLINE,
	Enemy.EnemyType.PROCRASTINATION,
]
const NIGHT_C1: Array[Enemy.EnemyType] = [
	Enemy.EnemyType.SELF_CRITICISM, Enemy.EnemyType.DEADLINE, Enemy.EnemyType.PROCRASTINATION,
	Enemy.EnemyType.SELF_CRITICISM, Enemy.EnemyType.DEADLINE, Enemy.EnemyType.PROCRASTINATION,
	Enemy.EnemyType.SELF_CRITICISM, Enemy.EnemyType.DEADLINE,
]
const MORNING_C2: Array[Enemy.EnemyType] = [
	Enemy.EnemyType.PROCRASTINATION, Enemy.EnemyType.DEADLINE, Enemy.EnemyType.PROCRASTINATION,
	Enemy.EnemyType.SELF_CRITICISM, Enemy.EnemyType.DEADLINE, Enemy.EnemyType.PROCRASTINATION,
	Enemy.EnemyType.SELF_CRITICISM, Enemy.EnemyType.DEADLINE,
]
const AFTERNOON_C2: Array[Enemy.EnemyType] = [
	Enemy.EnemyType.DEADLINE, Enemy.EnemyType.SELF_CRITICISM, Enemy.EnemyType.PROCRASTINATION,
	Enemy.EnemyType.DEADLINE, Enemy.EnemyType.SELF_CRITICISM, Enemy.EnemyType.PROCRASTINATION,
	Enemy.EnemyType.DEADLINE, Enemy.EnemyType.SELF_CRITICISM, Enemy.EnemyType.PROCRASTINATION,
]
const NIGHT_C2: Array[Enemy.EnemyType] = [
	Enemy.EnemyType.SELF_CRITICISM, Enemy.EnemyType.DEADLINE, Enemy.EnemyType.PROCRASTINATION,
	Enemy.EnemyType.SELF_CRITICISM, Enemy.EnemyType.DEADLINE, Enemy.EnemyType.PROCRASTINATION,
	Enemy.EnemyType.SELF_CRITICISM, Enemy.EnemyType.DEADLINE, Enemy.EnemyType.PROCRASTINATION,
	Enemy.EnemyType.SELF_CRITICISM,
]
const MORNING_C3: Array[Enemy.EnemyType] = [
	Enemy.EnemyType.DEADLINE, Enemy.EnemyType.PROCRASTINATION, Enemy.EnemyType.SELF_CRITICISM,
	Enemy.EnemyType.DEADLINE, Enemy.EnemyType.SELF_CRITICISM, Enemy.EnemyType.PROCRASTINATION,
	Enemy.EnemyType.DEADLINE, Enemy.EnemyType.PROCRASTINATION, Enemy.EnemyType.SELF_CRITICISM,
	Enemy.EnemyType.DEADLINE,
]
const AFTERNOON_C3: Array[Enemy.EnemyType] = [
	Enemy.EnemyType.SELF_CRITICISM, Enemy.EnemyType.DEADLINE, Enemy.EnemyType.PROCRASTINATION,
	Enemy.EnemyType.SELF_CRITICISM, Enemy.EnemyType.DEADLINE, Enemy.EnemyType.SELF_CRITICISM,
	Enemy.EnemyType.PROCRASTINATION, Enemy.EnemyType.DEADLINE, Enemy.EnemyType.PROCRASTINATION,
	Enemy.EnemyType.SELF_CRITICISM, Enemy.EnemyType.DEADLINE, Enemy.EnemyType.PROCRASTINATION,
]
const SPAWN_POINTS: Array[Vector2] = [
	Vector2(250, 345), Vector2(710, 350), Vector2(345, 225), Vector2(615, 225),
	Vector2(480, 145), Vector2(210, 165), Vector2(750, 165), Vector2(820, 275),
	Vector2(140, 275), Vector2(620, 430), Vector2(340, 430), Vector2(480, 460),
]
const ENTRY: Vector2 = Vector2(480, 310)


class Drop:
	var position: Vector2

	func _init(point: Vector2) -> void:
		position = point


class FloatingText:
	var point: Vector2
	var content: String
	var color: Color
	var remaining: float = 1.0


class Spark:
	var point: Vector2
	var velocity: Vector2
	var color: Color
	var remaining: float


var _door_open: bool = false
var _remaining: int
var _first_wave_count: int = 0
var _second_wave_delay: float
var _second_wave: Array[Enemy.EnemyType] = []
var _boss: Enemy
var _ally: Ally
var _decor_obstacles: Node2D
var _reinforcement_delay: float
var _hitstop: float
var _hitstop_pending: bool
var _shake_remaining: float
var _shake_strength: float
var _ambient_time: float
var _drops: Array[Drop] = []
var _messages: Array[FloatingText] = []
var _sparks: Array[Spark] = []
var _dust_origins: PackedVector2Array = PackedVector2Array()
var _effects_rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var _player: Player = $Player
@onready var _courtyard: Sprite2D = $Courtyard
@onready var _atmosphere: Node2D = $Atmosphere
@onready var _effects: Node2D = $Effects
@onready var _camera: Camera2D = $Camera2D
@onready var _enemy_container: Node2D = $Enemies
@onready var _ally_container: Node2D = $Allies
@onready var _stations: Node2D = $Stations
@onready var _door: StaticBody2D = $NorthDoor
@onready var _door_sprite: Sprite2D = $NorthDoor/Sprite2D
@onready var _door_sign: Label = $NorthDoor/Sign
@onready var _door_lock: Sprite2D = $NorthDoor/Lock
@onready var _hud: HUD = $HUD
@onready var _story: StoryDialog = $StoryDialog
@onready var _cutscene: CutscenePlayer = $CutscenePlayer


func _ready() -> void:
	_decor_obstacles = Node2D.new()
	_decor_obstacles.name = "DecorObstacles"
	add_child(_decor_obstacles)
	move_child(_decor_obstacles, _stations.get_index())
	var dust_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	dust_rng.seed = 1212
	for index: int in range(28):
		var cell: Vector2 = Vector2(index % 7, floori(index / 7.0))
		_dust_origins.append(Vector2(42, 74) + cell * Vector2(126, 106)
				+ Vector2(dust_rng.randf_range(12, 98), dust_rng.randf_range(10, 82)))
	_atmosphere.draw.connect(_draw_atmosphere)
	_effects.draw.connect(_draw_effects)
	_effects_rng.randomize()
	_hud.bind_player(_player)
	_player.enemy_hit.connect(_on_enemy_hit)
	_player.hit_taken.connect(_on_player_hit)
	_player.interacted.connect(_on_interacted)
	_player.breathing_completed.connect(_on_breathing_completed)
	GameManager.exhausted_changed.connect(_on_exhausted)
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.intro_requested.connect(_play_intro_cutscene)
	GameManager.run_started.connect(_setup_room.bind(1))


func _play_intro_cutscene() -> void:
	_clear_room()
	_cutscene.play_intro(GameManager.start_new_run)


func _snap_camera() -> void:
	_camera.position = _player.position.clamp(Vector2(320, 180), Vector2(640, 360)).round()


func _setup_room(room_index: int) -> void:
	_clear_room()
	GameManager.enter_room(room_index)
	_courtyard.texture = ROOM_ART[room_index - 1]
	_player.position = Vector2(480, 390) if GameManager.is_final_room() else ENTRY
	_player.reset_run()
	_snap_camera()
	var is_final: bool = GameManager.is_final_room()
	_door.visible = not is_final
	$NorthDoor/CollisionShape2D.set_deferred(&"disabled", is_final)
	_door_open = false
	_update_door_visual()
	_reinforcement_delay = 10.0
	match room_index:
		1:
			_add_station(Station.StationType.WATER_SNACK, Vector2(280, 250))
			_add_station(Station.StationType.REST_SPOT, Vector2(680, 250))
			_add_obstacle(Vector2(77, 67), Vector2(98, 58), Vector2.ZERO, _decor_obstacles)
			_add_obstacle(Vector2(858, 67), Vector2(68, 18), Vector2.ZERO, _decor_obstacles)
			_start_waves(MORNING_C1, 3)
		2:
			_add_station(Station.StationType.WATER_SNACK, Vector2(280, 235))
			var colleague: Station = _add_station(Station.StationType.CLASSMATE_NPC, Vector2(680, 300))
			colleague.classmate_recruited.connect(_on_classmate_recruited.bind(colleague.position))
			_add_obstacle(Vector2(98, 158), Vector2(68, 20), Vector2(0, 180))
			_add_obstacle(Vector2(862, 158), Vector2(68, 20), Vector2(0, 180))
			_start_waves(AFTERNOON_C1, 3)
		3:
			_add_station(Station.StationType.WATER_SNACK, Vector2(280, 250))
			_add_station(Station.StationType.REST_SPOT, Vector2(680, 250))
			_add_obstacle(Vector2(696, 63), Vector2(68, 18), Vector2.ZERO, _decor_obstacles)
			_start_waves(NIGHT_C1, 4)
		4:
			_add_station(Station.StationType.WATER_SNACK, Vector2(280, 250))
			_add_station(Station.StationType.REST_SPOT, Vector2(680, 250))
			_add_obstacle(Vector2(77, 67), Vector2(98, 58), Vector2.ZERO, _decor_obstacles)
			_add_obstacle(Vector2(858, 67), Vector2(68, 18), Vector2.ZERO, _decor_obstacles)
			_start_waves(MORNING_C2, 4)
		5:
			_add_station(Station.StationType.WATER_SNACK, Vector2(280, 235))
			_add_station(Station.StationType.REST_SPOT, Vector2(680, 300))
			_add_obstacle(Vector2(98, 158), Vector2(68, 20), Vector2(0, 180))
			_add_obstacle(Vector2(862, 158), Vector2(68, 20), Vector2(0, 180))
			_start_waves(AFTERNOON_C2, 4)
		6:
			_add_station(Station.StationType.WATER_SNACK, Vector2(280, 250))
			_add_station(Station.StationType.REST_SPOT, Vector2(680, 250))
			_add_obstacle(Vector2(696, 63), Vector2(68, 18), Vector2.ZERO, _decor_obstacles)
			_start_waves(NIGHT_C2, 5)
		7:
			_add_station(Station.StationType.WATER_SNACK, Vector2(280, 250))
			_add_station(Station.StationType.REST_SPOT, Vector2(680, 250))
			_add_obstacle(Vector2(77, 67), Vector2(98, 58), Vector2.ZERO, _decor_obstacles)
			_add_obstacle(Vector2(858, 67), Vector2(68, 18), Vector2.ZERO, _decor_obstacles)
			_start_waves(MORNING_C3, 5)
		8:
			_add_station(Station.StationType.WATER_SNACK, Vector2(280, 235))
			_add_station(Station.StationType.REST_SPOT, Vector2(680, 300))
			_add_obstacle(Vector2(98, 158), Vector2(68, 20), Vector2(0, 180))
			_add_obstacle(Vector2(862, 158), Vector2(68, 20), Vector2(0, 180))
			_start_waves(AFTERNOON_C3, 6)
		9:
			_add_station(Station.StationType.ROOM_PILLAR, Vector2(480, 145), "MENTE")
			_add_station(Station.StationType.ROOM_PILLAR, Vector2(265, 375), "CORPO")
			_add_station(Station.StationType.ROOM_PILLAR, Vector2(695, 375), "DESCANSO")
			_remaining = 1
			_boss = _spawn_enemy(Enemy.EnemyType.BURNOUT_BOSS, Vector2(480, 255))
			_boss.pillar_drained.connect(_on_pillar_drained)
			_boss.boss_pulsed.connect(_start_shake.bind(2.0, 0.18))
	if GameManager.ally_active:
		_spawn_ally(_player.position)
	_refresh_objective()
	_story.play_sequence(ROOM_DIALOGUES[room_index - 1])


func _clear_room() -> void:
	_set_hitstop(0.0)
	for container: Node2D in [_enemy_container, _ally_container, _stations, _decor_obstacles]:
		if container == null:
			continue
		for child: Node in container.get_children():
			container.remove_child(child)
			child.queue_free()
	_boss = null
	_ally = null
	_remaining = 0
	_first_wave_count = 0
	_second_wave.clear()
	_drops.clear()
	_messages.clear()
	_sparks.clear()
	_shake_remaining = 0.0
	_camera.offset = Vector2.ZERO


func _start_waves(types: Array[Enemy.EnemyType], first_wave_size: int) -> void:
	_remaining = types.size()
	_first_wave_count = first_wave_size
	_second_wave.assign(types.slice(first_wave_size))
	_second_wave_delay = 5.0
	for index: int in range(first_wave_size):
		_spawn_enemy(types[index], SPAWN_POINTS[index % SPAWN_POINTS.size()])


func _add_station(type: Station.StationType, point: Vector2, pillar: String = "CORPO") -> Station:
	var station: Station = STATION_SCENE.instantiate() as Station
	station.station_type = type
	station.pillar_name = pillar
	station.position = point
	_stations.add_child(station)
	if type == Station.StationType.ROOM_PILLAR:
		_add_obstacle(point + Vector2(0, 2), Vector2(20, 12))
		var caption: Label = Label.new()
		caption.text = pillar
		caption.position = Vector2(-42, 12)
		caption.size = Vector2(84, 14)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override(&"font_size", 10)
		caption.add_theme_color_override(&"font_shadow_color", Color.BLACK)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		station.add_child(caption)
	return station


func _add_obstacle(point: Vector2, dimensions: Vector2, second_offset: Vector2 = Vector2.ZERO,
		parent_node: Node2D = null) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = point
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = dimensions
	var collider: CollisionShape2D = CollisionShape2D.new()
	collider.shape = rectangle
	body.add_child(collider)
	if second_offset != Vector2.ZERO:
		var second: CollisionShape2D = CollisionShape2D.new()
		second.shape = rectangle
		second.position = second_offset
		body.add_child(second)
	(parent_node if parent_node != null else _stations).add_child(body)


func _spawn_enemy(type: Enemy.EnemyType, point: Vector2) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.enemy_type = type
	enemy.position = point
	enemy.player = _player
	enemy.defeated.connect(_on_enemy_defeated.bind(enemy))
	_enemy_container.add_child(enemy)
	return enemy


func _on_enemy_defeated(enemy: Enemy) -> void:
	_remaining -= 1
	GameManager.increment_combo()
	GameManager.add_score(100 * GameManager.combo)
	_burst(enemy.position, Enemy.COLORS[enemy.enemy_type], 13)
	if enemy.is_boss():
		_finish_boss.call_deferred()
	else:
		_drops.append(Drop.new(enemy.position))


func _finish_boss() -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING and GameManager.hp > 0:
		for node: Node in _enemy_container.get_children():
			if not node.is_queued_for_deletion():
				node.queue_free()
		for projectile: Node in get_tree().get_nodes_in_group(&"enemy_projectiles"):
			projectile.queue_free()
		_story.play_sequence("victory", _play_outro)


func _play_outro() -> void:
	if GameManager.hp > 0:
		_cutscene.play_outro(_win)


func _win() -> void:
	if GameManager.hp > 0:
		GameManager.set_state(GameManager.GameState.VICTORY)


func _on_state_changed(state: GameManager.GameState) -> void:
	if state in [GameManager.GameState.MENU, GameManager.GameState.VICTORY, GameManager.GameState.GAME_OVER]:
		_clear_room()
		if state == GameManager.GameState.MENU:
			_courtyard.texture = ROOM_ART[0]
			_door.hide()


func _on_classmate_recruited(point: Vector2) -> void:
	_spawn_ally(point)
	_story.play_sequence("classmate_help")


func _spawn_ally(point: Vector2) -> void:
	var ally: Ally = ALLY_SCENE.instantiate() as Ally
	ally.core_position = point
	_ally_container.add_child(ally)
	_ally = ally


func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING or _hitstop > 0.0:
		return
	if is_instance_valid(_ally):
		_ally.core_position = _ally.core_position.move_toward(_player.position, 91.0 * delta)
	for node: Node in _enemy_container.get_children():
		var enemy: Enemy = node as Enemy
		if enemy != null:
			enemy.position = enemy.position.clamp(Vector2(30, 56), Vector2(930, 512))
	_update_drops(delta)
	if not GameManager.is_final_room():
		_update_waves(delta)
		_update_door()
	else:
		_update_reinforcements(delta)
	_refresh_objective()


func _update_waves(delta: float) -> void:
	if _second_wave.is_empty():
		return
	_second_wave_delay -= delta
	if _second_wave_delay <= 0.0 or _remaining == _second_wave.size():
		var index: int = 0
		for type: Enemy.EnemyType in _second_wave:
			_spawn_enemy(type, SPAWN_POINTS[(_first_wave_count + index) % SPAWN_POINTS.size()])
			index += 1
		_second_wave.clear()


func _update_reinforcements(delta: float) -> void:
	if not is_instance_valid(_boss) or _boss.is_queued_for_deletion() or not _boss.is_phase_two():
		return
	_reinforcement_delay = maxf(0.0, _reinforcement_delay - delta)
	if _reinforcement_delay == 0.0 and _remaining < 3:
		_remaining += 1
		_spawn_enemy(Enemy.EnemyType.PROCRASTINATION, SPAWN_POINTS[0])
		_reinforcement_delay = 12.0


func _update_door() -> void:
	var turn: int = GameManager.get_turn()
	var min_body: float = 50.0 if turn == 1 else 45.0
	var balanced: bool = GameManager.body >= min_body \
			and (turn < 2 or GameManager.mind >= 45.0) \
			and (turn < 3 or GameManager.rest >= 45.0)
	var open: bool = _remaining == 0 and balanced
	if open != _door_open:
		_door_open = open
		_update_door_visual()
		if open:
			_float_text(_door.position + Vector2(0, 66), "PORTA ABERTA!", Color("#afff9d"))
			AudioManager.play_door_open()
	if _door_open and _player.position.distance_squared_to(_door.position) <= 26.0 * 26.0:
		_setup_room(GameManager.room + 1)


func _update_door_visual() -> void:
	_door_sprite.self_modulate = Color("#b3ffa2") if _door_open else Color("#9d8597")
	_door_lock.visible = not _door_open
	_door_sign.text = "AVANÇAR ↑" if _door_open else "TRANCADA"
	_door_sign.modulate = Color("#f8df90") if _door_open else Color("#e5bdc5")


func _refresh_objective() -> void:
	if GameManager.is_final_room():
		var hp: int = maxi(0, _boss.hp) if is_instance_valid(_boss) else 0
		var phase: int = 2 if is_instance_valid(_boss) and _boss.is_phase_two() else 1
		_hud.set_objective("Burnout %d HP  •  Fase %d" % [hp, phase])
	elif _door_open:
		_hud.set_objective("PORTA ABERTA! Suba até ela ↑")
	else:
		var turn: int = GameManager.get_turn()
		var need_parts: Array[String] = []
		if GameManager.body < (50.0 if turn == 1 else 45.0):
			need_parts.append("Corpo [E]")
		if turn >= 2 and GameManager.mind < 45.0:
			need_parts.append("Mente [R]")
		if turn == 3 and GameManager.rest < 45.0:
			need_parts.append("Descanso [E]")
		var need: String = " + ".join(need_parts)
		_hud.set_objective("Inimigos: %d%s" % [_remaining, "  •  " + need if not need.is_empty() else ""])


func _update_drops(delta: float) -> void:
	for index: int in range(_drops.size() - 1, -1, -1):
		var drop: Drop = _drops[index]
		if drop.position.distance_squared_to(_player.position) > 50.0 * 50.0:
			continue
		drop.position = drop.position.move_toward(_player.position, 185.0 * delta)
		if drop.position.distance_squared_to(_player.position) <= 8.0 * 8.0:
			_drops.remove_at(index)
			GameManager.modify_body(14.0)
			GameManager.heal_player(3)
			GameManager.add_score(25)
			AudioManager.play_pickup()
			_float_text(_player.position + Vector2(0, -16), "+14 CORPO · +3 HP", Color("#8de5ff"))


func _on_enemy_hit(point: Vector2, damage: int, clarity: bool, _is_boss: bool) -> void:
	_float_text(point + Vector2(0, -15), ("FOCO! " if clarity else "") + ("-%d" % damage),
			Color("#89ffe0") if clarity else Color("#fff2ce"))
	_burst(point, Color("#89ffe0") if clarity else Color("#f4ba72"), 8)
	_set_hitstop(0.062 if clarity else 0.032)
	_start_shake(2.0 if clarity else 1.0, 0.14 if clarity else 0.07)


func _on_player_hit(_mind_damage: float) -> void:
	GameManager.reset_combo()
	if GameManager.current_state == GameManager.GameState.PLAYING:
		_start_shake(3.0, 0.16)


func _on_interacted(_station_name: String, feedback: String) -> void:
	_float_text(_player.position + Vector2(0, -16), feedback.to_upper(), Color("#afffbb"))


func _on_exhausted(exhausted: bool) -> void:
	if exhausted:
		_float_text(_player.position + Vector2(0, -18), "OFEGANTE!", Color("#ffadc3"))


func _on_pillar_drained(pillar: String) -> void:
	_float_text(_player.position + Vector2(0, -24), "BURNOUT DRENANDO %s!" % pillar, Color("#ffadc3"))


func _on_breathing_completed() -> void:
	_burst(_player.position, Color("#a6f9f2"), 12)


func _set_hitstop(duration: float) -> void:
	_hitstop = duration
	_hitstop_pending = duration > 0.0
	var physics_enabled: bool = duration <= 0.0
	_player.set_physics_process(physics_enabled)
	for container: Node2D in [_enemy_container, _ally_container]:
		for node: Node in container.get_children():
			if not node.is_queued_for_deletion():
				node.set_physics_process(physics_enabled)


func _start_shake(strength: float, duration: float) -> void:
	if GameManager.screen_shake_enabled:
		_shake_strength = maxf(strength, _shake_strength if _shake_remaining > 0.0 else 0.0)
		_shake_remaining = maxf(duration, _shake_remaining)


func _float_text(point: Vector2, message: String, color: Color) -> void:
	var floating: FloatingText = FloatingText.new()
	floating.point = point
	floating.content = message
	floating.color = color
	_messages.append(floating)


func _burst(point: Vector2, color: Color, count: int) -> void:
	for index: int in range(mini(count, 96 - _sparks.size())):
		var direction: Vector2 = Vector2.from_angle(_effects_rng.randf_range(0.0, TAU))
		var spark: Spark = Spark.new()
		spark.point = point + direction * 4.0
		spark.velocity = direction * _effects_rng.randf_range(30.0, 95.0)
		spark.color = color.lightened(0.35) if index % 3 == 0 else color
		spark.remaining = _effects_rng.randf_range(0.16, 0.36)
		_sparks.append(spark)


func _process(delta: float) -> void:
	if _hitstop_pending:
		# A renderização do impacto pode chegar no mesmo frame que o golpe.
		_hitstop_pending = false
	elif _hitstop > 0.0:
		_hitstop = maxf(0.0, _hitstop - delta)
		if _hitstop == 0.0:
			_set_hitstop(0.0)
	_ambient_time = fposmod(_ambient_time + delta, TAU * 5.0)
	if is_instance_valid(_player) and GameManager.current_state in [
			GameManager.GameState.PLAYING, GameManager.GameState.DIALOGUE, GameManager.GameState.PAUSED]:
		var target_cam: Vector2 = _player.position.clamp(Vector2(320, 180), Vector2(640, 360))
		if _camera.position.distance_squared_to(target_cam) > 90.0 * 90.0:
			_camera.position = target_cam.round()
		else:
			_camera.position = _camera.position.lerp(target_cam, 1.0 - exp(-delta * 10.0)).round()
	_shake_remaining = maxf(0.0, _shake_remaining - delta) if GameManager.screen_shake_enabled else 0.0
	var phase: int = ceili(_shake_remaining * 30.0)
	var strength: float = minf(_shake_strength, float(phase))
	_camera.offset = Vector2(strength, floorf(strength * 0.5)) * (-1 if phase % 2 == 0 else 1)
	for index: int in range(_sparks.size() - 1, -1, -1):
		var spark: Spark = _sparks[index]
		spark.remaining -= delta
		if spark.remaining <= 0.0:
			_sparks.remove_at(index)
		else:
			spark.point += spark.velocity * delta
			spark.velocity.y += 80.0 * delta
	for index: int in range(_messages.size() - 1, -1, -1):
		var floating: FloatingText = _messages[index]
		floating.remaining -= delta
		if floating.remaining <= 0.0:
			_messages.remove_at(index)
		else:
			floating.point.y -= 22.0 * delta
	_atmosphere.queue_redraw()
	_effects.queue_redraw()


func _draw_atmosphere() -> void:
	var turn: int = GameManager.get_turn()
	var cycle: int = GameManager.get_cycle()
	var tint: Color = ROOM_LIGHT[turn - 1]
	var shimmer: float = 0.5 + 0.5 * sin(_ambient_time * 2.2)
	match turn:
		1:
			var beam_col: Color = Color("#ffd38a") if cycle == 1 else (Color("#d2b0c2") if cycle == 2 else Color("#bd9eff"))
			for beam_x: float in [194.0, 620.0]:
				_draw_sunbeam(beam_x, 54.0, 86.0, beam_col, 0.032 + shimmer * 0.015)
			_draw_halo(Vector2(142, 52), 28.0, beam_col, 0.025 + shimmer * 0.010)
			_draw_halo(Vector2(858, 60), 34.0, beam_col, 0.026 + shimmer * 0.010)
		2:
			var beam_col: Color = Color("#f2b872") if cycle == 1 else (Color("#d98b88") if cycle == 2 else Color("#b880ff"))
			for beam_x: float in [188.0, 596.0]:
				_draw_sunbeam(beam_x, 54.0, 86.0, beam_col, 0.026 + shimmer * 0.012)
			for screen_pos: Vector2 in [
				Vector2(98, 148), Vector2(98, 328), Vector2(862, 148), Vector2(862, 328),
			]:
				var screen_tint: Color = Color("#74e5ff") if screen_pos.x < 480.0 else Color("#ffcb80")
				if cycle == 2:
					screen_tint = Color("#ffa354") if screen_pos.x < 480.0 else Color("#ff6f69")
				elif cycle == 3:
					screen_tint = Color("#ff5a76") if screen_pos.x < 480.0 else Color("#ca83ff")
				_draw_halo(screen_pos, 36.0, screen_tint, 0.028 + shimmer * 0.012)
		3:
			_draw_halo(Vector2(648, 30), 42.0, Color("#f8c170"), 0.038 + 0.015 * sin(_ambient_time * 5.0))
			if GameManager.is_final_room():
				for step: int in range(7):
					var frac: float = float(step) / 7.0
					var width: float = 48.0 + frac * 18.0
					var moon_color := Color(0.58, 0.74, 0.96, (1.0 - frac) * (0.045 + shimmer * 0.015))
					_atmosphere.draw_rect(Rect2(480.0 - width * 0.5, 50.0 + frac * 98.0, width, 14.0), moon_color)
				for idx: int in range(6):
					var candle: Vector2 = [
						Vector2(34, 134), Vector2(922, 134),
						Vector2(34, 292), Vector2(922, 292),
						Vector2(34, 462), Vector2(922, 462),
					][idx]
					var flicker: float = 0.032 + 0.014 * sin(_ambient_time * 7.0 + float(idx) * 1.7)
					_draw_halo(candle, 30.0, Color("#ffbd6b"), flicker)
				_draw_ley_pulses()
			else:
				for idx: int in range(4):
					var candle: Vector2 = [
						Vector2(34, 180), Vector2(922, 180),
						Vector2(34, 462), Vector2(922, 462),
					][idx]
					_draw_halo(candle, 28.0, Color("#ffbd6b"), 0.032 + 0.012 * sin(_ambient_time * 6.0 + float(idx)))

	if _door.visible and _door_open:
		_draw_halo(_door.position + Vector2(0, 14), 40.0, Color("#c9ff7a"),
				0.045 + 0.014 * sin(_ambient_time * 4.0))
	for index: int in range(_dust_origins.size()):
		var phase: float = index * 2.39996
		var drift: Vector2 = Vector2(sin(_ambient_time * 0.4 + phase) * 11.0,
				cos(_ambient_time * 0.6 + phase) * 8.0)
		tint.a = 0.22 + 0.14 * sin(_ambient_time * 1.2 + phase)
		_atmosphere.draw_rect(Rect2((_dust_origins[index] + drift).round(), Vector2.ONE), tint)


func _draw_sunbeam(origin_x: float, start_y: float, length: float, color: Color, opacity: float) -> void:
	for step: int in range(6):
		var frac: float = float(step) / 6.0
		var py: float = start_y + frac * length
		var px: float = origin_x + frac * length * 0.45
		color.a = opacity * (1.0 - frac * 0.55)
		_atmosphere.draw_rect(Rect2(Vector2(px, py).round(), Vector2(28, 12)), color)


func _draw_ley_pulses() -> void:
	var center := Vector2(480, 255)
	var conduits: Array = [
		[Vector2(480, 145), GameManager.mind, Color("#8de5ff")],
		[Vector2(265, 375), GameManager.body, Color("#80f1a8")],
		[Vector2(695, 375), GameManager.rest, Color("#ffe091")],
	]
	for entry_idx: int in range(conduits.size()):
		var entry: Array = conduits[entry_idx]
		var anchor: Vector2 = entry[0] as Vector2
		var value: float = float(entry[1])
		var critical: bool = value < 40.0
		var pulse_color: Color = Color("#ff435b") if critical else (entry[2] as Color)
		for mote: int in range(3):
			var phase: float = fposmod(_ambient_time * (0.95 if critical else 0.45) + float(mote) / 3.0 + float(entry_idx) * 0.2, 1.0)
			var pos: Vector2 = anchor.lerp(center, phase).round()
			pulse_color.a = sin(phase * PI) * (0.65 if critical else 0.35)
			_atmosphere.draw_rect(Rect2(pos - Vector2.ONE, Vector2(2, 2)), pulse_color)


func _draw_halo(point: Vector2, radius: float, color: Color, opacity: float) -> void:
	color.a = opacity
	for ring: int in range(8, 0, -1):
		_atmosphere.draw_circle(point, radius * ring / 8.0, color)


func _draw_effects() -> void:
	for drop: Drop in _drops:
		var point: Vector2 = drop.position.round()
		_effects.draw_circle(point, 8.0, Color(0.43, 0.83, 1.0, 0.18))
		_effects.draw_colored_polygon(PackedVector2Array([
			point + Vector2(0, -5), point + Vector2(3, 0), point + Vector2(2, 3),
			point + Vector2(-2, 3), point + Vector2(-3, 0),
		]), Color("#8de5ff"))
		_effects.draw_rect(Rect2(point + Vector2(-1, -1), Vector2.ONE), Color.WHITE)
	for spark: Spark in _sparks:
		var color: Color = Color(spark.color, minf(1.0, spark.remaining / 0.12))
		_effects.draw_rect(Rect2(spark.point.round(), Vector2(2, 2)), color)
	var font: Font = ThemeDB.fallback_font
	for floating: FloatingText in _messages:
		var width: float = font.get_string_size(floating.content, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var point: Vector2 = (floating.point - Vector2(width / 2.0, 0)).round()
		point.x = clampf(point.x, 22.0, 938.0 - width)
		var opacity: float = minf(1.0, floating.remaining * 3.0)
		_effects.draw_string_outline(font, point, floating.content, HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
				4, Color(0.10, 0.06, 0.14, opacity))
		_effects.draw_string(font, point, floating.content, HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
				Color(floating.color, opacity))
