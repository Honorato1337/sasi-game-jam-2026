extends Node

const Player = preload("res://scenes/player/player.gd")

const SFX_POOL_SIZE: int = 8
const SAMPLE_RATE: int = 22050
const WAVE_SIZE: int = 1024
const SYNTHESIS_BUDGET_US: int = 2500
const SYNTHESIS_BLOCK_SIZE: int = 512
const MUSIC_VOLUME_DB: float = -7.5

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
const BEETHOVEN: Array[Vector3i] = [
	# Compasso 1 (8 ticks): motivo rítmico dramático em Dó menor
	Vector3i(67, 48, 1), Vector3i(67, 48, 1), Vector3i(67, 48, 1),
	Vector3i(63, 39, 3), Vector3i(0, 48, 1), Vector3i(65, 43, 1),
	# Compasso 2 (8 ticks): resposta descendente
	Vector3i(65, 43, 1), Vector3i(65, 43, 1), Vector3i(65, 43, 1),
	Vector3i(62, 38, 3), Vector3i(0, 43, 1), Vector3i(67, 48, 1),
	# Compasso 3 (8 ticks): arpejo urgente ascendente
	Vector3i(72, 48, 1), Vector3i(75, 48, 1), Vector3i(79, 51, 1), Vector3i(75, 51, 1),
	Vector3i(77, 50, 1), Vector3i(74, 50, 1), Vector3i(79, 43, 1), Vector3i(74, 43, 1),
	# Compasso 4 (8 ticks): tensão e retorno
	Vector3i(75, 48, 2), Vector3i(74, 43, 1), Vector3i(72, 48, 1),
	Vector3i(71, 43, 2), Vector3i(72, 48, 1), Vector3i(0, 36, 1),
]
const HOPE: Array[Vector3i] = [
	Vector3i(72, 48, 2), Vector3i(76, 52, 2), Vector3i(79, 55, 2), Vector3i(84, 52, 2),
	Vector3i(81, 53, 2), Vector3i(79, 55, 2), Vector3i(76, 52, 3), Vector3i(0, 48, 1),
	Vector3i(74, 50, 2), Vector3i(77, 53, 2), Vector3i(76, 52, 2), Vector3i(72, 48, 2),
	Vector3i(74, 43, 2), Vector3i(71, 47, 2), Vector3i(72, 48, 3), Vector3i(0, 48, 1),
]
const NIGHT: Array[Vector3i] = [
	Vector3i(69, 45, 2), Vector3i(72, 52, 2), Vector3i(76, 57, 2), Vector3i(74, 53, 2),
	Vector3i(72, 48, 3), Vector3i(0, 48, 1), Vector3i(71, 43, 2), Vector3i(69, 45, 2),
	Vector3i(67, 43, 2), Vector3i(72, 48, 2), Vector3i(74, 50, 2), Vector3i(76, 52, 2),
	Vector3i(72, 45, 3), Vector3i(69, 45, 3), Vector3i(0, 40, 2),
]
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
	&"victory": [Vector3i(72, 48, 2), Vector3i(76, 48, 2), Vector3i(79, 55, 2),
		Vector3i(84, 48, 7)],
	&"game_over": [Vector3i(71, 47, 2), Vector3i(67, 43, 2), Vector3i(63, 39, 3),
		Vector3i(59, 35, 7)],
}

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
var _piano_wave: PackedFloat32Array = PackedFloat32Array()
var _pad_wave: PackedFloat32Array = PackedFloat32Array()
var _bell_wave: PackedFloat32Array = PackedFloat32Array()
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


func _build_wavetables() -> void:
	_piano_wave.resize(WAVE_SIZE)
	_pad_wave.resize(WAVE_SIZE)
	_bell_wave.resize(WAVE_SIZE)
	for idx: int in range(WAVE_SIZE):
		var a: float = TAU * float(idx) / float(WAVE_SIZE)
		# Piano de feltro quente, cordas suaves e celesta sem ondas quadradas agressivas.
		_piano_wave[idx] = (sin(a) + 0.34 * sin(a * 2.0) + 0.11 * sin(a * 3.0) + 0.03 * sin(a * 4.0)) / 1.38
		_pad_wave[idx] = (sin(a) + 0.26 * sin(a * 2.0) + 0.16 * sin(a * 3.0) + 0.06 * sin(a * 5.0)) / 1.32
		_bell_wave[idx] = (sin(a) + 0.18 * sin(a * 2.0) + 0.08 * sin(a * 3.0)) / 1.20


func _generate_audio() -> void:
	_synthesis_deadline = Time.get_ticks_usec() + SYNTHESIS_BUDGET_US
	for effect: StringName in EFFECT_SCORES:
		var score: Array[Vector3i] = []
		score.assign(EFFECT_SCORES[effect])
		var sfx_timbre: StringName = &"pad" if effect == &"heartbeat" else (&"piano" if effect in [&"player_hit", &"core_hit", &"attack", &"dash"] else &"bell")
		_effects[effect] = await _render_score(score, 0.036, sfx_timbre, false)

	await _generate_track(&"menu", MENU, 0.29, &"piano")
	await _generate_track(&"beethoven", BEETHOVEN, 0.16, &"strings")
	await _generate_track(&"morning", MORNING, 0.18, &"bell")
	await _generate_track(&"nocturne", NOCTURNE, 0.24, &"piano")
	await _generate_track(&"night", NIGHT, 0.26, &"piano")
	await _generate_track(&"boss", BOSS, 0.155, &"strings")
	await _generate_track(&"hope", HOPE, 0.31, &"bell")


func _generate_track(track: StringName, score: Array[Vector3i], tick: float, timbre: StringName) -> void:
	_music[track] = await _render_score(score, tick, timbre, true)
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


func _render_score(score: Array[Vector3i], tick_seconds: float, timbre: StringName,
		loop: bool) -> AudioStreamWAV:
	var samples_per_tick: int = roundi(tick_seconds * SAMPLE_RATE)
	var total_samples: int = 0
	for event: Vector3i in score:
		total_samples += event.z * samples_per_tick

	var mix_buf: PackedFloat32Array = PackedFloat32Array()
	mix_buf.resize(total_samples)
	var lead_table: PackedFloat32Array = _piano_wave
	var attack_sec: float = 0.018
	if timbre == &"strings":
		lead_table = _pad_wave
		attack_sec = 0.042 if loop else 0.012
	elif timbre == &"bell":
		lead_table = _bell_wave
		attack_sec = 0.010 if loop else 0.006
	elif timbre == &"pad":
		lead_table = _pad_wave
		attack_sec = 0.014

	var attack_samples: float = maxf(1.0, float(SAMPLE_RATE) * attack_sec)
	var release_samples: float = maxf(1.0, float(SAMPLE_RATE) * (0.045 if loop else 0.014))
	var offset: int = 0
	for event: Vector3i in score:
		var length: int = event.z * samples_per_tick
		var tail_len: int = roundi(float(length) * 0.28) if loop else 0
		var render_len: int = length + tail_len
		var lead_step: float = _note_step(event.x)
		var bass_step: float = _note_step(event.y)
		var lead_gain: float = (0.30 if loop else 0.48) if event.x != 0 else 0.0
		var bass_gain: float = (0.24 if loop else 0.44) if event.y != 0 else 0.0
		for block: int in range(0, render_len, SYNTHESIS_BLOCK_SIZE):
			if Time.get_ticks_usec() >= _synthesis_deadline:
				# Spread PCM synthesis across frames on single-threaded Web exports.
				await get_tree().process_frame
				_synthesis_deadline = Time.get_ticks_usec() + SYNTHESIS_BUDGET_US
			var end: int = mini(block + SYNTHESIS_BLOCK_SIZE, render_len)
			for sample: int in range(block, end):
				var env: float = 1.0
				if float(sample) < attack_samples:
					env = float(sample) / attack_samples
				elif sample >= length:
					env = maxf(0.0, 1.0 - float(sample - length) / float(maxi(1, tail_len)))
				else:
					var dist_end: float = float(render_len - 1 - sample)
					if dist_end < release_samples:
						env = dist_end / release_samples
				var decay: float = 1.0 - (0.36 if timbre == &"strings" else 0.56) * float(sample) / float(render_len)
				var lead_val: float = _sample_wave(lead_table, float(sample) * lead_step) if lead_gain > 0.0 else 0.0
				var bass_val: float = _sample_wave(_pad_wave, float(sample) * bass_step) if bass_gain > 0.0 else 0.0
				var dest: int = (offset + sample) % total_samples if loop else mini(total_samples - 1, offset + sample)
				mix_buf[dest] += (lead_val * lead_gain + bass_val * bass_gain) * env * decay
		offset += length

	if loop and total_samples > 0:
		var delay_samples: int = mini(total_samples - 1, roundi(0.16 * SAMPLE_RATE))
		var echoed: PackedFloat32Array = PackedFloat32Array()
		echoed.resize(total_samples)
		for idx: int in range(total_samples):
			var tap: int = (idx - delay_samples + total_samples) % total_samples
			echoed[idx] = mix_buf[idx] + mix_buf[tap] * 0.18
		mix_buf = echoed

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
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = total_samples
	return stream


func _note_step(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0) / SAMPLE_RATE if note != 0 else 0.0
