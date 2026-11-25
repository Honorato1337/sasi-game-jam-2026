extends SceneTree

const Manager := preload("res://scripts/autoload/game_manager.gd")
const SPRITES := "res://assets/sprites/"
# Largura e altura de cada quadro, seguidas do número de quadros.
const LAYOUTS := {
	"student_sheet": Vector3i(32, 32, 8), "student_cutscene_sheet": Vector3i(32, 32, 4),
	"classmate_sheet": Vector3i(32, 32, 2),
	"stations_sheet": Vector3i(48, 48, 4), "room_props_sheet": Vector3i(48, 48, 5),
	"enemy_procrastination_sheet": Vector3i(32, 32, 2),
	"enemy_deadline_sheet": Vector3i(32, 32, 2), "enemy_selfcriticism_sheet": Vector3i(34, 36, 2),
	"boss_burnout_sheet": Vector3i(80, 80, 2),
	"room_morning": Vector3i(960, 540, 1), "room_afternoon": Vector3i(960, 540, 1), "room_night": Vector3i(960, 540, 1),
	"room_c2_morning": Vector3i(960, 540, 1), "room_c2_afternoon": Vector3i(960, 540, 1), "room_c2_night": Vector3i(960, 540, 1),
	"room_c3_morning": Vector3i(960, 540, 1), "room_c3_afternoon": Vector3i(960, 540, 1), "room_c3_night": Vector3i(960, 540, 1),
	"room_respite": Vector3i(960, 540, 1),
	"cutscene_wake": Vector3i(208, 103, 1), "cutscene_bus_day": Vector3i(208, 103, 1),
	"cutscene_class": Vector3i(208, 103, 1), "cutscene_lunch": Vector3i(208, 103, 1),
	"cutscene_bus_night": Vector3i(208, 103, 1), "cutscene_sleep": Vector3i(208, 103, 1),
	"cutscene_happy_wake": Vector3i(208, 103, 1), "cutscene_happy_bus": Vector3i(208, 103, 1),
	"cutscene_happy_class": Vector3i(208, 103, 1), "cutscene_happy_lunch": Vector3i(208, 103, 1),
	"cutscene_happy_sunset": Vector3i(208, 103, 1), "cutscene_happy_sleep": Vector3i(208, 103, 1),
	"cutscene_console": Vector3i(282, 116, 1), "cutscene_dawn": Vector3i(320, 180, 1),
	"cutscene_portraits": Vector3i(48, 48, 4),
}
var failures: int = 0

func check(ok: bool, label: String) -> void:
	if not ok:
		push_error(label)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func check_art() -> void:
	for name: String in LAYOUTS:
		var layout: Vector3i = LAYOUTS[name]
		var path: String = SPRITES + name + ".png"
		var texture := load(path) as Texture2D
		var img := Image.new()
		if texture == null or img.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
			check(false, path)
			continue
		check(texture.get_size() == Vector2(layout.x*layout.z,layout.y), name + " atlas")
		check(img.get_format() == Image.FORMAT_RGBA8, name + " RGBA8")
		var seen: Array[PackedByteArray] = []
		for frame in layout.z:
			var tile := img.get_region(Rect2i(frame*layout.x,0,layout.x,layout.y))
			var bytes := tile.get_data()
			check(not seen.has(bytes), name + " quadros distintos")
			seen.append(bytes)
			if layout.z > 1:
				check(tile.get_pixel(0,0).a == 0 and tile.get_used_rect().has_area(), name + " transparência")
			else:
				check(tile.detect_alpha() == Image.ALPHA_NONE, name + " fundo opaco")

func run() -> void:
	check_art()
	var gm := root.get_node("GameManager") as Manager
	gm.start_new_run()
	check(gm.room == 1 and gm.body == 35 and gm.hp == 100 and gm.mind == 100 and gm.rest == 100, "manhã")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	check(InputMap.action_has_event(&"interact", key), "interação E")
	check(gm.get_attack_damage() == 16 and gm.get_attack_range() == 26 and gm.get_move_speed_multiplier() == 0.75, "corpo baixo")
	gm.modify_body(5)
	check(gm.get_attack_damage() == 26 and gm.get_attack_range() == 44 and gm.get_move_speed_multiplier() == 1, "limiar corpo")
	gm.spend_rest(25)
	gm.tick_pillars(0.45)
	check(gm.rest == 75, "espera antes da recuperação")
	gm.tick_pillars(0.5)
	check(is_equal_approx(gm.rest,87.5), "recuperação passiva")
	gm.tick_pillars(0.25,true)
	check(is_equal_approx(gm.rest,97) and is_equal_approx(gm.body,39.28), "respiração e desgaste")
	gm.spend_rest(200)
	gm.tick_pillars(1.5)
	check(gm.is_exhausted and gm.rest == 0 and gm.get_move_speed_multiplier() == 0.55, "exaustão")
	gm.toggle_pause()
	gm.tick_pillars(4)
	check(gm.is_exhausted and gm.rest == 0, "pausa")
	gm.toggle_pause()
	gm.tick_pillars(0.5)
	check(not gm.is_exhausted and gm.rest == 35, "fim da exaustão")
	gm.modify_mind(-75)
	check(gm.mind_state == Manager.MindState.ANXIOUS, "limiar ansiedade")
	gm.modify_mind(-1)
	check(gm.mind_state == Manager.MindState.OVERLOAD, "sobrecarga")
	gm.enter_room(2)
	gm.activate_ally()
	gm.tick_pillars(1)
	check(gm.mind == 24, "colega distante")
	gm.tick_pillars(1,false,true)
	check(gm.mind == 27.5, "colega próximo")
	gm.spend_rest(100)
	gm.complete_breathing()
	check(gm.get_breathe_duration() == 1.35 and gm.mind == 62.5 and gm.rest == 25 and not gm.is_exhausted, "respiração completa")
	check(gm.get_attack_range() == 64 and gm.get_attack_damage() == 70 and gm.consume_clarity_strike() and not gm.consume_clarity_strike(), "clareza consumida uma vez")
	gm.enter_room(5)
	gm.modify_body(50.0)
	check(gm.room == 5 and gm.get_cycle() == 2 and gm.get_turn() == 2 and not gm.is_final_room(), "ciclo e turno sala 5")
	gm.modify_mind(-20.0)
	check(is_equal_approx(gm.get_attack_cooldown_multiplier(), 1.25), "debuff de ataque ansioso")
	gm.modify_mind(-20.0)
	check(is_equal_approx(gm.get_attack_cooldown_multiplier(), 1.50) and is_equal_approx(gm.get_dash_cooldown_multiplier(), 1.35) and is_equal_approx(gm.get_move_speed_multiplier(), 0.85), "debuff de sobrecarga")
	var mind_before_c2: float = gm.mind
	gm.tick_pillars(1.0)
	check(gm.mind < mind_before_c2, "desgaste mental passivo no ciclo 2")
	gm.enter_room(12)
	gm.increment_combo()
	gm.add_score(10)
	check(gm.room == 9 and gm.get_cycle() == 3 and gm.get_turn() == 3 and gm.is_final_room() and gm.combo == 1 and gm.score == 10, "sala e placar")
	gm.increment_combo()
	gm.increment_combo()
	check(is_equal_approx(gm.get_breathe_duration(), 1.13), "combo 3 acelera respiração")
	gm.increment_combo()
	gm.increment_combo()
	check(gm.get_attack_damage() >= 30, "combo 5 aumenta dano")
	gm.damage_player(40)
	gm.heal_player(15)
	check(gm.hp == 75 and gm.core_hp == gm.hp, "vida e compatibilidade")
	gm.damage_player(100)
	check(gm.current_state == Manager.GameState.GAME_OVER, "derrota")
	gm.reset_game()
	check(gm.current_state == Manager.GameState.MENU and gm.combo == 0 and gm.score == 0 and not gm.ally_active and gm.room == 1, "reinício")
	gm.start_new_run()
	gm.apply_habit_choice("nutrition")
	check(gm.max_hp == 125 and gm.nutrition_rank == 1, "hábito nutrição amplia HP máximo")
	gm.set_respite_room(true)
	var b0: float = gm.body
	gm.tick_pillars(1.0)
	check(gm.in_respite_room and gm.body > b0, "sala de respiro recupera pilares passivamente")
	gm.reset_game()
	check(not gm.in_respite_room, "reinício limpa sala de respiro")
	print("T-016: ", failures, " falha(s).")
	quit(1 if failures else 0)
