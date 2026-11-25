extends SceneTree

const STEP: float = 1.0 / 60.0
const PLAYER_PATH: String = "res://scenes/player/player.tscn"
const STATION_PATH: String = "res://scenes/objects/care_station.tscn"
const ENEMY_PATH: String = "res://scenes/enemies/enemy_base.tscn"
const ALLY_PATH: String = "res://scenes/enemies/ally_support.tscn"

var failures: int = 0
var world: Node2D
var player: CharacterBody2D
var gm: Node
var interactions: Array[String] = []
var drains: Array[String] = []
var recruitments: int = 0


func _initialize() -> void:
	run.call_deferred()


func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)


func step(actor: Node, seconds: float) -> void:
	for index: int in range(roundi(seconds / STEP)):
		actor._physics_process(STEP)


func action(name: StringName) -> void:
	await process_frame
	set_action(name, true)
	await physics_frame
	step(player, STEP)
	set_action(name, false)
	await process_frame
	await physics_frame


func set_action(name: StringName, pressed: bool) -> void:
	if name == &"interact":
		var event := InputEventKey.new()
		event.physical_keycode = KEY_E
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	elif pressed:
		Input.action_press(name)
	else:
		Input.action_release(name)

func station(kind: int, offset: Vector2, pillar: String = "CORPO") -> Node2D:
	var node := (load(STATION_PATH) as PackedScene).instantiate() as Node2D
	node.station_type = kind
	node.pillar_name = pillar
	node.position = player.position + offset
	world.add_child(node)
	return node


func enemy(kind: int, offset: Vector2) -> Node2D:
	var node := (load(ENEMY_PATH) as PackedScene).instantiate() as Node2D
	node.enemy_type = kind
	node.position = player.position + offset
	world.add_child(node)
	return node


func clear_group(group: StringName) -> void:
	for node: Node in get_nodes_in_group(group):
		node.free()


func run() -> void:
	gm = root.get_node("GameManager")
	world = Node2D.new()
	world.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(world)
	player = (load(PLAYER_PATH) as PackedScene).instantiate() as CharacterBody2D
	player.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	world.add_child(player)
	player.position = Vector2(320, 180)
	player.interacted.connect(func(name: String, feedback: String) -> void:
		interactions.append(name + "|" + feedback))
	var east := InputEventKey.new()
	east.physical_keycode = KEY_E
	check(InputMap.action_has_event(&"interact", east), "E binding")
	var breathe := InputEventKey.new()
	breathe.physical_keycode = KEY_R
	check(InputMap.action_has_event(&"breathe", breathe), "R binding")
	var sprite: Sprite2D = player.get_node("Visual/Sprite2D") as Sprite2D
	check(sprite.hframes == 8 and sprite.texture.resource_path.ends_with("student_sheet.png"), "Student atlas")
	await test_player()
	await test_stations()
	test_enemies()
	await test_boss()
	await test_ally()
	world.free()
	var audio: Node = root.get_node("AudioManager")
	audio.stop_music()
	for voice: AudioStreamPlayer in audio.sfx_players:
		voice.stop()
	await create_timer(0.1).timeout
	print("T-017: ", failures, " falha(s).")
	quit(1 if failures else 0)


func test_player() -> void:
	gm.start_new_run()
	Input.action_press(&"move_right")
	step(player, STEP)
	check(is_equal_approx(player.velocity.x, 122.0 * 0.75), "Movement with low body")
	Input.action_press(&"breathe")
	step(player, STEP)
	check(is_equal_approx(player.velocity.x, 122.0 * 0.75 * 0.4), "Movement while breathing")
	Input.action_release(&"breathe")
	Input.action_release(&"move_right")
	player.position = Vector2(320, 180)
	var target: Node2D = enemy(0, Vector2(29, 0))
	await action(&"attack")
	check(target.hp == 28 and gm.rest == 92 and player._attack_range == 28.0, "Low body attack range and cost")
	target.position.x -= 3.0
	step(player, 0.34)
	await action(&"attack")
	check(target.hp == 10 and gm.rest == 84, "Low body attack damage")
	gm.modify_body(30.0)
	target.position.x += 18.0
	step(player, 0.34)
	await action(&"attack")
	check((not is_instance_valid(target) or target.is_queued_for_deletion()) and player._attack_range == 46.0 and gm.rest == 76, "Normal attack")
	clear_group(&"enemies")
	clear_group(&"slow_puddles")
	var behind: Node2D = enemy(2, Vector2(-24, 0))
	var above: Node2D = enemy(2, Vector2(0, -24))
	var below: Node2D = enemy(2, Vector2(0, 24))
	var right_target: Node2D = enemy(2, Vector2(24, 0))
	var far_target: Node2D = enemy(2, Vector2(-50, 0))
	player.facing_direction = Vector2.RIGHT
	step(player, 0.34)
	await action(&"attack")
	check(behind.hp == 6 and above.hp == 6 and below.hp == 6 and right_target.hp == 6
			and behind._knockback.x < 0.0 and far_target.hp == 36, "360 radial attack hits all surrounding enemies")
	clear_group(&"enemies")
	clear_group(&"slow_puddles")
	gm.spend_rest(100.0)
	gm.modify_mind(-80.0)
	step(player, 0.34)
	await action(&"attack")
	await action(&"dash")
	check(gm.is_exhausted and player._attack_cooldown == 0.0 and player._dash_cooldown == 0.0, "Exhausted input lock")
	Input.action_press(&"breathe")
	step(player, 71.0 * STEP)
	check(not gm.clarity_ready, "Breathing channel")
	step(player, STEP)
	Input.action_release(&"breathe")

	check(gm.clarity_ready and not gm.is_exhausted and gm.mind == 55.0 and gm.rest == 25.0, "Breathing restores pillars")
	await action(&"dash")
	check(is_equal_approx(gm.rest, 9.0 + gm.REST_RECOVERY_RATE * STEP) and player._dash_remaining > 0.0, "Dash cost and motion")
	check(not player.apply_enemy_contact(player.global_position, 8, 0.0, 0.0), "Dash immunity")
	player.reset_run()
	check(player.apply_enemy_contact(player.global_position, 8, 7.0, 6.0), "Enemy contact accepted")
	step(player, 0.73)
	check(not player.apply_enemy_contact(player.global_position, 8, 0.0, 0.0), "Contact immunity window")
	step(player, 0.05)
	check(player.apply_enemy_contact(player.global_position, 8, 0.0, 0.0), "Contact immunity expires")
	player.reset_run()
	player.position = Vector2(320, 180)


func test_stations() -> void:
	gm.start_new_run()
	gm.damage_player(35)
	var far: Node2D = station(0, Vector2(47, 0))
	await action(&"interact")
	check(interactions.is_empty() and gm.hp == 65, "No interaction outside reach")
	var water: Node2D = station(0, Vector2(46, 0))
	var rest: Node2D = station(1, Vector2(20, 0))
	gm.modify_rest(-55.0)
	gm.modify_mind(-30.0)
	await action(&"interact")
	check(gm.rest == 95.0 and gm.mind == 95.0 and gm.hp == 75 and not rest.can_interact(), "E chooses nearest available station")
	await action(&"interact")
	check(gm.hp == 95 and gm.body > 84.0 and not water.can_interact(), "Water, HP and inclusive reach")
	check(interactions.size() == 2 and interactions[0].contains("+50") and interactions[1].contains("+20 HP"), "Interaction feedback")
	step(water, 3.48)
	check(not water.can_interact(), "Water cooldown")
	step(water, 0.04)
	check(water.can_interact(), "Water can be reused")
	far.free()
	water.free()
	rest.free()
	for pillar: String in ["CORPO", "MENTE", "DESCANSO"]:
		gm.modify_body(30.0 - gm.body)
		gm.modify_mind(30.0 - gm.mind)
		gm.modify_rest(30.0 - gm.rest)
		var node: Node2D = station(2, Vector2(15, 0), pillar)
		await action(&"interact")
		match pillar:
			"CORPO": check(gm.body > 74.0, "Body pillar")
			"MENTE": check(gm.mind == 75.0, "Mind pillar")
			"DESCANSO": check(gm.rest == 75.0, "Rest pillar")
		step(node, 0.98)
		check(not node.can_interact(), "Pillar cooldown")
		step(node, 0.04)
		check(node.can_interact(), "Pillar reactivation")
		node.free()


func test_enemies() -> void:
	gm.start_new_run()
	var slime: Node2D = enemy(0, Vector2(10, 0))
	step(slime, STEP)
	check(gm.hp == 95 and gm.body == 29.0, "Procrastination contact")
	slime.take_damage(28)
	var puddle: Node2D = get_first_node_in_group(&"slow_puddles") as Node2D
	check(puddle != null and is_equal_approx(player._ground_speed_multiplier(), 0.65), "Death puddle and 35 percent slow")
	if puddle != null:
		step(puddle, 2.82)
		check(puddle.is_queued_for_deletion() and player._ground_speed_multiplier() == 1.0, "Puddle expires")
	clear_group(&"enemies")
	clear_group(&"slow_puddles")
	player.reset_run()
	var deadline: Node2D = enemy(1, Vector2(180, 0))
	step(deadline, 2.7)
	check(deadline.hp == 25 and deadline._warning_strength() > 0.0, "Deadline warning")
	step(deadline, 0.34)
	check(deadline._charge_remaining > 0.0, "Deadline charge")
	deadline.position = player.position + Vector2(12, 0)
	step(deadline, STEP)
	check(gm.hp == 89 and gm.mind == 94.0, "Deadline contact")
	deadline.free()
	player.reset_run()
	var ghost: Node2D = enemy(2, Vector2(100, 0))
	step(ghost, 3.4)
	check(ghost.hp == 36 and ghost.position.distance_to(player.position) == 100.0 and ghost._warning_strength() > 0.0, "Self-criticism spacing and warning")
	step(ghost, 0.44)
	var orb: Node2D = get_first_node_in_group(&"enemy_projectiles") as Node2D
	check(orb != null, "Doubt orb")
	if orb != null:
		step(orb, 1.4)
		check(gm.hp == 84 and gm.mind == 85.0, "Doubt orb damage")
	ghost.free()
	clear_group(&"enemy_projectiles")


func test_boss() -> void:
	gm.start_new_run()
	player.reset_run()
	var boss: Node2D = enemy(3, Vector2(140, 0))
	boss.pillar_drained.connect(func(pillar: String) -> void: drains.append(pillar))
	check(boss.hp == 260 and boss.get_effective_damage(75, true) == 110, "Boss HP and clarity weakness")
	step(boss, 3.7)
	check(boss._warning_strength() > 0.0 and get_node_count_in_group(&"stress_projectiles") == 0, "Crimson warning before fan")
	step(boss, 0.74)
	check(get_node_count_in_group(&"stress_projectiles") == 3, "Phase one fan")
	clear_group(&"enemy_projectiles")
	step(boss, 4.10)
	check(drains == ["CORPO"] and gm.body == 19.0, "Phase one pillar drain")
	boss.take_damage(20)
	boss.position = player.position + Vector2(52, 0)
	gm.complete_breathing()
	await action(&"attack")
	check(boss.hp == 130 and boss.is_phase_two() and player._attack_range == 66.0 and gm.rest == 100.0, "Clarity attack and phase two threshold")
	clear_group(&"enemy_projectiles")
	step(boss, STEP)
	check(get_node_count_in_group(&"stress_projectiles") == 5, "Phase two fan")
	for projectile: Node2D in get_nodes_in_group(&"stress_projectiles"):
		projectile.global_position = player.global_position + Vector2(45, 0)
	step(player, 0.34)
	gm.complete_breathing()
	await action(&"attack")
	check(get_node_count_in_group(&"stress_projectiles") == 0, "Clarity cuts stress projectiles")
	step(boss, 7.0)
	check(drains == ["CORPO", "MENTE"] and gm.mind == 84.0, "Phase two pillar drain")
	step(boss, 7.02)
	check(drains == ["CORPO", "MENTE", "DESCANSO"] and gm.rest == 84.0, "Boss can drain all pillars")
	boss.free()
	clear_group(&"enemy_projectiles")


func test_ally() -> void:
	gm.start_new_run()
	player.reset_run()
	var npc: Node2D = station(3, Vector2(10, 0))
	npc.classmate_recruited.connect(func() -> void: recruitments += 1)
	await action(&"interact")
	check(recruitments == 1 and gm.ally_active and not npc.visible and not npc.can_interact(), "Classmate recruitment")
	var ally := (load(ALLY_PATH) as PackedScene).instantiate() as Node2D
	ally.core_position = player.position
	world.add_child(ally)
	check(ally.is_player_near(player), "Ally proximity")
	gm.modify_mind(-50.0)
	step(player, 1.0)
	check(is_equal_approx(gm.mind, 53.5), "Ally mind recovery")
	var target: Node2D = enemy(2, Vector2(25, 0))
	step(ally, 2.02)
	check(target.hp == 18 and target._slow_remaining == 1.2, "Calming pulse damage and slow")
