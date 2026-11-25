extends Node

const Player = preload("res://scenes/player/player.gd")

const SFX_POOL_SIZE: int = 8
const SAMPLE_RATE: int = 22050
const WAVE_SIZE: int = 1024
const SHAKER_SIZE: int = 4096
const SYNTHESIS_BUDGET_US: int = 5000
const SYNTHESIS_BLOCK_SIZE: int = 512
const MUSIC_VOLUME_DB: float = -7.5

const EFFECT_SCORES: Dictionary[StringName, Array] = {
	&"voice_blip": [Vector3i(76, 0, 1)],
	&"pickup": [Vector3i(72, 0, 1), Vector3i(84, 0, 2)],
	&"door_open": [Vector3i(67, 48, 2), Vector3i(76, 52, 2), Vector3i(84, 60, 4)],
	&"attack": [Vector3i(77, 0, 1), Vector3i(65, 0, 1), Vector3i(54, 0, 1)],
	&"clarity_strike": [Vector3i(72, 48, 1), Vector3i(79, 55, 1), Vector3i(84, 60, 3)],
	&"dash": [Vector3i(55, 0, 1), Vector3i(62, 0, 1), Vector3i(71, 0, 1), Vector3i(82, 0, 1)],
	&"breathe_complete": [Vector3i(67, 48, 2), Vector3i(72, 52, 2), Vector3i(76, 55, 4)],
	&"player_hit": [Vector3i(51, 37, 1), Vector3i(48, 33, 1), Vector3i(43, 29, 2)],
	&"core_hit": [Vector3i(39, 32, 2), Vector3i(33, 25, 3)],
	&"heartbeat": [Vector3i(0, 43, 2), Vector3i(0, 0, 1), Vector3i(0, 38, 2)],
	&"habit_select": [Vector3i(74, 50, 1), Vector3i(79, 55, 2)],
	&"alarm_beep": [Vector3i(88, 0, 1), Vector3i(0, 0, 1), Vector3i(88, 0, 1)],
	&"console_boot": [Vector3i(60, 48, 1), Vector3i(67, 55, 1), Vector3i(72, 60, 1), Vector3i(84, 60, 3)],
	&"victory": [Vector3i(72, 48, 2), Vector3i(76, 48, 2), Vector3i(79, 55, 2), Vector3i(84, 48, 7)],
	&"game_over": [Vector3i(71, 47, 2), Vector3i(67, 43, 2), Vector3i(63, 39, 3), Vector3i(59, 35, 7)],
}

const BOSSA_MENU: Array[Dictionary] = [
	{"bass": Vector2i(45, 52), "chord": Vector3i(60, 64, 71), "melody": [Vector2i(76, 3), Vector2i(74, 1), Vector2i(72, 2), Vector2i(71, 2)]},
	{"bass": Vector2i(38, 45), "chord": Vector3i(60, 64, 65), "melody": [Vector2i(72, 3), Vector2i(71, 1), Vector2i(69, 3), Vector2i(0, 1)]},
	{"bass": Vector2i(43, 50), "chord": Vector3i(59, 64, 65), "melody": [Vector2i(71, 3), Vector2i(69, 1), Vector2i(67, 2), Vector2i(69, 2)]},
	{"bass": Vector2i(48, 43), "chord": Vector3i(59, 62, 64), "melody": [Vector2i(74, 3), Vector2i(72, 1), Vector2i(71, 3), Vector2i(69, 1)]},
	{"bass": Vector2i(41, 48), "chord": Vector3i(60, 64, 69), "melody": [Vector2i(76, 3), Vector2i(74, 1), Vector2i(72, 2), Vector2i(71, 2)]},
	{"bass": Vector2i(47, 53), "chord": Vector3i(57, 62, 65), "melody": [Vector2i(74, 3), Vector2i(72, 1), Vector2i(71, 2), Vector2i(69, 2)]},
	{"bass": Vector2i(40, 47), "chord": Vector3i(56, 62, 65), "melody": [Vector2i(77, 2), Vector2i(76, 2), Vector2i(74, 2), Vector2i(71, 2)]},
	{"bass": Vector2i(45, 52), "chord": Vector3i(60, 66, 71), "melody": [Vector2i(72, 4), Vector2i(71, 2), Vector2i(0, 2)]},
]

const BOSSA_POEM: Array[Dictionary] = [
	{"bass": Vector2i(50, 45), "chord": Vector3i(64, 65, 69), "melody": [Vector2i(77, 3), Vector2i(76, 1), Vector2i(74, 3), Vector2i(0, 1)]},
	{"bass": Vector2i(43, 50), "chord": Vector3i(58, 62, 65), "melody": [Vector2i(79, 3), Vector2i(77, 1), Vector2i(74, 2), Vector2i(72, 2)]},
	{"bass": Vector2i(48, 43), "chord": Vector3i(58, 62, 64), "melody": [Vector2i(76, 3), Vector2i(74, 1), Vector2i(72, 3), Vector2i(0, 1)]},
	{"bass": Vector2i(41, 48), "chord": Vector3i(60, 64, 67), "melody": [Vector2i(74, 3), Vector2i(72, 1), Vector2i(69, 3), Vector2i(0, 1)]},
	{"bass": Vector2i(46, 53), "chord": Vector3i(57, 62, 65), "melody": [Vector2i(74, 2), Vector2i(72, 2), Vector2i(70, 2), Vector2i(69, 2)]},
	{"bass": Vector2i(40, 46), "chord": Vector3i(58, 62, 67), "melody": [Vector2i(76, 3), Vector2i(74, 1), Vector2i(70, 2), Vector2i(69, 2)]},
	{"bass": Vector2i(45, 52), "chord": Vector3i(58, 61, 67), "melody": [Vector2i(73, 3), Vector2i(74, 1), Vector2i(76, 2), Vector2i(74, 2)]},
	{"bass": Vector2i(50, 45), "chord": Vector3i(60, 64, 69), "melody": [Vector2i(72, 3), Vector2i(69, 3), Vector2i(0, 2)]},
]

const BOSSA_BEETHOVEN: Array[Dictionary] = [
	{"bass": Vector2i(48, 43), "chord": Vector3i(60, 63, 67), "melody": [Vector2i(67, 1), Vector2i(67, 1), Vector2i(67, 1), Vector2i(63, 3), Vector2i(0, 1), Vector2i(65, 1)]},
	{"bass": Vector2i(43, 50), "chord": Vector3i(59, 62, 65), "melody": [Vector2i(65, 1), Vector2i(65, 1), Vector2i(65, 1), Vector2i(62, 3), Vector2i(0, 1), Vector2i(67, 1)]},
	{"bass": Vector2i(41, 43), "chord": Vector3i(60, 63, 68), "melody": [Vector2i(72, 1), Vector2i(75, 1), Vector2i(79, 1), Vector2i(75, 1), Vector2i(77, 1), Vector2i(74, 1), Vector2i(79, 1), Vector2i(74, 1)]},
	{"bass": Vector2i(48, 43), "chord": Vector3i(59, 63, 67), "melody": [Vector2i(75, 2), Vector2i(74, 1), Vector2i(72, 1), Vector2i(71, 2), Vector2i(72, 1), Vector2i(0, 1)]},
]

const BOSSA_MORNING: Array[Dictionary] = [
	{"bass": Vector2i(41, 48), "chord": Vector3i(60, 64, 67), "melody": [Vector2i(76, 3), Vector2i(74, 1), Vector2i(72, 2), Vector2i(69, 2)]},
	{"bass": Vector2i(45, 52), "chord": Vector3i(58, 61, 67), "melody": [Vector2i(73, 3), Vector2i(74, 1), Vector2i(76, 3), Vector2i(0, 1)]},
	{"bass": Vector2i(50, 45), "chord": Vector3i(60, 64, 65), "melody": [Vector2i(77, 3), Vector2i(76, 1), Vector2i(74, 2), Vector2i(72, 2)]},
	{"bass": Vector2i(43, 50), "chord": Vector3i(59, 64, 65), "melody": [Vector2i(71, 3), Vector2i(74, 1), Vector2i(72, 2), Vector2i(69, 2)]},
	{"bass": Vector2i(43, 50), "chord": Vector3i(58, 62, 65), "melody": [Vector2i(74, 3), Vector2i(72, 1), Vector2i(70, 2), Vector2i(69, 2)]},
	{"bass": Vector2i(48, 43), "chord": Vector3i(58, 62, 64), "melody": [Vector2i(72, 3), Vector2i(70, 1), Vector2i(69, 2), Vector2i(67, 2)]},
	{"bass": Vector2i(41, 48), "chord": Vector3i(57, 60, 64), "melody": [Vector2i(69, 3), Vector2i(72, 2), Vector2i(74, 2), Vector2i(72, 1)]},
	{"bass": Vector2i(48, 43), "chord": Vector3i(58, 62, 67), "melody": [Vector2i(70, 3), Vector2i(69, 2), Vector2i(67, 2), Vector2i(0, 1)]},
]

const BOSSA_NOCTURNE: Array[Dictionary] = [
	{"bass": Vector2i(40, 47), "chord": Vector3i(59, 62, 66), "melody": [Vector2i(74, 3), Vector2i(72, 1), Vector2i(71, 2), Vector2i(67, 2)]},
	{"bass": Vector2i(45, 52), "chord": Vector3i(60, 64, 71), "melody": [Vector2i(71, 3), Vector2i(69, 1), Vector2i(67, 3), Vector2i(0, 1)]},
	{"bass": Vector2i(50, 45), "chord": Vector3i(60, 64, 66), "melody": [Vector2i(72, 3), Vector2i(71, 1), Vector2i(69, 2), Vector2i(66, 2)]},
	{"bass": Vector2i(43, 50), "chord": Vector3i(59, 62, 66), "melody": [Vector2i(71, 3), Vector2i(69, 1), Vector2i(67, 3), Vector2i(0, 1)]},
	{"bass": Vector2i(48, 43), "chord": Vector3i(59, 62, 64), "melody": [Vector2i(76, 3), Vector2i(74, 1), Vector2i(72, 2), Vector2i(71, 2)]},
	{"bass": Vector2i(42, 48), "chord": Vector3i(60, 64, 69), "melody": [Vector2i(72, 3), Vector2i(71, 1), Vector2i(69, 2), Vector2i(67, 2)]},
	{"bass": Vector2i(47, 42), "chord": Vector3i(57, 60, 63), "melody": [Vector2i(75, 2), Vector2i(74, 2), Vector2i(72, 2), Vector2i(69, 2)]},
	{"bass": Vector2i(40, 47), "chord": Vector3i(59, 62, 66), "melody": [Vector2i(71, 4), Vector2i(67, 2), Vector2i(0, 2)]},
]

const BOSSA_NIGHT: Array[Dictionary] = [
	{"bass": Vector2i(48, 43), "chord": Vector3i(58, 62, 63), "melody": [Vector2i(74, 3), Vector2i(72, 1), Vector2i(70, 2), Vector2i(67, 2)]},
	{"bass": Vector2i(41, 48), "chord": Vector3i(56, 60, 67), "melody": [Vector2i(75, 3), Vector2i(74, 1), Vector2i(72, 3), Vector2i(0, 1)]},
	{"bass": Vector2i(46, 53), "chord": Vector3i(56, 62, 67), "melody": [Vector2i(74, 3), Vector2i(72, 1), Vector2i(70, 2), Vector2i(68, 2)]},
	{"bass": Vector2i(39, 46), "chord": Vector3i(58, 62, 67), "melody": [Vector2i(70, 3), Vector2i(68, 1), Vector2i(67, 3), Vector2i(0, 1)]},
	{"bass": Vector2i(44, 51), "chord": Vector3i(55, 60, 63), "melody": [Vector2i(72, 3), Vector2i(70, 1), Vector2i(68, 2), Vector2i(67, 2)]},
	{"bass": Vector2i(50, 44), "chord": Vector3i(56, 60, 65), "melody": [Vector2i(72, 2), Vector2i(70, 2), Vector2i(68, 2), Vector2i(65, 2)]},
	{"bass": Vector2i(43, 50), "chord": Vector3i(56, 59, 65), "melody": [Vector2i(74, 3), Vector2i(72, 1), Vector2i(71, 2), Vector2i(67, 2)]},
	{"bass": Vector2i(48, 43), "chord": Vector3i(58, 62, 63), "melody": [Vector2i(72, 4), Vector2i(67, 2), Vector2i(0, 2)]},
]

const BOSSA_BOSS: Array[Dictionary] = [
	{"bass": Vector2i(47, 42), "chord": Vector3i(57, 61, 62), "melody": [Vector2i(73, 2), Vector2i(74, 2), Vector2i(78, 2), Vector2i(74, 2)]},
	{"bass": Vector2i(40, 47), "chord": Vector3i(55, 59, 66), "melody": [Vector2i(79, 3), Vector2i(78, 1), Vector2i(74, 2), Vector2i(73, 2)]},
	{"bass": Vector2i(45, 52), "chord": Vector3i(55, 61, 66), "melody": [Vector2i(78, 2), Vector2i(76, 2), Vector2i(74, 2), Vector2i(73, 2)]},
	{"bass": Vector2i(50, 45), "chord": Vector3i(61, 64, 66), "melody": [Vector2i(76, 3), Vector2i(74, 1), Vector2i(73, 2), Vector2i(71, 2)]},
	{"bass": Vector2i(43, 50), "chord": Vector3i(59, 62, 66), "melody": [Vector2i(74, 2), Vector2i(78, 2), Vector2i(83, 2), Vector2i(81, 2)]},
	{"bass": Vector2i(49, 43), "chord": Vector3i(59, 64, 67), "melody": [Vector2i(79, 2), Vector2i(78, 2), Vector2i(76, 2), Vector2i(74, 2)]},
	{"bass": Vector2i(42, 49), "chord": Vector3i(58, 61, 67), "melody": [Vector2i(79, 3), Vector2i(78, 1), Vector2i(76, 2), Vector2i(73, 2)]},
	{"bass": Vector2i(47, 42), "chord": Vector3i(57, 61, 66), "melody": [Vector2i(74, 3), Vector2i(71, 3), Vector2i(0, 2)]},
]

const BOSSA_HOPE: Array[Dictionary] = [
	{"bass": Vector2i(48, 43), "chord": Vector3i(59, 62, 64), "melody": [Vector2i(76, 3), Vector2i(79, 2), Vector2i(83, 3)]},
	{"bass": Vector2i(45, 52), "chord": Vector3i(60, 64, 71), "melody": [Vector2i(84, 3), Vector2i(83, 1), Vector2i(81, 2), Vector2i(79, 2)]},
	{"bass": Vector2i(50, 45), "chord": Vector3i(60, 64, 65), "melody": [Vector2i(77, 3), Vector2i(76, 1), Vector2i(74, 2), Vector2i(72, 2)]},
	{"bass": Vector2i(43, 50), "chord": Vector3i(59, 64, 65), "melody": [Vector2i(76, 3), Vector2i(74, 1), Vector2i(71, 3), Vector2i(0, 1)]},
	{"bass": Vector2i(40, 47), "chord": Vector3i(59, 62, 67), "melody": [Vector2i(76, 2), Vector2i(74, 2), Vector2i(72, 2), Vector2i(71, 2)]},
	{"bass": Vector2i(45, 52), "chord": Vector3i(58, 61, 67), "melody": [Vector2i(73, 3), Vector2i(74, 1), Vector2i(76, 2), Vector2i(72, 2)]},
	{"bass": Vector2i(50, 45), "chord": Vector3i(60, 64, 65), "melody": [Vector2i(74, 3), Vector2i(72, 1), Vector2i(69, 2), Vector2i(71, 2)]},
	{"bass": Vector2i(43, 48), "chord": Vector3i(59, 62, 64), "melody": [Vector2i(72, 5), Vector2i(0, 3)]},
]

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var muted: bool = false
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var _music_volume_db: float = 0.0
var _sfx_volumes_db: Array[float] = []
var _next_sfx_player_index: int = 0
var _music: Dictionary[StringName, AudioStreamWAV] = {}
var _effects: Dictionary[StringName, AudioStreamWAV] = {}
var _pending_track: StringName
var _pending_volume: float = MUSIC_VOLUME_DB
var _pending_pitch: float = 1.0
var _synthesis_deadline: int = 0
const ROOM_TRACKS: Array[StringName] = [&"morning", &"nocturne", &"night"]

var _nylon_wave: PackedFloat32Array = PackedFloat32Array()
var _rhodes_wave: PackedFloat32Array = PackedFloat32Array()
var _flute_wave: PackedFloat32Array = PackedFloat32Array()
var _bass_wave: PackedFloat32Array = PackedFloat32Array()
var _shaker_wave: PackedFloat32Array = PackedFloat32Array()
var _beat_phase: float = 1.0
var _vibrato_time: float = 0.0
var _breath_cue_frame: int = -1


func _ready() -> void:
	_build_wavetables()
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)
	for index: int in range(SFX_POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % index
		add_child(player)
		sfx_players.append(player)
		_sfx_volumes_db.append(0.0)

	GameManager.state_changed.connect(_on_state_changed)
	GameManager.room_changed.connect(_on_room_changed)
	GameManager.mind_state_changed.connect(_on_mind_state_changed)
	GameManager.exhausted_changed.connect(_on_exhausted_changed)
	GameManager.clarity_ready_changed.connect(_on_clarity_ready_changed)
	GameManager.habits_updated.connect(_on_habits_updated)
	get_tree().node_added.connect(_on_node_added)
	for node: Node in get_tree().get_nodes_in_group(&"player"):
		_on_node_added(node)
	_update_music()
	_generate_audio.call_deferred()


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	if GameManager.mind_state == GameManager.MindState.OVERLOAD and not GameManager.is_exhausted:
		_vibrato_time = fmod(_vibrato_time + delta, 1.0)
		music_player.pitch_scale = 1.12 + 0.008 * sin(TAU * 4.0 * _vibrato_time)
	if GameManager.mind_state != GameManager.MindState.CALM or GameManager.is_exhausted:
		_beat_phase += delta * GameManager.bpm / 60.0
		if _beat_phase >= 1.0:
			_beat_phase = fmod(_beat_phase, 1.0)
			_play_effect(&"heartbeat", -10.0)


func play_music(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	_pending_track = &""
	_music_volume_db = volume_db
	music_player.volume_db = _get_effective_volume(volume_db, music_volume)
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.play()


func stop_music() -> void:
	_pending_track = &""
	music_player.stop()


func play_track(track: StringName, volume_db: float = MUSIC_VOLUME_DB, pitch: float = 1.0) -> void:
	var stream: AudioStreamWAV = _music.get(track) as AudioStreamWAV
	if stream == null:
		stop_music()
		_pending_track = track
		_pending_volume = volume_db
		_pending_pitch = maxf(pitch, 0.1)
		return
	music_player.pitch_scale = maxf(pitch, 0.1)
	play_music(stream, volume_db)


func set_music_pitch(pitch: float) -> void:
	var clamped: float = maxf(pitch, 0.1)
	_pending_pitch = clamped
	if music_player != null:
		music_player.pitch_scale = clamped


func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null or sfx_players.is_empty():
		return
	var index: int = _next_sfx_player_index
	var player: AudioStreamPlayer = sfx_players[index]
	_next_sfx_player_index = (index + 1) % sfx_players.size()
	_sfx_volumes_db[index] = volume_db
	player.stream = stream
	player.volume_db = _get_effective_volume(volume_db, sfx_volume)
	player.pitch_scale = maxf(pitch_scale, 0.01)
	player.play()


func set_muted(value: bool) -> void:
	muted = value
	_apply_music_volume()
	_apply_sfx_volume()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_music_volume()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_sfx_volume()


func play_ui_cue() -> void:
	_play_effect(&"habit_select")


func play_voice_blip() -> void:
	_play_effect(&"voice_blip", -16.0)


func play_pickup() -> void:
	_play_effect(&"pickup", -9.0)


func play_door_open() -> void:
	_play_effect(&"door_open", -7.0)


func play_alarm_beep() -> void:
	_play_effect(&"alarm_beep", -14.0)


func play_console_boot() -> void:
	_play_effect(&"console_boot", -7.0)


func _apply_music_volume() -> void:
	if music_player != null:
		music_player.volume_db = _get_effective_volume(_music_volume_db, music_volume)


func _apply_sfx_volume() -> void:
	for index: int in range(sfx_players.size()):
		sfx_players[index].volume_db = _get_effective_volume(_sfx_volumes_db[index], sfx_volume)


func _get_effective_volume(volume_db: float, gain: float) -> float:
	return -80.0 if muted or gain <= 0.001 else volume_db + linear_to_db(gain)


func _play_effect(effect: StringName, volume_db: float = -5.0) -> void:
	play_sfx(_effects.get(effect) as AudioStreamWAV, volume_db)


func _on_state_changed(state: GameManager.GameState) -> void:
	if state != GameManager.GameState.PLAYING:
		_beat_phase = 1.0
		_stop_heartbeat()
	music_player.stream_paused = state == GameManager.GameState.PAUSED
	match state:
		GameManager.GameState.VICTORY:
			stop_music()
			_play_effect(&"victory")
		GameManager.GameState.GAME_OVER:
			stop_music()
			_play_effect(&"game_over")
		GameManager.GameState.CUTSCENE:
			pass
		GameManager.GameState.MENU, GameManager.GameState.HABIT_SELECT, GameManager.GameState.PLAYING, GameManager.GameState.DIALOGUE:
			_update_music()


func _on_room_changed(_room: int) -> void:
	_update_music()


func _update_music() -> void:
	var track: StringName
	var volume: float = MUSIC_VOLUME_DB
	match GameManager.current_state:
		GameManager.GameState.MENU, GameManager.GameState.HABIT_SELECT:
			track = &"menu"
			music_player.pitch_scale = 1.0
		GameManager.GameState.DIALOGUE:
			track = &"boss" if GameManager.is_final_room() else ROOM_TRACKS[GameManager.get_turn() - 1]
			music_player.pitch_scale = 1.0
			volume -= 7.0
		GameManager.GameState.PLAYING:
			track = &"boss" if GameManager.is_final_room() else ROOM_TRACKS[GameManager.get_turn() - 1]
			_update_pitch()
		_:
			return
	var stream: AudioStreamWAV = _music.get(track) as AudioStreamWAV
	if stream == null:
		stop_music()
		_pending_track = track
		return
	play_music(stream, volume)


func _on_mind_state_changed(_state: GameManager.MindState) -> void:
	_update_reaction()


func _on_exhausted_changed(_exhausted: bool) -> void:
	_update_reaction()


func _update_reaction() -> void:
	_vibrato_time = 0.0
	if GameManager.current_state == GameManager.GameState.PLAYING:
		_update_pitch()
	if GameManager.mind_state == GameManager.MindState.CALM and not GameManager.is_exhausted:
		_beat_phase = 1.0
		_stop_heartbeat()


func _update_pitch() -> void:
	if GameManager.is_exhausted:
		music_player.pitch_scale = 0.90
	else:
		match GameManager.mind_state:
			GameManager.MindState.CALM: music_player.pitch_scale = 1.0
			GameManager.MindState.ANXIOUS: music_player.pitch_scale = 1.06
			GameManager.MindState.OVERLOAD: music_player.pitch_scale = 1.12


func _stop_heartbeat() -> void:
	var heartbeat: AudioStreamWAV = _effects.get(&"heartbeat") as AudioStreamWAV
	if heartbeat == null:
		return
	for player: AudioStreamPlayer in sfx_players:
		if player.stream == heartbeat:
			player.stop()


func _on_clarity_ready_changed(is_ready: bool) -> void:
	if is_ready:
		_on_breathing_completed()


func _on_habits_updated(sleep_rank: int, nutrition_rank: int, ally_count: int) -> void:
	if GameManager.current_state == GameManager.GameState.HABIT_SELECT \
			and sleep_rank + nutrition_rank + ally_count > 0:
		_play_effect(&"habit_select")


func _on_node_added(node: Node) -> void:
	var player: Player = node as Player
	if player == null or player.attacked.is_connected(_on_player_attacked):
		return
	player.attacked.connect(_on_player_attacked)
	player.dashed.connect(_on_player_dashed)
	player.breathing_completed.connect(_on_breathing_completed)
	player.hit_taken.connect(_on_player_hit)


func _on_player_attacked(is_clarity: bool, _origin: Vector2, _direction: Vector2,
		_attack_range: float, _damage: int) -> void:
	_play_effect(&"clarity_strike" if is_clarity else &"attack")


func _on_player_dashed(_direction: Vector2) -> void:
	_play_effect(&"dash")


func _on_breathing_completed() -> void:
	# The first completed breath emits both the readiness and completion signals.
	var frame: int = Engine.get_process_frames()
	if _breath_cue_frame != frame:
		_breath_cue_frame = frame
		_play_effect(&"breathe_complete")


func _on_player_hit(_bpm_added: float) -> void:
	_play_effect(&"player_hit")


func _build_wavetables() -> void:
	_nylon_wave.resize(WAVE_SIZE)
	_rhodes_wave.resize(WAVE_SIZE)
	_flute_wave.resize(WAVE_SIZE)
	_bass_wave.resize(WAVE_SIZE)
	_shaker_wave.resize(SHAKER_SIZE)
	for idx: int in range(WAVE_SIZE):
		var a: float = TAU * float(idx) / float(WAVE_SIZE)
		# Violão de nylon quente, Rhodes aveludado, flauta suave e baixo acústico de polegar.
		_nylon_wave[idx] = (sin(a) + 0.44 * sin(a * 2.0 + 0.25) + 0.18 * sin(a * 3.0)
				+ 0.065 * sin(a * 4.0 + 0.45) + 0.02 * sin(a * 5.0)) / 1.58
		_rhodes_wave[idx] = (sin(a) + 0.28 * sin(a * 2.0) + 0.09 * sin(a * 3.0)
				+ 0.03 * sin(a * 6.0)) / 1.32
		_flute_wave[idx] = (sin(a) + 0.24 * sin(a * 2.0) + 0.11 * sin(a * 3.0)
				+ 0.03 * sin(a * 4.0)) / 1.28
		_bass_wave[idx] = (sin(a) + 0.36 * sin(a * 2.0) + 0.09 * sin(a * 3.0)) / 1.38

	var lcg: int = 20260417
	var prev: float = 0.0
	for s_idx: int in range(SHAKER_SIZE):
		lcg = (lcg * 1664525 + 1013904223) & 0x7fffffff
		var white: float = (float(lcg) / 2147483647.0) * 2.0 - 1.0
		# Suavização simples simulando vassourinha / ganzá quente sem estalo áspero.
		var brushed: float = white * 0.55 - prev * 0.35
		prev = white
		_shaker_wave[s_idx] = clampf(brushed, -1.0, 1.0)


func _generate_audio() -> void:
	_synthesis_deadline = Time.get_ticks_usec() + SYNTHESIS_BUDGET_US
	for effect: StringName in EFFECT_SCORES:
		var score: Array[Vector3i] = []
		score.assign(EFFECT_SCORES[effect])
		var sfx_timbre: StringName = &"pad" if effect == &"heartbeat" else (&"rhodes" if effect in [&"player_hit", &"core_hit", &"attack", &"dash"] else &"nylon")
		_effects[effect] = await _render_score(score, 0.036, sfx_timbre, false)

	await _generate_bossa_track(&"menu", BOSSA_MENU, 0.235, &"rhodes", &"bossa")
	await _generate_bossa_track(&"beethoven", BOSSA_BEETHOVEN, 0.16, &"flute", &"urgent")
	await _generate_bossa_track(&"poem", BOSSA_POEM, 0.285, &"flute", &"arpeggio")
	await _generate_bossa_track(&"morning", BOSSA_MORNING, 0.21, &"rhodes", &"bossa")
	await _generate_bossa_track(&"nocturne", BOSSA_NOCTURNE, 0.23, &"flute", &"bossa")
	await _generate_bossa_track(&"night", BOSSA_NIGHT, 0.25, &"rhodes", &"bossa")
	await _generate_bossa_track(&"boss", BOSSA_BOSS, 0.155, &"flute", &"urgent")
	await _generate_bossa_track(&"hope", BOSSA_HOPE, 0.265, &"rhodes", &"bossa")


func _generate_bossa_track(track: StringName, bars: Array[Dictionary], step_seconds: float,
		lead_style: StringName, groove_mode: StringName) -> void:
	_music[track] = await _render_bossa_track(bars, step_seconds, lead_style, groove_mode)
	if _pending_track == track:
		if GameManager.current_state == GameManager.GameState.CUTSCENE:
			play_track(track, _pending_volume, _pending_pitch)
		else:
			_update_music()


func _sample_wave(table: PackedFloat32Array, phase: float) -> float:
	var pos: float = fposmod(phase, 1.0) * float(WAVE_SIZE)
	var i0: int = int(pos) % WAVE_SIZE
	var i1: int = (i0 + 1) % WAVE_SIZE
	return lerpf(table[i0], table[i1], pos - floorf(pos))


func _yield_if_needed() -> void:
	if Time.get_ticks_usec() >= _synthesis_deadline:
		await get_tree().process_frame
		_synthesis_deadline = Time.get_ticks_usec() + SYNTHESIS_BUDGET_US


func _render_bossa_track(bars: Array[Dictionary], step_seconds: float, lead_style: StringName,
		groove_mode: StringName) -> AudioStreamWAV:
	var samples_per_step: int = roundi(step_seconds * float(SAMPLE_RATE))
	var samples_per_bar: int = samples_per_step * 8
	var total_samples: int = maxi(1, bars.size() * samples_per_bar)
	var mix_buf: PackedFloat32Array = PackedFloat32Array()
	mix_buf.resize(total_samples)

	var lead_table: PackedFloat32Array = _flute_wave if lead_style == &"flute" else _rhodes_wave
	var attack_samples: float = float(SAMPLE_RATE) * (0.026 if lead_style == &"flute" else 0.014)
	var release_samples: float = float(SAMPLE_RATE) * 0.060
	var chord_len: int = roundi(step_seconds * 2.4 * float(SAMPLE_RATE))
	var pluck_atk: float = maxf(1.0, float(SAMPLE_RATE) * 0.008)
	var inv_sr: float = 1.0 / float(SAMPLE_RATE)

	for bar_idx: int in range(bars.size()):
		await _yield_if_needed()
		var bar: Dictionary = bars[bar_idx]
		var bar_offset: int = bar_idx * samples_per_bar
		var bass_pair: Vector2i = bar["bass"]
		var chord: Vector3i = bar["chord"]

		# 1. Violão de nylon (dedilhado arpejado para poema ou batida sincopada de Bossa Nova).
		if groove_mode == &"arpeggio":
			var root_arp: int = bass_pair.x + 12
			var arp_notes: Array[int] = [
				root_arp, chord.x, chord.y, chord.z,
				chord.y, chord.x, chord.z, chord.y,
			]
			var arp_len: int = roundi(float(samples_per_step) * 2.2)
			for step_idx: int in range(8):
				var arp_step: float = _note_step(arp_notes[step_idx])
				var arp_gain: float = 0.145 if step_idx == 0 else 0.115
				var start_pos: int = bar_offset + step_idx * samples_per_step
				for s: int in range(arp_len):
					var env: float = (float(s) / pluck_atk) if float(s) < pluck_atk else exp(-3.6 * float(s) * inv_sr)
					var dest: int = (start_pos + s) % total_samples
					mix_buf[dest] += _sample_wave(_nylon_wave, float(s) * arp_step) * env * arp_gain
		else:
			var step_x: float = _note_step(chord.x)
			var step_y: float = _note_step(chord.y)
			var step_z: float = _note_step(chord.z)
			var chord_pluck: PackedFloat32Array = PackedFloat32Array()
			chord_pluck.resize(chord_len)
			var rel_samples: float = float(SAMPLE_RATE) * 0.045
			for s: int in range(chord_len):
				var env: float = 1.0
				if float(s) < pluck_atk:
					env = float(s) / pluck_atk
				elif chord_len - s < int(rel_samples):
					env = float(chord_len - s) / rel_samples
				var decay: float = exp(-4.8 * float(s) * inv_sr)
				var v: float = (_sample_wave(_nylon_wave, float(s) * step_x)
						+ _sample_wave(_nylon_wave, float(s) * step_y) * 0.94
						+ _sample_wave(_nylon_wave, float(s) * step_z) * 0.90) * 0.34
				chord_pluck[s] = v * env * decay

			var strum_steps: Array[float] = []
			var strum_gains: Array[float] = []
			if groove_mode == &"urgent":
				strum_steps = [0.0, 1.5, 3.0, 4.5, 6.0, 7.0]
				strum_gains = [0.22, 0.16, 0.20, 0.16, 0.19, 0.15]
			elif (bar_idx % 2) == 0:
				# Clave clássica de Bossa Nova: compasso par sincopado sobre as colcheias/semicolcheias.
				strum_steps = [0.0, 1.5, 3.0, 5.0, 6.0]
				strum_gains = [0.24, 0.17, 0.22, 0.18, 0.20]
			else:
				strum_steps = [1.0, 2.0, 3.5, 5.0, 6.5]
				strum_gains = [0.18, 0.19, 0.21, 0.17, 0.20]

			for idx: int in range(strum_steps.size()):
				var hit_pos: int = bar_offset + roundi(strum_steps[idx] * float(samples_per_step))
				var hit_gain: float = strum_gains[idx]
				for s: int in range(chord_len):
					var dest: int = (hit_pos + s) % total_samples
					mix_buf[dest] += chord_pluck[s] * hit_gain

		# 2. Baixo acústico quente no tempo 1, tempo 3 e antecipação de Bossa.
		var bass_hits: Array[Vector2] = [Vector2(0.0, 3.5), Vector2(4.0, 3.2)]
		if groove_mode == &"bossa" and (bar_idx % 2) == 1:
			bass_hits = [Vector2(0.0, 3.3), Vector2(4.0, 2.6), Vector2(7.0, 1.0)]
		elif groove_mode == &"urgent":
			bass_hits = [Vector2(0.0, 2.4), Vector2(3.0, 1.2), Vector2(4.0, 2.4), Vector2(7.0, 1.0)]
		elif groove_mode == &"arpeggio":
			bass_hits = [Vector2(0.0, 4.2), Vector2(4.0, 3.8)]
		var bass_atk: float = maxf(1.0, float(SAMPLE_RATE) * 0.012)
		for b_idx: int in range(bass_hits.size()):
			var b_note: int = bass_pair.x if b_idx == 0 else bass_pair.y
			var b_step: float = _note_step(b_note)
			var b_start: int = bar_offset + roundi(bass_hits[b_idx].x * float(samples_per_step))
			var b_len: int = roundi(bass_hits[b_idx].y * float(samples_per_step))
			var b_gain: float = 0.24 if b_idx == 0 else 0.19
			for s: int in range(b_len):
				var env: float = (float(s) / bass_atk) if float(s) < bass_atk else minf(1.0, float(b_len - s) / (float(SAMPLE_RATE) * 0.04))
				var decay: float = exp(-2.1 * float(s) * inv_sr)
				var dest: int = (b_start + s) % total_samples
				mix_buf[dest] += _sample_wave(_bass_wave, float(s) * b_step) * env * decay * b_gain

		# 3. Vassourinha / ganzá sutil nas faixas com levada.
		if groove_mode != &"arpeggio":
			var brush_len: int = mini(roundi(0.032 * float(SAMPLE_RATE)), SHAKER_SIZE)
			for half_step: int in range(16):
				var accent: float = 0.026 if (half_step % 4 == 2) else (0.018 if (half_step % 2 == 0) else 0.011)
				var sh_pos: int = bar_offset + roundi(float(half_step) * 0.5 * float(samples_per_step))
				var seed_shift: int = (half_step * 173 + bar_idx * 97) % SHAKER_SIZE
				for s: int in range(brush_len):
					var sh_env: float = (1.0 - float(s) / float(brush_len)) * accent
					var dest: int = (sh_pos + s) % total_samples
					mix_buf[dest] += _shaker_wave[(s + seed_shift) % SHAKER_SIZE] * sh_env

		# 4. Melodia cantabile em Rhodes ou Flauta com fraseado suave e vibrato sutil.
		var melody_offset: int = bar_offset
		var melody_events: Array = bar["melody"]
		for ev: Vector2i in melody_events:
			var length: int = ev.y * samples_per_step
			if ev.x != 0:
				var tail_len: int = roundi(float(length) * 0.24)
				var render_len: int = length + tail_len
				var note_step: float = _note_step(ev.x)
				var lead_gain: float = 0.24 if lead_style == &"rhodes" else 0.22
				var use_vibrato: bool = ev.y >= 3
				for s: int in range(render_len):
					var env: float = 1.0
					if float(s) < attack_samples:
						env = float(s) / attack_samples
					elif s >= length:
						env = maxf(0.0, 1.0 - float(s - length) / float(maxi(1, tail_len)))
					elif float(render_len - 1 - s) < release_samples:
						env = float(render_len - 1 - s) / release_samples
					var decay: float = exp(-1.55 * float(s) * inv_sr) if lead_style == &"rhodes" else (1.0 - 0.22 * float(s) / float(render_len))
					var vib: float = (1.0 + 0.0028 * sin(TAU * 4.8 * float(s) * inv_sr)) if use_vibrato else 1.0
					var dest: int = (melody_offset + s) % total_samples
					mix_buf[dest] += _sample_wave(lead_table, float(s) * note_step * vib) * env * decay * lead_gain
			melody_offset += length

	await _yield_if_needed()
	# Eco acústico suave de sala íntima + suavização sutil de agudos.
	var tap_a: int = mini(total_samples - 1, roundi(0.185 * float(SAMPLE_RATE)))
	var tap_b: int = mini(total_samples - 1, roundi(0.310 * float(SAMPLE_RATE)))
	var wet_buf: PackedFloat32Array = PackedFloat32Array()
	wet_buf.resize(total_samples)
	for idx: int in range(total_samples):
		var a_idx: int = (idx - tap_a + total_samples) % total_samples
		var b_idx: int = (idx - tap_b + total_samples) % total_samples
		wet_buf[idx] = mix_buf[idx] + mix_buf[a_idx] * 0.19 + mix_buf[b_idx] * 0.09

	var pcm: PackedByteArray = PackedByteArray()
	pcm.resize(total_samples * 2)
	var prev_sample: float = wet_buf[total_samples - 1]
	for idx: int in range(total_samples):
		var warm: float = wet_buf[idx] * 0.78 + prev_sample * 0.22
		prev_sample = wet_buf[idx]
		var shaped: float = clampf(warm * 0.88, -0.98, 0.98)
		pcm.encode_s16(idx * 2, roundi(shaped * 32767.0))

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_samples
	return stream


func _render_score(score: Array[Vector3i], tick_seconds: float, timbre: StringName,
		_loop: bool) -> AudioStreamWAV:
	var samples_per_tick: int = roundi(tick_seconds * SAMPLE_RATE)
	var total_samples: int = 0
	for event: Vector3i in score:
		total_samples += event.z * samples_per_tick

	var mix_buf: PackedFloat32Array = PackedFloat32Array()
	mix_buf.resize(total_samples)
	var lead_table: PackedFloat32Array = _nylon_wave if timbre == &"nylon" else (_flute_wave if timbre == &"pad" else _rhodes_wave)
	var attack_sec: float = 0.012 if timbre == &"pad" else 0.008
	var attack_samples: float = maxf(1.0, float(SAMPLE_RATE) * attack_sec)
	var release_samples: float = maxf(1.0, float(SAMPLE_RATE) * 0.014)
	var offset: int = 0
	for event: Vector3i in score:
		var length: int = event.z * samples_per_tick
		var lead_step: float = _note_step(event.x)
		var bass_step: float = _note_step(event.y)
		var lead_gain: float = 0.46 if event.x != 0 else 0.0
		var bass_gain: float = 0.42 if event.y != 0 else 0.0
		for block: int in range(0, length, SYNTHESIS_BLOCK_SIZE):
			await _yield_if_needed()
			var end: int = mini(block + SYNTHESIS_BLOCK_SIZE, length)
			for sample: int in range(block, end):
				var env: float = 1.0
				if float(sample) < attack_samples:
					env = float(sample) / attack_samples
				else:
					var dist_end: float = float(length - 1 - sample)
					if dist_end < release_samples:
						env = dist_end / release_samples
				var decay: float = 1.0 - 0.50 * float(sample) / float(maxi(1, length))
				var lead_val: float = _sample_wave(lead_table, float(sample) * lead_step) if lead_gain > 0.0 else 0.0
				var bass_val: float = _sample_wave(_bass_wave, float(sample) * bass_step) if bass_gain > 0.0 else 0.0
				var dest: int = mini(total_samples - 1, offset + sample)
				mix_buf[dest] += (lead_val * lead_gain + bass_val * bass_gain) * env * decay
		offset += length

	var pcm: PackedByteArray = PackedByteArray()
	pcm.resize(total_samples * 2)
	for idx: int in range(total_samples):
		var shaped: float = clampf(mix_buf[idx] * 0.88, -0.98, 0.98)
		pcm.encode_s16(idx * 2, roundi(shaped * 32767.0))

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	return stream


func _note_step(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0) / SAMPLE_RATE if note != 0 else 0.0
