extends SceneTree

const Manager := preload("res://scripts/autoload/game_manager.gd")
const SPRITES := "res://assets/sprites/"
# Largura e altura de cada quadro, seguidas do número de quadros.
const LAYOUTS := {
	"student_sheet": Vector3i(32,32,8), "classmate_sheet": Vector3i(32,32,2),
	"stations_sheet": Vector3i(48,48,4), "enemy_procrastination_sheet": Vector3i(32,32,2),
	"enemy_deadline_sheet": Vector3i(32,32,2), "enemy_selfcriticism_sheet": Vector3i(34,36,2),
	"boss_burnout_sheet": Vector3i(80,80,2), "room_morning": Vector3i(640,360,1),
	"room_afternoon": Vector3i(640,360,1), "room_night": Vector3i(640,360,1)
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
	check(gm.get_attack_damage() == 14 and gm.get_attack_range() == 24 and gm.get_move_speed_multiplier() == 0.75, "corpo baixo")
	gm.modify_body(5)
	check(gm.get_attack_damage() == 24 and gm.get_attack_range() == 40 and gm.get_move_speed_multiplier() == 1, "limiar corpo")
	gm.spend_rest(25)
	gm.tick_pillars(0.45)
	check(gm.rest == 75, "espera antes da recuperação")
	gm.tick_pillars(0.5)
	check(is_equal_approx(gm.rest,86), "recuperação passiva")
	gm.tick_pillars(0.25,true)
	check(is_equal_approx(gm.rest,94.5) and is_equal_approx(gm.body,38.98), "respiração e desgaste")
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
	check(gm.get_breathe_duration() == 1.5 and gm.mind == 62.5 and gm.rest == 25 and not gm.is_exhausted, "respiração completa")
	check(gm.get_attack_range() == 60 and gm.get_attack_damage() == 65 and gm.consume_clarity_strike() and not gm.consume_clarity_strike(), "clareza consumida uma vez")
	gm.enter_room(5)
	gm.increment_combo()
	gm.add_score(10)
	check(gm.room == 3 and gm.combo == 1 and gm.score == 10, "sala e placar")
	gm.damage_player(40)
	gm.heal_player(15)
	check(gm.hp == 75 and gm.core_hp == gm.hp, "vida e compatibilidade")
	gm.damage_player(100)
	check(gm.current_state == Manager.GameState.GAME_OVER, "derrota")
	gm.reset_game()
	check(gm.current_state == Manager.GameState.MENU and gm.combo == 0 and gm.score == 0 and not gm.ally_active and gm.room == 1, "reinício")
	print("T-016: ", failures, " falha(s).")
	quit(1 if failures else 0)
