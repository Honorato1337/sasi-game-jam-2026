extends Node

# HABIT_SELECT is used by the legacy arena until T-018.
enum GameState { MENU, CUTSCENE, DIALOGUE, PLAYING, PAUSED, VICTORY, GAME_OVER, HABIT_SELECT }
enum MindState { CALM, ANXIOUS, OVERLOAD }

signal intro_requested
signal pillars_changed(body: float, mind: float, rest: float)
signal hp_changed(new_hp: int, max_hp: int)
signal mind_state_changed(new_state: MindState)
signal exhausted_changed(is_exhausted: bool)
signal room_changed(new_room: int)
signal ally_activated(active: bool)
signal combo_changed(new_combo: int)

const MAX_PILLAR: float = 100.0
const MAX_ROOMS: int = 9
const REST_RECOVERY_DELAY: float = 0.45
const REST_RECOVERY_RATE: float = 25.0

var body: float = MAX_PILLAR
var mind: float = MAX_PILLAR
var rest: float = MAX_PILLAR
var max_hp: int = 100
var hp: int = 100
var mind_state: MindState = MindState.CALM
var is_exhausted: bool = false
var ally_active: bool = false
var room: int = 1
var combo: int = 0
var _rest_delay: float = 0.0

enum SignalLevel { CALM, WARNING, OVERLOAD, EXHAUSTED }

signal state_changed(new_state: GameState)
signal run_started
signal score_changed(new_score: int)
signal bpm_changed(new_bpm: float, level: SignalLevel)
signal signal_level_changed(new_level: SignalLevel)
signal core_hp_changed(new_hp: int, max_hp: int)
signal wave_changed(new_wave: int)
signal habits_updated(sleep_rank: int, nutrition_rank: int, ally_count: int)
signal clarity_ready_changed(is_ready: bool)

const MIN_BPM: float = 70.0
const MAX_BPM: float = 180.0
const EXHAUSTION_DURATION: float = 2.0
const MAX_WAVES: int = 4
const MAX_ALLIES: int = 3

var current_state: GameState = GameState.MENU
var score: int = 0
var bpm: float:
	get: return 75.0 + (MAX_PILLAR - mind) * 0.95
var signal_level: SignalLevel = SignalLevel.CALM
var max_core_hp: int:
	get: return max_hp
var core_hp: int:
	get: return hp
var wave: int = 1
var sleep_rank: int = 0
var nutrition_rank: int = 0
var ally_count: int = 0
var clarity_ready: bool = false
var screen_shake_enabled: bool = true

var _exhaustion_remaining: float = 0.0


func _ready() -> void:
	_ensure_input_map()


func set_state(new_state: GameState) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	state_changed.emit(current_state)


func toggle_pause() -> void:
	match current_state:
		GameState.PLAYING:
			set_state(GameState.PAUSED)
		GameState.PAUSED:
			set_state(GameState.PLAYING)


func set_screen_shake_enabled(enabled: bool) -> void:
	screen_shake_enabled = enabled


func add_score(points: int) -> void:
	if points == 0:
		return

	score += points
	score_changed.emit(score)


func add_bpm(amount: float) -> void:
	if amount > 0.0:
		modify_mind(-amount * pow(0.8, sleep_rank) / 0.95)


func reduce_bpm(amount: float) -> void:
	if amount > 0.0:
		modify_mind(amount / 0.95)


## Call once per gameplay frame. Set recover_passively to false during combat actions.
func tick_bpm(delta: float, recover_passively: bool = true) -> void:
	if current_state != GameState.PLAYING or delta <= 0.0:
		return
	tick_pillars(delta)
	if recover_passively:
		reduce_bpm((6.0 + 2.5 * sleep_rank) * delta)


func complete_breathing() -> void:
	_exhaustion_remaining = 0.0
	_set_exhausted(false)
	modify_mind(35.0)
	modify_rest(25.0)
	_set_clarity_ready(true)


func consume_clarity_strike() -> bool:
	if not clarity_ready:
		return false
	_set_clarity_ready(false)
	return true


func damage_core(amount: int) -> void:
	if amount <= 0 or core_hp == 0:
		return
	_set_core_hp(core_hp - amount)
	if core_hp == 0:
		set_state(GameState.GAME_OVER)


func heal_core(amount: int) -> void:
	if amount > 0 and core_hp > 0:
		_set_core_hp(core_hp + amount)


## The between-wave UI applies one choice before the arena advances.
func apply_habit_choice(choice: String) -> void:
	match choice:
		"sleep":
			sleep_rank += 1
			_exhaustion_remaining = 0.0
			modify_mind(MAX_PILLAR)
		"nutrition":
			nutrition_rank += 1
			heal_core(25)
		"connection":
			if ally_count >= MAX_ALLIES:
				return
			ally_count += 1
		_:
			return
	habits_updated.emit(sleep_rank, nutrition_rank, ally_count)


func advance_wave() -> void:
	if current_state != GameState.PLAYING and current_state != GameState.HABIT_SELECT:
		return
	if wave == MAX_WAVES:
		set_state(GameState.VICTORY)
		return
	wave += 1
	set_state(GameState.PLAYING)
	wave_changed.emit(wave)


func start_intro_cutscene() -> void:
	set_state(GameState.CUTSCENE)
	intro_requested.emit()


func start_new_run() -> void:
	_reset_run(GameState.PLAYING)
	run_started.emit()


func reset_game() -> void:
	_reset_run(GameState.MENU)


func get_move_speed_multiplier() -> float:
	if is_exhausted:
		return 0.55
	if body < 40.0:
		return 0.75
	if mind_state == MindState.OVERLOAD:
		return 0.85
	return 1.0


func get_attack_cooldown_multiplier() -> float:
	if mind_state == MindState.OVERLOAD:
		return 1.50
	if mind_state == MindState.ANXIOUS:
		return 1.25
	return 1.0


func get_dash_cooldown_multiplier() -> float:
	return 1.35 if mind_state == MindState.OVERLOAD else 1.0


func get_breathe_duration() -> float:
	return 1.35


func _reset_run(new_state: GameState) -> void:
	sleep_rank = 0
	nutrition_rank = 0
	ally_count = 0
	_exhaustion_remaining = 0.0
	_rest_delay = 0.0
	_set_exhausted(false)
	body = 35.0 if new_state == GameState.PLAYING else MAX_PILLAR
	rest = MAX_PILLAR
	modify_mind(MAX_PILLAR)
	pillars_changed.emit(body, mind, rest)
	enter_room(1)
	reset_combo()
	if ally_active:
		ally_active = false
		ally_activated.emit(false)
	_set_core_hp(max_core_hp)
	_set_clarity_ready(false)
	habits_updated.emit(sleep_rank, nutrition_rank, ally_count)
	if wave != 1:
		wave = 1
		wave_changed.emit(wave)
	if score != 0:
		score = 0
		score_changed.emit(score)
	set_state(new_state)


func tick_pillars(delta: float, is_breathing: bool = false, near_ally: bool = false) -> void:
	if current_state != GameState.PLAYING or delta <= 0.0:
		return
	var cycle: int = get_cycle()
	modify_body(-(0.60 + 0.25 * float(cycle - 1)) * delta)
	if ally_active and near_ally:
		modify_mind(3.5 * delta)
	elif cycle > 1 and not is_breathing:
		modify_mind(-0.38 * float(cycle - 1) * delta)
	var remaining: float = delta
	if is_exhausted:
		var spent: float = minf(remaining, _exhaustion_remaining)
		_exhaustion_remaining -= spent
		remaining -= spent
		if _exhaustion_remaining <= 0.000001:
			_set_exhausted(false)
			modify_rest(35.0 - rest)
	var delay: float = minf(remaining, _rest_delay)
	_rest_delay -= delay
	if remaining > delay:
		modify_rest((remaining - delay) * (38.0 if is_breathing else REST_RECOVERY_RATE))


func modify_body(delta_val: float) -> void:
	var next: float = clampf(body + delta_val, 0.0, MAX_PILLAR)
	if body != next:
		body = next
		pillars_changed.emit(body, mind, rest)


func modify_mind(delta_val: float) -> void:
	var next: float = clampf(mind + delta_val, 0.0, MAX_PILLAR)
	if mind == next:
		return
	mind = next
	var level: MindState = MindState.CALM
	if mind < 25.0:
		level = MindState.OVERLOAD
	elif mind < 50.0:
		level = MindState.ANXIOUS
	if level != mind_state:
		mind_state = level
		mind_state_changed.emit(level)
	_sync_signal_level()
	bpm_changed.emit(bpm, signal_level)
	pillars_changed.emit(body, mind, rest)


func modify_rest(delta_val: float) -> void:
	var next: float = clampf(rest + delta_val, 0.0, MAX_PILLAR)
	if rest == next:
		return
	rest = next
	if delta_val < 0.0:
		_rest_delay = REST_RECOVERY_DELAY
	if rest == 0.0:
		_rest_delay = 0.0
		_exhaustion_remaining = EXHAUSTION_DURATION
		_set_exhausted(true)
	pillars_changed.emit(body, mind, rest)


func spend_rest(amount: float) -> void:
	if amount > 0.0 and not is_exhausted:
		modify_rest(-amount)


func _set_exhausted(value: bool) -> void:
	if is_exhausted != value:
		is_exhausted = value
		_sync_signal_level()
		exhausted_changed.emit(value)


func _sync_signal_level() -> void:
	var level: SignalLevel = SignalLevel.CALM
	if is_exhausted:
		level = SignalLevel.EXHAUSTED
	elif mind_state == MindState.OVERLOAD:
		level = SignalLevel.OVERLOAD
	elif mind_state == MindState.ANXIOUS:
		level = SignalLevel.WARNING
	if signal_level != level:
		signal_level = level
		signal_level_changed.emit(level)


func get_attack_range() -> float:
	if clarity_ready:
		return 64.0
	return 26.0 if body < 40.0 else 44.0


func get_attack_damage() -> int:
	if clarity_ready:
		return 70
	return 16 if body < 40.0 else 26


func get_cycle() -> int:
	return ((room - 1) / 3) + 1


func get_turn() -> int:
	return ((room - 1) % 3) + 1


func is_final_room() -> bool:
	return room == MAX_ROOMS


func activate_ally() -> void:
	if not ally_active:
		ally_active = true
		ally_activated.emit(true)


func enter_room(room_index: int) -> void:
	var next: int = clampi(room_index, 1, MAX_ROOMS)
	if room != next:
		room = next
		room_changed.emit(room)


func increment_combo() -> void:
	combo += 1
	combo_changed.emit(combo)


func reset_combo() -> void:
	if combo != 0:
		combo = 0
		combo_changed.emit(combo)


func damage_player(amount: int) -> void:
	damage_core(amount)


func heal_player(amount: int) -> void:
	heal_core(amount)


func _set_core_hp(value: int) -> void:
	var new_hp: int = clampi(value, 0, max_core_hp)
	if core_hp != new_hp:
		hp = new_hp
		hp_changed.emit(hp, max_hp)
		core_hp_changed.emit(core_hp, max_core_hp)


func _set_clarity_ready(is_ready: bool) -> void:
	if clarity_ready != is_ready:
		clarity_ready = is_ready
		clarity_ready_changed.emit(clarity_ready)


func _ensure_input_map() -> void:
	_add_input_action(&"move_left", [KEY_A, KEY_LEFT])
	_add_input_action(&"move_right", [KEY_D, KEY_RIGHT])
	_add_input_action(&"move_up", [KEY_W, KEY_UP])
	_add_input_action(&"move_down", [KEY_S, KEY_DOWN])
	_add_input_action(&"attack", [KEY_SPACE], MOUSE_BUTTON_LEFT)
	_add_input_action(&"dash", [KEY_SHIFT])
	_add_input_action(&"breathe", [KEY_R])
	_add_input_action(&"interact", [KEY_E])


func _add_input_action(action: StringName, keys: Array[Key],
		mouse_button: MouseButton = MOUSE_BUTTON_NONE) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key: Key in keys:
		var key_event: InputEventKey = InputEventKey.new()
		key_event.physical_keycode = key
		InputMap.action_add_event(action, key_event)
	if mouse_button != MOUSE_BUTTON_NONE:
		var mouse_event: InputEventMouseButton = InputEventMouseButton.new()
		mouse_event.button_index = mouse_button
		InputMap.action_add_event(action, mouse_event)
