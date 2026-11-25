extends Node

const Arena = preload("res://scenes/levels/arena.gd")
const Enemy = preload("res://scenes/enemies/enemy_base.gd")
const Player = preload("res://scenes/player/player.gd")
const Station = preload("res://scenes/objects/care_station.gd")
const Screens = preload("res://scenes/ui/title_end_screens.gd")
const StoryDialog = preload("res://scenes/ui/story_dialog.gd")
const CutscenePlayer = preload("res://scenes/ui/cutscene_player.gd")

var _failures: int
var _attacks: int
var _headless: bool = DisplayServer.get_name() == "headless"
@onready var _arena: Arena = $Arena
@onready var _player: Player = $Arena/Player
@onready var _screens: Screens = $Arena/TitleEndScreens
@onready var _story: StoryDialog = $Arena/StoryDialog
@onready var _cutscene: CutscenePlayer = $Arena/CutscenePlayer


func _ready() -> void:
	_player.attacked.connect(_on_attack)
	get_tree().create_timer(85.0).timeout.connect(_on_timeout)
	_run.call_deferred()


func _on_timeout() -> void:
	_check(false, "Tempo limite da validação")
	print("T-018: %d falha(s)." % _failures)
	get_tree().quit(1)


func _run() -> void:
	# A síntese procedural é distribuída entre frames no desktop e na Web.
	var deadline: int = Time.get_ticks_msec() + 25000
	while AudioManager._music.size() < 8 and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(AudioManager._music.size() == 8, "Trilhas procedurais carregadas")
	await _check_menu()
	await _check_intro_cutscene()
	await _check_morning()
	await _check_afternoon()
	await _check_cycle_progression()
	await _check_night()
	await _check_endings()
	AudioManager.stop_music()
	AudioManager.music_player.stream = null
	for audio_player: AudioStreamPlayer in AudioManager.sfx_players:
		audio_player.stop()
		audio_player.stream = null
	await _wait(0.3)
	print("T-018 (%s): %d falha(s)." % ["headless" if _headless else "desktop", _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _check_menu() -> void:
	await _wait(0.10)
	_check(GameManager.current_state == GameManager.GameState.MENU and _screens.visible, "Menu inicial")
	_check(_screens._logo_rect != null and _screens._logo_rect.visible, "Logo 32-bit visível no menu inicial")
	if not _headless:
		_check(get_window().size == Vector2i(1280, 720), "Janela desktop 1280×720")
	await _capture("menu")
	_activate(_screens._title_window, "COMO JOGAR")
	_check(_screens._help_window.visible, "Abre instruções")
	await _capture("instrucoes")
	await _tap(KEY_ESCAPE)
	_activate(_screens._title_window, "CRÉDITOS & SAÚDE")
	_check(_screens._credits_window.visible, "Abre créditos")
	await _tap(KEY_ESCAPE)
	_activate(_screens._title_window, "CONFIGURAÇÕES")
	_check(_screens._settings_window.visible, "Abre configurações")
	var buttons: Array = _screens._buttons[_screens._settings_window]
	buttons[0].pressed.emit()
	buttons[2].pressed.emit()
	_check(is_equal_approx(AudioManager.music_volume, 0.9) and is_equal_approx(AudioManager.sfx_volume, 0.9)
			and is_equal_approx(_screens._music_slider.value, 90.0)
			and is_equal_approx(_screens._sfx_slider.value, 90.0),
			"Ajusta volumes")
	await _capture("config")
	_screens._mute_button.pressed.emit()
	_check(AudioManager.muted and AudioManager.music_player.volume_db == -80.0, "Ativa mudo")
	_screens._mute_button.pressed.emit()
	_screens._shake_button.pressed.emit()
	_check(not GameManager.screen_shake_enabled, "Desativa tremor")
	_arena._start_shake(3.0, 0.20)
	_check(_arena._shake_remaining == 0.0, "Tremor respeita configuração")
	_screens._shake_button.pressed.emit()
	if _headless:
		_check(_screens._fullscreen_button.disabled, "Tela cheia desabilitada em headless")
	else:
		_screens._fullscreen_button.pressed.emit()
		await _wait(0.15)
		_check(_screens._is_fullscreen(), "Tela cheia desktop")
		_screens._fullscreen_button.pressed.emit()
		await _wait(0.15)
		_check(not _screens._is_fullscreen() and get_window().size == Vector2i(1280, 720), "Restaura janela 1280×720")
	await _tap(KEY_ESCAPE)
	_check(_screens._title_window.visible and _button(_screens._title_window, "SAIR") != null, "Volta ao menu com Sair")
	_button(_screens._title_window, "JOGAR").grab_focus()
	await _tap(KEY_ENTER)


func _check_intro_cutscene() -> void:
	await _wait(0.08)
	_check(GameManager.current_state == GameManager.GameState.CUTSCENE
			and _cutscene.get_phase_name() == "MONTAGE", "Cutscene de abertura inicia na montagem")
	_check(AudioManager.music_player.stream == AudioManager._music.get(&"beethoven"),
			"Trilha estilo Beethoven toca na montagem")
	await _wait(1.32)
	_check(_cutscene._scene_idx >= 1, "Montagem avança em sincronia com a música")
	await _capture("cutscene-rotina")
	await _tap(KEY_SPACE)
	await _wait(0.06)
	_check(_cutscene.get_phase_name() == "INTRO_POEM" and AudioManager.music_player.playing
			and AudioManager.music_player.stream == AudioManager._music.get(&"poem"),
			"Poema Cansaço em fundo preto com música")
	await _wait(0.90)
	_check(_cutscene._poem_reveal_count <= 2, "Poema Cansaço revela versos devagar")
	await _tap(KEY_SPACE)
	await _wait(0.06)
	await _capture("cutscene-poema")
	await _tap(KEY_SPACE)
	await _wait(0.06)
	_check(_cutscene.get_phase_name() == "CONSOLE_ENTRY", "Transição para cena do videogame")
	await _tap(KEY_SPACE)
	await _wait(0.06)
	await _tap(KEY_SPACE)
	await _wait(0.45)
	await _capture("cutscene-console")
	await _tap(KEY_ESCAPE)
	await _wait(0.08)
	_check(_cutscene.get_phase_name() == "NONE" and _attacks == 0, "Cutscene encerra entrando no jogo sem atacar")


func _check_morning() -> void:
	_check_room(1, "room_1_morning", 4, 7)
	_check(_arena._decor_obstacles.get_child_count() >= 6, "Pilastras e obstáculos presentes na Manhã")
	_check(_arena._camera.limit_right == 960 and _arena._camera.limit_bottom == 540, "Câmera cobre mapa 960×540")
	_check(GameManager.body == 35.0 and GameManager.get_attack_range() == 26.0
			and GameManager.get_attack_damage() == 16 and GameManager.get_move_speed_multiplier() == 0.75,
			"Sinal de Corpo na Manhã")
	var sfx_index: int = AudioManager._next_sfx_player_index
	await _wait(0.3)
	_check(AudioManager._next_sfx_player_index != sfx_index, "Typewriter toca blips de voz")
	_check(_story._atlas.atlas == StoryDialog.PORTRAITS, "Diálogo exibe retrato 48×48 expressivo")
	_check(_story._text.visible_characters > 0 and _story._text.visible_characters < _story._text.text.length(),
			"Efeito typewriter")
	await _tap(KEY_SPACE)
	_check(_story._text.visible_characters == _story._text.text.length() and _story._index == 0,
			"Espaço completa a fala")
	await _click()
	_check(_story._index == 1, "Clique avança a fala")
	await _tap(KEY_ENTER)
	await _tap(KEY_ENTER)
	_check(_story._index == 2, "Enter avança a fala")
	await _capture("manha")
	await _tap(KEY_SPACE)
	await _tap(KEY_SPACE)
	_check(GameManager.current_state == GameManager.GameState.PLAYING and _attacks == 0,
			"Final do diálogo consome Espaço sem atacar")
	_check(AudioManager.music_player.stream == AudioManager._music.get(&"morning"), "Trilha da Manhã")
	await _tap(KEY_P)
	_check(GameManager.current_state == GameManager.GameState.PAUSED and _screens._pause_window.visible,
			"P pausa a partida")
	await _tap(KEY_ESCAPE)
	_check(GameManager.current_state == GameManager.GameState.PLAYING, "Esc retoma a partida")
	_player.position = _arena._door.position + Vector2(0, 18)
	await _wait(0.08)
	_check(GameManager.room == 1 and not _arena._door_open, "Porta da Manhã trancada com inimigos")
	var water: Station = _find_station(Station.StationType.WATER_SNACK)
	_player.position = water.position + Vector2(0, 18)
	await _tap(KEY_E)
	_check(GameManager.body > 79.0 and GameManager.get_attack_damage() == 26, "Água pelo E recupera Corpo")
	var target: Enemy = _first_enemy()
	_check(is_equal_approx(target._fog_amount, 1.0), "Inimigos no Ciclo 1 iniciam 100% pretos")
	target.position = _player.position + Vector2(21, 0)
	_player.facing_direction = Vector2.RIGHT
	var hp_before: int = target.hp
	await _tap(KEY_SPACE)
	_check(is_instance_valid(target) and target.hp == hp_before - 26
			and _arena._hitstop > 0.0 and not _player.is_physics_processing(),
			"Espada causa 26 de dano e aplica hitstop")
	await _wait(0.10)
	_check(_player.is_physics_processing(), "Hitstop libera o controle")
	await _clear_combat()
	GameManager.modify_body(-100.0)
	await _wait(0.08)
	_check(not _arena._door_open and _arena._remaining == 0, "Manhã limpa exige Corpo ≥ 50")
	var score: int = GameManager.score
	var drop: Vector2 = _arena._drops[0].position
	_player.position = drop + Vector2(25, 0)
	await _wait(0.3)
	_check(GameManager.body > 12 and GameManager.score >= score + 25, "Gota magnética recupera Corpo e soma score")
	GameManager.modify_body(100.0)
	await _walk_through_door(2)


func _check_afternoon() -> void:
	_check_room(2, "room_2_afternoon", 4, 8)
	_check(_arena._stations.get_child_count() == 4, "Água, colega e duas bancadas físicas")
	await _tap(KEY_ESCAPE)
	_check(GameManager.current_state == GameManager.GameState.PLAYING, "Esc pula sem pausar")
	var colleague: Station = _find_station(Station.StationType.CLASSMATE_NPC)
	_player.position = colleague.position + Vector2(0, 17)
	await _tap(KEY_E)
	_check(GameManager.ally_active and _story.active_sequence == "classmate_help"
			and is_instance_valid(_arena._ally), "E recruta aliado e abre diálogo")
	await _capture("colega")
	await _tap(KEY_ESCAPE)
	await _wait(0.08)
	_check(AudioManager.music_player.stream == AudioManager._music.get(&"nocturne"), "Trilha da Tarde")
	GameManager.modify_mind(-60.0)
	_check(GameManager.mind_state == GameManager.MindState.ANXIOUS
			and is_equal_approx(AudioManager.music_player.pitch_scale, 1.06)
			and is_equal_approx(_arena._hud._vignette.get_shader_parameter(&"strength"), 0.28),
			"Ansiedade muda vinheta e pitch")
	await _wait(0.08)
	_check(_heartbeat_playing(), "Heartbeat durante ansiedade")
	GameManager.modify_mind(-25.0)
	_check(GameManager.mind_state == GameManager.MindState.OVERLOAD
			and is_equal_approx(_arena._hud._vignette.get_shader_parameter(&"strength"), 0.58),
			"Sobrecarga intensifica vinheta")
	await _wait(0.08)
	_check(absf(AudioManager.music_player.pitch_scale - 1.12) <= 0.009, "Pitch estável em sobrecarga")
	GameManager.spend_rest(100.0)
	_check(GameManager.is_exhausted and is_equal_approx(AudioManager.music_player.pitch_scale, 0.90),
			"Exaustão tem prioridade no pitch")
	GameManager.complete_breathing()
	await _clear_combat()
	GameManager.modify_mind(-100.0)
	await _wait(0.08)
	_check(not _arena._door_open and _arena._remaining == 0, "Tarde limpa ainda exige Mente ≥ 45")
	GameManager.modify_mind(100.0)
	GameManager.modify_body(-100.0)
	await _wait(0.08)
	_check(not _arena._door_open, "Tarde também exige Corpo ≥ 45")
	GameManager.modify_body(100.0)
	await _walk_through_door(3)


func _check_cycle_progression() -> void:
	# Sala 3 (Noite Ciclo 1) -> Sala de Respiro 1 -> Sala 4
	_check_room(3, "room_3_night", 4, 9)
	_check(AudioManager.music_player.stream == AudioManager._music.get(&"night"), "Trilha da Noite C1")
	await _tap(KEY_ESCAPE)
	await _clear_combat()
	GameManager.spend_rest(100.0)
	await _wait(0.08)
	_check(not _arena._door_open, "Noite exige Descanso >= 45")
	GameManager.complete_breathing()
	GameManager.modify_rest(100.0)
	GameManager.modify_mind(100.0)
	GameManager.modify_body(100.0)
	await _walk_through_door(4, true)
	_check(GameManager.in_respite_room and _arena._enemy_container.get_child_count() == 0
			and _story.active_sequence == "respite_1" and not _arena._door_open
			and AudioManager.music_player.stream == AudioManager._music.get(&"poem"),
			"Respiro 1 inicia calmo com música suave")
	await _tap(KEY_ESCAPE)
	await _wait(0.08)
	await _capture("respiro-1")
	var nutrition_altar: Station = _find_habit_altar("nutrition")
	_check(nutrition_altar != null, "Pedestal Nutrição presente no Respiro 1")
	_player.position = nutrition_altar.position + Vector2(0, 20)
	await _tap(KEY_E)
	await _wait(0.08)
	_check(GameManager.max_hp == 125 and GameManager.nutrition_rank == 1 and _arena._door_open,
			"Pedestal no Respiro aplica Hábito 2 e destranca Porta Norte")
	await _walk_through_door(4)

	# Sala 4 (Manhã Ciclo 2)
	_check_room(4, "room_4_c2_morning", 4, 9)
	await _tap(KEY_ESCAPE)
	await _wait(0.08)
	var water_c2: Station = _find_station(Station.StationType.WATER_SNACK)
	_check(water_c2 != null and water_c2.locked_by_wave, "Estações da Sala 4 iniciam seladas na 1ª leva")
	_check(is_equal_approx(_first_enemy()._fog_amount, 0.50), "Ciclo 2 revela parcialmente o jogador nos inimigos")
	await _capture("ciclo2-manha")
	await _clear_combat()
	_check(water_c2 != null and not water_c2.locked_by_wave, "Estações liberam após a 1ª leva")
	GameManager.modify_body(100.0)
	await _walk_through_door(5)

	# Sala 5 (Turno de Sobrevivência 28s - Tarde Ciclo 2)
	_check_room(5, "room_5_c2_afternoon", 4, 4)
	_check(_arena._is_survival_room and is_equal_approx(_arena._survival_remaining, 28.0)
			and _arena._hud.is_survival_hud_visible(), "Sala 5 inicia Turno de Sobrevivência de 28s")
	await _tap(KEY_ESCAPE)
	await _wait(0.08)
	await _capture("sobrevivencia-c2")
	_first_enemy().take_damage(1000)
	await _wait(0.06)
	_check(not _arena._door_open, "Porta na Sala 5 não abre antes de encerrar os 28s")
	_arena._survival_remaining = 0.06
	await _wait(0.14)
	_check(_arena._survival_finished and _arena._enemy_container.get_child_count() == 0
			and not _arena._hud.is_survival_hud_visible(),
			"Sinal de fim do turno dissipa sombras e oculta timer")
	GameManager.modify_body(100.0)
	GameManager.modify_mind(100.0)
	await _walk_through_door(6)

	# Sala 6 (Noite Ciclo 2) -> Sala de Respiro 2 -> Sala 7
	_check_room(6, "room_6_c2_night", 5, 11)
	await _tap(KEY_ESCAPE)
	await _clear_combat()
	GameManager.modify_body(100.0)
	GameManager.modify_mind(100.0)
	GameManager.modify_rest(100.0)
	await _walk_through_door(7, true)
	_check(GameManager.in_respite_room and _story.active_sequence == "respite_2"
			and AudioManager.music_player.stream == AudioManager._music.get(&"hope"),
			"Respiro 2 inicia com música de esperança")
	await _tap(KEY_ESCAPE)
	await _wait(0.08)
	var sleep_altar: Station = _find_habit_altar("sleep")
	_check(sleep_altar != null, "Pedestal Sono presente no Respiro 2")
	_player.position = sleep_altar.position + Vector2(0, 20)
	await _tap(KEY_E)
	await _wait(0.08)
	_check(GameManager.sleep_rank == 1 and _arena._door_open, "Hábito 1 no Respiro 2 destranca Sala 7")
	await _walk_through_door(7)

	# Sala 7 (Manhã Ciclo 3) e Sala 8 (Turno de Sobrevivência 28s Ciclo 3)
	_check_room(7, "room_7_c3_morning", 5, 11)
	await _tap(KEY_ESCAPE)
	await _wait(0.08)
	_check(is_equal_approx(_first_enemy()._fog_amount, 0.08), "Ciclo 3 quase dissipa névoa revelando o próprio rosto")
	await _capture("ciclo3-manha")
	await _clear_combat()
	GameManager.modify_body(100.0)
	await _walk_through_door(8)

	_check_room(8, "room_8_c3_afternoon", 5, 5)
	_check(_arena._is_survival_room and _arena._hud.is_survival_hud_visible(),
			"Sala 8 inicia Turno de Sobrevivência 28s do Ciclo 3")
	await _tap(KEY_ESCAPE)
	_arena._survival_remaining = 0.06
	await _wait(0.14)
	_check(_arena._survival_finished and _arena._enemy_container.get_child_count() == 0,
			"Sala 8 dissipa sombras ao fim do turno")
	GameManager.modify_body(100.0)
	GameManager.modify_mind(100.0)
	await _walk_through_door(9)


func _check_night() -> void:
	_check_room(9, "room_9_c3_night", 1, 1)
	_check(_arena._stations.get_child_count() == 6 and GameManager.ally_active,
			"Três pilares físicos e apoio persistente")
	_check(is_equal_approx(AudioManager.music_player.pitch_scale, 1.0) and not _heartbeat_playing(),
			"Diálogo mantém áudio suave sem heartbeat")
	await _tap(KEY_ESCAPE)
	_check(AudioManager.music_player.stream == AudioManager._music.get(&"boss"), "Trilha do Boss Final")
	var boss: Enemy = _arena._boss
	_check(boss.hp == 380 and is_equal_approx(boss._fog_amount, 0.0) and not boss.is_phase_two(),
			"Boss final inicia nítido na fase 1")
	var pillar: Station = _find_station(Station.StationType.ROOM_PILLAR, "CORPO")
	GameManager.modify_body(-100.0)
	_player.position = pillar.position + Vector2(0, 18)
	await _tap(KEY_E)
	_check(GameManager.body >= 41.0, "E reacende o pilar Corpo")
	_player.position = Vector2(480, 390)
	boss._attack_elapsed = boss._attack_interval() - 0.01
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(get_tree().get_nodes_in_group(&"stress_projectiles").size() == 3, "Fase 1 dispara três projéteis")
	boss.take_damage(210)
	_check(boss.is_phase_two(), "Boss entra na fase 2 com vida abaixo da metade")
	boss._next_pillar = 1
	boss._drain_elapsed = 5.99
	var previous_mind: float = GameManager.mind
	boss._attack_elapsed = boss._attack_interval() - 0.01
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(get_tree().get_nodes_in_group(&"stress_projectiles").size() >= 8
			and GameManager.mind < previous_mind - 14.0, "Fase 2 aumenta leque e drena Mente")
	await _wait(0.14)
	await _capture("noite")
	for projectile: Node in get_tree().get_nodes_in_group(&"stress_projectiles"):
		projectile.queue_free()
	GameManager.consume_clarity_strike()
	_key(KEY_R, true)
	await _wait(1.45)
	_key(KEY_R, false)
	_check(GameManager.clarity_ready, "Segurar R carrega Golpe de Clareza")
	_player.position = boss.position + Vector2(0, 52)
	_player.facing_direction = Vector2.UP
	boss._spawn_projectile(Vector2.DOWN)
	await _tap(KEY_SPACE)
	_check(boss.hp == 50 and not GameManager.clarity_ready and _arena._hitstop > 0.0,
			"Clareza causa 120 de dano no Boss com hitstop")
	await _wait(0.14)
	_check(get_tree().get_nodes_in_group(&"stress_projectiles").is_empty(), "Clareza corta projétil de estresse")
	boss.take_damage(50)
	await _wait(0.06)
	_check(_story.active_sequence == "victory" and GameManager.hp > 0, "Vitória começa pelo diálogo")


func _check_endings() -> void:
	await _tap(KEY_ESCAPE)
	await _wait(0.08)
	_check(GameManager.current_state == GameManager.GameState.CUTSCENE
			and _cutscene.get_phase_name() == "CONSOLE_EXIT", "Vitória inicia saída da TV")
	await _wait(0.65)
	await _capture("cutscene-saida-tv")
	await _tap(KEY_SPACE)
	await _wait(0.08)
	_check(_cutscene.get_phase_name() == "CONSOLE_EXIT" and _cutscene._console_step == 1
			and AudioManager.music_player.stream == AudioManager._music.get(&"morning"),
			"Reflexão no quarto após sair da TV")
	await _capture("cutscene-reflexao")
	await _tap(KEY_SPACE)
	await _wait(0.06)
	await _tap(KEY_SPACE)
	await _wait(0.08)
	_check(_cutscene.get_phase_name() == "HAPPY_MONTAGE"
			and _cutscene._montage_fatigue_lbl.text == "FELIZ E EM PAZ",
			"Retorno à rotina feliz antes do poema final")
	await _wait(1.36)
	_check(_cutscene._scene_idx >= 1, "Rotina feliz avança cenas normalmente")
	await _capture("cutscene-rotina-feliz")
	await _tap(KEY_SPACE)
	await _wait(0.08)
	_check(GameManager.current_state == GameManager.GameState.CUTSCENE
			and _cutscene.get_phase_name() == "ENDING_POEM"
			and AudioManager.music_player.stream == AudioManager._music.get(&"hope"),
			"Poema final de Emily Dickinson com trilha serena")
	await _tap(KEY_SPACE)
	await _wait(0.06)
	await _capture("poema-final")
	await _tap(KEY_SPACE)
	await _wait(0.08)
	_check(GameManager.current_state == GameManager.GameState.VICTORY and _screens._end_window.visible
			and _screens._end_heading.text == "O AMANHECER CHEGOU"
			and _screens._stats.text.begins_with("Ciclo 3/3 (Noite)"), "Resumo de vitória após poema")
	await _capture("vitoria")
	await _tap(KEY_ENTER)
	_check_room(1, "room_1_morning", 4, 7)
	_check(GameManager.hp == 100 and GameManager.score == 0 and not GameManager.ally_active, "Reinício limpa partida")
	await _tap(KEY_ESCAPE)
	GameManager.damage_player(100)
	_check(GameManager.current_state == GameManager.GameState.GAME_OVER and _screens._end_window.visible
			and _screens._end_heading.text == "O BURNOUT PEDIU PAUSA", "Derrota por HP zero")
	await _capture("derrota")


func _check_room(room: int, sequence: String, active: int, total: int) -> void:
	_check(GameManager.room == room and GameManager.current_state == GameManager.GameState.DIALOGUE
			and _story.active_sequence == sequence, "Sala %d e sequência %s" % [room, sequence])
	_check(_arena._courtyard.texture == Arena.ROOM_ART[room - 1]
			and _arena._enemy_container.get_child_count() == active and _arena._remaining == total,
			"Cenário e inimigos da Sala %d" % room)


func _clear_combat() -> void:
	# A espada real é testada acima. Elimina os demais pelo ponto de entrada de dano
	# para validar as duas levas e os bloqueios da porta de forma determinística.
	for wave: int in range(2):
		for node: Node in _arena._enemy_container.get_children():
			var enemy: Enemy = node as Enemy
			if enemy != null:
				enemy.take_damage(1000)
		await _wait(0.12)


func _walk_through_door(next_room: int, expect_respite: bool = false) -> void:
	_player.position = _arena._door.position + Vector2(0, 50)
	await _wait(0.06)
	_check(_arena._door_open and _arena._door_sign.text == "AVANÇAR ↑", "Porta abre após cumprir objetivos")
	await _capture("porta-%s%d" % ["respiro-" if GameManager.in_respite_room else "", GameManager.room])
	_key(KEY_W, true)
	await _wait(0.45)
	_key(KEY_W, false)
	if expect_respite:
		_check(GameManager.in_respite_room and GameManager.current_state == GameManager.GameState.DIALOGUE,
				"Entra na Sala de Respiro antes da Sala %d" % next_room)
	else:
		_check(not GameManager.in_respite_room and GameManager.room == next_room,
				"Cruza a Porta Norte andando até a Sala %d" % next_room)


func _find_habit_altar(habit: String) -> Station:
	for node: Node in _arena._stations.get_children():
		var station: Station = node as Station
		if station != null and station.station_type == Station.StationType.HABIT_ALTAR and station.habit_key == habit:
			return station
	return null


func _find_station(type: Station.StationType, pillar: String = "CORPO") -> Station:
	for node: Node in _arena._stations.get_children():
		var station: Station = node as Station
		if station != null and station.station_type == type and station.pillar_name == pillar:
			return station
	return null


func _first_enemy() -> Enemy:
	for node: Node in _arena._enemy_container.get_children():
		if node is Enemy:
			return node
	return null


func _heartbeat_playing() -> bool:
	var stream: AudioStreamWAV = AudioManager._effects.get(&"heartbeat")
	for player: AudioStreamPlayer in AudioManager.sfx_players:
		if stream != null and player.stream == stream and player.playing:
			return true
	return false


func _button(panel: Panel, caption: String) -> Button:
	for button: Button in _screens._buttons[panel]:
		if button.text == caption:
			return button
	return null


func _activate(panel: Panel, caption: String) -> void:
	_button(panel, caption).pressed.emit()


func _on_attack(_clarity: bool, _origin: Vector2, _direction: Vector2, _reach: float, _damage: int) -> void:
	_attacks += 1


func _key(code: Key, pressed: bool) -> void:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = code
	key.physical_keycode = code
	key.pressed = pressed
	Input.parse_input_event(key)
	Input.flush_buffered_events()


func _tap(code: Key) -> void:
	_key(code, true)
	await get_tree().create_timer(0.0, true, true).timeout
	_key(code, false)
	await get_tree().create_timer(0.0, true, true).timeout


func _click() -> void:
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	Input.flush_buffered_events()
	click = click.duplicate() as InputEventMouseButton
	click.pressed = false
	Input.parse_input_event(click)
	await get_tree().create_timer(0.0, true, true).timeout


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _capture(label: String) -> void:
	if _headless or "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var result: Error = get_viewport().get_texture().get_image().save_png("res://.godot/t018-%s.png" % label)
	_check(result == OK, "Captura desktop " + label)


func _check(ok: bool, description: String) -> void:
	if not ok:
		_failures += 1
		push_error("T-018: " + description)
