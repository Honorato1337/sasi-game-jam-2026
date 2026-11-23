extends Node

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
}

signal state_changed(new_state: GameState)
signal score_changed(new_score: int)

var current_state: GameState = GameState.MENU
var score: int = 0


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


func reset_game() -> void:
	set_state(GameState.MENU)

	if score == 0:
		return

	score = 0
	score_changed.emit(score)
