extends Node

enum GameState {
	MENU,
	PLAYING,
	HABIT_SELECT,
	PAUSED,
	VICTORY,
	GAME_OVER,
}

enum SignalLevel { CALM, WARNING, OVERLOAD, EXHAUSTED }

signal state_changed(new_state: GameState)
signal score_changed(new_score: int)
signal bpm_changed(new_bpm: float, level: SignalLevel)
signal signal_level_changed(new_level: SignalLevel)
signal core_hp_changed(new_hp: int, max_hp: int)
signal wave_changed(new_wave: int)
signal habits_updated(sleep_rank: int, nutrition_rank: int, ally_count: int)
signal clarity_ready_changed(is_ready: bool)

const MIN_BPM: float = 70.0
const MAX_BPM: float = 180.0
const EXHAUSTION_DURATION: float = 2.5
const EXHAUSTION_RECOVERY_BPM: float = 135.0
const MAX_WAVES: int = 4
const MAX_ALLIES: int = 3

var current_state: GameState = GameState.MENU
var score: int = 0
var bpm: float = MIN_BPM
var signal_level: SignalLevel = SignalLevel.CALM
var max_core_hp: int = 100
var core_hp: int = max_core_hp
var wave: int = 1
var sleep_rank: int = 0
var nutrition_rank: int = 0
var ally_count: int = 0
var clarity_ready: bool = false

var _exhaustion_remaining: float = 0.0


func _ready() -> void:
	_ensure_input_map()


func set_state(new_state: GameState) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	state_changed.emit(current_state)


func add_score(points: int) -> void:
	if points == 0:
		return

	score += points
	score_changed.emit(score)


func add_bpm(amount: float) -> void:
	if amount > 0.0:
		_set_bpm(bpm + amount * pow(0.8, sleep_rank))


func reduce_bpm(amount: float) -> void:
	if amount > 0.0:
		_set_bpm(bpm - amount)


## Call once per gameplay frame. Set recover_passively to false during combat actions.
func tick_bpm(delta: float, recover_passively: bool = true) -> void:
	if current_state != GameState.PLAYING or delta <= 0.0:
		return
	_exhaustion_remaining = maxf(0.0, _exhaustion_remaining - delta)
	var recovery: float = 0.0
	if recover_passively:
		recovery = (6.0 + 2.5 * sleep_rank) * delta
	_set_bpm(bpm - recovery)


func complete_breathing() -> void:
	_exhaustion_remaining = 0.0
	_set_bpm(bpm - 15.0, true)
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
			_set_bpm(MIN_BPM, true)
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


func start_new_run() -> void:
	_reset_run(GameState.PLAYING)


func reset_game() -> void:
	_reset_run(GameState.MENU)


func get_move_speed_multiplier() -> float:
	var nutrition_multiplier: float = 1.0 + 0.15 * nutrition_rank
	match signal_level:
		SignalLevel.EXHAUSTED:
			return nutrition_multiplier * 0.45
		SignalLevel.OVERLOAD:
			return nutrition_multiplier * 0.85
	return nutrition_multiplier


func get_breathe_duration() -> float:
	return maxf(0.9, 1.5 - 0.2 * nutrition_rank)


func _reset_run(new_state: GameState) -> void:
	sleep_rank = 0
	nutrition_rank = 0
	ally_count = 0
	_exhaustion_remaining = 0.0
	_set_bpm(MIN_BPM, true)
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


func _set_bpm(value: float, clear_exhaustion: bool = false) -> void:
	var previous_bpm: float = bpm
	var previous_level: SignalLevel = signal_level
	bpm = clampf(value, MIN_BPM, MAX_BPM)

	if bpm >= MAX_BPM:
		if previous_level != SignalLevel.EXHAUSTED:
			_exhaustion_remaining = EXHAUSTION_DURATION
		signal_level = SignalLevel.EXHAUSTED
	elif previous_level == SignalLevel.EXHAUSTED and not clear_exhaustion \
			and (_exhaustion_remaining > 0.0 or bpm > EXHAUSTION_RECOVERY_BPM):
		signal_level = SignalLevel.EXHAUSTED
	elif bpm >= 150.0:
		signal_level = SignalLevel.OVERLOAD
	elif bpm >= 120.0:
		signal_level = SignalLevel.WARNING
	else:
		signal_level = SignalLevel.CALM

	if previous_level != signal_level:
		signal_level_changed.emit(signal_level)
	if previous_bpm != bpm or previous_level != signal_level:
		bpm_changed.emit(bpm, signal_level)


func _set_core_hp(value: int) -> void:
	var new_hp: int = clampi(value, 0, max_core_hp)
	if core_hp != new_hp:
		core_hp = new_hp
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
