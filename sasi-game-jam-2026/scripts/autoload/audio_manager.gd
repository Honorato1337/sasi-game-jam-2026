extends Node

const Player = preload("res://scenes/player/player.gd")

const SFX_POOL_SIZE: int = 8
const SAMPLE_RATE: int = 22050
const SYNTHESIS_BUDGET_US: int = 1500
const SYNTHESIS_BLOCK_SIZE: int = 256
const MUSIC_VOLUME_DB: float = -9.0

# Each event holds a MIDI melody note, a MIDI bass note and a duration in ticks.
# Zero means a rest. The phrases are original and use the composers' styles as cues.
const MENU: Array[Vector3i] = [
	Vector3i(72, 48, 2), Vector3i(76, 55, 1), Vector3i(79, 55, 1),
	Vector3i(81, 45, 2), Vector3i(79, 52, 2), Vector3i(76, 41, 2),
	Vector3i(74, 43, 1), Vector3i(71, 43, 1), Vector3i(72, 48, 3), Vector3i(0, 0, 1),
]
const MORNING: Array[Vector3i] = [
	Vector3i(60, 48, 1), Vector3i(67, 48, 1), Vector3i(72, 52, 1), Vector3i(76, 52, 1),
	Vector3i(67, 48, 1), Vector3i(72, 48, 1), Vector3i(76, 55, 1), Vector3i(79, 55, 1),
	Vector3i(65, 45, 1), Vector3i(69, 45, 1), Vector3i(74, 50, 1), Vector3i(77, 50, 1),
	Vector3i(69, 45, 1), Vector3i(74, 45, 1), Vector3i(77, 53, 1), Vector3i(81, 53, 1),
	Vector3i(64, 48, 1), Vector3i(69, 48, 1), Vector3i(72, 45, 1), Vector3i(76, 45, 1),
	Vector3i(65, 41, 1), Vector3i(72, 41, 1), Vector3i(77, 48, 1), Vector3i(81, 48, 1),
	Vector3i(67, 43, 1), Vector3i(74, 43, 1), Vector3i(77, 47, 1), Vector3i(83, 47, 1),
	Vector3i(79, 43, 1), Vector3i(77, 43, 1), Vector3i(74, 47, 1), Vector3i(71, 47, 1),
]
const NOCTURNE: Array[Vector3i] = [
	Vector3i(76, 45, 3), Vector3i(81, 52, 2), Vector3i(83, 57, 1),
	Vector3i(84, 41, 2), Vector3i(83, 48, 1), Vector3i(79, 53, 3),
	Vector3i(77, 50, 3), Vector3i(76, 57, 2), Vector3i(74, 53, 1),
	Vector3i(71, 40, 2), Vector3i(80, 47, 1), Vector3i(76, 56, 3),
	Vector3i(81, 45, 4), Vector3i(79, 52, 1), Vector3i(76, 57, 1),
	Vector3i(77, 41, 2), Vector3i(74, 48, 1), Vector3i(72, 53, 3),
	Vector3i(71, 40, 2), Vector3i(74, 47, 1), Vector3i(76, 56, 2),
	Vector3i(74, 47, 1), Vector3i(72, 45, 2), Vector3i(69, 52, 3), Vector3i(0, 45, 1),
]
const BOSS: Array[Vector3i] = [
	Vector3i(71, 35, 2), Vector3i(78, 42, 1), Vector3i(79, 35, 1),
	Vector3i(78, 42, 2), Vector3i(74, 35, 1), Vector3i(73, 42, 1),
	Vector3i(71, 35, 1), Vector3i(71, 42, 1), Vector3i(74, 35, 1), Vector3i(78, 42, 1),
	Vector3i(83, 31, 3), Vector3i(81, 38, 1), Vector3i(79, 31, 2), Vector3i(78, 38, 2),
	Vector3i(76, 40, 1), Vector3i(74, 47, 1), Vector3i(76, 40, 1), Vector3i(79, 47, 1),
	Vector3i(78, 30, 2), Vector3i(77, 42, 1), Vector3i(78, 30, 1),
	Vector3i(85, 42, 2), Vector3i(82, 46, 1), Vector3i(78, 42, 1),
]
const EFFECT_SCORES: Dictionary[StringName, Array] = {
	&"attack": [Vector3i(77, 0, 1), Vector3i(65, 0, 1), Vector3i(54, 0, 1)],
	&"clarity_strike": [Vector3i(72, 48, 1), Vector3i(79, 55, 1), Vector3i(84, 60, 3)],
	&"dash": [Vector3i(55, 0, 1), Vector3i(62, 0, 1), Vector3i(71, 0, 1), Vector3i(82, 0, 1)],
	&"breathe_complete": [Vector3i(67, 48, 2), Vector3i(72, 52, 2), Vector3i(76, 55, 4)],
	&"player_hit": [Vector3i(51, 37, 1), Vector3i(48, 33, 1), Vector3i(43, 29, 2)],
	&"core_hit": [Vector3i(39, 32, 2), Vector3i(33, 25, 3)],
	&"heartbeat": [Vector3i(0, 43, 2), Vector3i(0, 0, 1), Vector3i(0, 38, 2)],
	&"habit_select": [Vector3i(74, 50, 1), Vector3i(79, 55, 2)],
	&"victory": [Vector3i(72, 48, 2), Vector3i(76, 48, 2), Vector3i(79, 55, 2),
		Vector3i(84, 48, 7)],
	&"game_over": [Vector3i(71, 47, 2), Vector3i(67, 43, 2), Vector3i(63, 39, 3),
		Vector3i(59, 35, 7)],
}

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var muted: bool = false
var _music_volume_db: float = 0.0
var _sfx_volumes_db: Array[float] = []
var _next_sfx_player_index: int = 0
var _music: Dictionary[StringName, AudioStreamWAV] = {}
var _effects: Dictionary[StringName, AudioStreamWAV] = {}
var _pending_track: StringName
var _synthesis_deadline: int = 0
var _bpm: float
var _signal_level: GameManager.SignalLevel
var _previous_core_hp: int
var _beat_phase: float = 1.0
var _vibrato_time: float = 0.0
var _breath_cue_frame: int = -1


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)
	for index: int in range(SFX_POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % index
		add_child(player)
		sfx_players.append(player)
		_sfx_volumes_db.append(0.0)

	_bpm = GameManager.bpm
	_previous_core_hp = GameManager.core_hp
	_on_signal_level_changed(GameManager.signal_level)
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.bpm_changed.connect(_on_bpm_changed)
	GameManager.signal_level_changed.connect(_on_signal_level_changed)
	GameManager.core_hp_changed.connect(_on_core_hp_changed)
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
	if _signal_level == GameManager.SignalLevel.OVERLOAD:
		_vibrato_time = fmod(_vibrato_time + delta, 1.0)
		music_player.pitch_scale = 1.12 + 0.008 * sin(TAU * 4.0 * _vibrato_time)
	if _signal_level != GameManager.SignalLevel.CALM:
		_beat_phase += delta * _bpm / 60.0
		if _beat_phase >= 1.0:
			_beat_phase = fmod(_beat_phase, 1.0)
			_play_effect(&"heartbeat", -10.0)


func play_music(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	_pending_track = &""
	_music_volume_db = volume_db
	music_player.volume_db = _get_effective_volume(volume_db)
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.play()


func stop_music() -> void:
	_pending_track = &""
	music_player.stop()


func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null or sfx_players.is_empty():
		return
	var index: int = _next_sfx_player_index
	var player: AudioStreamPlayer = sfx_players[index]
	_next_sfx_player_index = (index + 1) % sfx_players.size()
	_sfx_volumes_db[index] = volume_db
	player.stream = stream
	player.volume_db = _get_effective_volume(volume_db)
	player.pitch_scale = maxf(pitch_scale, 0.01)
	player.play()


func set_muted(value: bool) -> void:
	muted = value
	if music_player != null:
		music_player.volume_db = _get_effective_volume(_music_volume_db)
	for index: int in range(sfx_players.size()):
		sfx_players[index].volume_db = _get_effective_volume(_sfx_volumes_db[index])


func _get_effective_volume(volume_db: float) -> float:
	return -80.0 if muted else volume_db


func _play_effect(effect: StringName, volume_db: float = -5.0) -> void:
	play_sfx(_effects.get(effect) as AudioStreamWAV, volume_db)


func _on_state_changed(state: GameManager.GameState) -> void:
	if state != GameManager.GameState.PLAYING:
		_beat_phase = 1.0
	music_player.stream_paused = state == GameManager.GameState.PAUSED
	match state:
		GameManager.GameState.VICTORY:
			stop_music()
			_play_effect(&"victory")
		GameManager.GameState.GAME_OVER:
			stop_music()
			_play_effect(&"game_over")
		GameManager.GameState.MENU, GameManager.GameState.HABIT_SELECT, GameManager.GameState.PLAYING:
			_update_music()


func _on_wave_changed(_wave: int) -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		_update_music()


func _update_music() -> void:
	var track: StringName
	match GameManager.current_state:
		GameManager.GameState.MENU, GameManager.GameState.HABIT_SELECT:
			track = &"menu"
			music_player.pitch_scale = 1.0
		GameManager.GameState.PLAYING:
			match GameManager.wave:
				1:
					track = &"morning"
				2, 3:
					track = &"nocturne"
				4:
					track = &"boss"
			_update_pitch()
		_:
			return
	var stream: AudioStreamWAV = _music.get(track) as AudioStreamWAV
	if stream == null:
		stop_music()
		_pending_track = track
		return
	play_music(stream, MUSIC_VOLUME_DB)


func _on_bpm_changed(bpm: float, _level: GameManager.SignalLevel) -> void:
	_bpm = bpm


func _on_signal_level_changed(level: GameManager.SignalLevel) -> void:
	if _signal_level == GameManager.SignalLevel.CALM:
		_beat_phase = 1.0
	_signal_level = level
	_vibrato_time = 0.0
	if GameManager.current_state == GameManager.GameState.PLAYING:
		_update_pitch()


func _update_pitch() -> void:
	match _signal_level:
		GameManager.SignalLevel.CALM:
			music_player.pitch_scale = 1.0
		GameManager.SignalLevel.WARNING:
			music_player.pitch_scale = 1.06
		GameManager.SignalLevel.OVERLOAD:
			music_player.pitch_scale = 1.12
		GameManager.SignalLevel.EXHAUSTED:
			music_player.pitch_scale = 0.92


func _on_core_hp_changed(hp: int, _max_hp: int) -> void:
	if hp < _previous_core_hp:
		_play_effect(&"core_hit")
	_previous_core_hp = hp


func _on_clarity_ready_changed(is_ready: bool) -> void:
	if is_ready:
		_on_breathing_completed()


func _on_habits_updated(sleep_rank: int, nutrition_rank: int, ally_count: int) -> void:
	if GameManager.current_state == GameManager.GameState.HABIT_SELECT 			and sleep_rank + nutrition_rank + ally_count > 0:
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


func _generate_audio() -> void:
	_synthesis_deadline = Time.get_ticks_usec() + SYNTHESIS_BUDGET_US
	for effect: StringName in EFFECT_SCORES:
		var score: Array[Vector3i] = []
		score.assign(EFFECT_SCORES[effect])
		_effects[effect] = await _render_score(score, 0.026, 0.31, false)

	await _generate_track(&"menu", MENU, 0.29, 0.46)
	await _generate_track(&"morning", MORNING, 0.17, 0.5)
	await _generate_track(&"nocturne", NOCTURNE, 0.23, 0.33)
	await _generate_track(&"boss", BOSS, 0.145, 0.25)


func _generate_track(track: StringName, score: Array[Vector3i], tick: float, duty: float) -> void:
	_music[track] = await _render_score(score, tick, duty, true)
	if _pending_track == track:
		_update_music()


func _render_score(score: Array[Vector3i], tick_seconds: float, duty: float,
		loop: bool) -> AudioStreamWAV:
	var samples_per_tick: int = roundi(tick_seconds * SAMPLE_RATE)
	var total_samples: int = 0
	for event: Vector3i in score:
		total_samples += event.z * samples_per_tick

	var pcm: PackedByteArray = PackedByteArray()
	pcm.resize(total_samples * 2)
	var offset: int = 0
	for event: Vector3i in score:
		var length: int = event.z * samples_per_tick
		var lead_step: float = _note_step(event.x)
		var bass_step: float = _note_step(event.y)
		var fade_samples: float = SAMPLE_RATE * (0.009 if loop else 0.005)
		var lead_gain: float = (0.23 if loop else 0.46) if event.x != 0 else 0.0
		var bass_gain: float = (0.18 if loop else 0.47) if event.y != 0 else 0.0
		for block: int in range(0, length, SYNTHESIS_BLOCK_SIZE):
			if Time.get_ticks_usec() >= _synthesis_deadline:
				# Spread PCM synthesis across frames on single-threaded Web exports.
				await get_tree().process_frame
				_synthesis_deadline = Time.get_ticks_usec() + SYNTHESIS_BUDGET_US
			var end: int = mini(block + SYNTHESIS_BLOCK_SIZE, length)
			for sample: int in range(block, end):
				var lead_phase: float = fmod(sample * lead_step, 1.0)
				var bass_phase: float = fmod(sample * bass_step, 1.0)
				var pulse: float = (1.0 if lead_phase < duty else -1.0) + 1.0 - 2.0 * duty
				var triangle: float = 1.0 - 4.0 * absf(bass_phase - 0.5)
				var envelope: float = minf(1.0, mini(sample, length - 1 - sample) / fade_samples)
				var decay: float = 1.0 - 0.38 * float(sample) / length
				var amplitude: float = (pulse * lead_gain + triangle * bass_gain) * envelope * decay
				pcm.encode_s16((offset + sample) * 2, roundi(amplitude * 32767.0))
		offset += length

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = total_samples
	return stream


func _note_step(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0) / SAMPLE_RATE if note != 0 else 0.0
