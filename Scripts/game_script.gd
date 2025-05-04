extends Node

# States in the game state machine
enum GameState {
	READY,
	PLAY,
	WIN
}

# Current state of the game
var current_state = GameState.READY

# Player scores
var player1_score = 0
var player2_score = 0

# UI elements (assuming these will be assigned in the inspector)
@onready var display_label = $Display

func _ready():
	# Initialize the game in READY state
	change_state(GameState.READY)
	
	# Connect to the signal that triggers the start of play
	SignalBus.start_play.connect(_on_start_play)
	
	# Connect to the signal that indicates a score
	SignalBus.score_updated.connect(_on_score_updated)

func change_state(new_state):
	current_state = new_state
	
	match current_state:
		GameState.READY:
			# Lock player input
			lock_player_input()
			
			# Display READY text
			display_label.text = "READY"
			display_label.visible = true
			
		GameState.PLAY:
			# Unlock player input
			unlock_player_input()

			# Show GO text briefly
			display_label.text = "GO!"
			display_label.visible = true
			
			# Timer to hide GO text
			var timer = get_tree().create_timer(1.0)
			await timer.timeout
			display_label.visible = false
			
		GameState.WIN:
			# Lock player input
			lock_player_input()
			
			# Determine winner and display
			var winner_text = "Player 1 Wins!" if player1_score >= 7 else "Player 2 Wins!"
			display_label.text = winner_text
			display_label.visible = true

# Signal handlers
func _on_start_play():
	if current_state == GameState.READY:
		change_state(GameState.PLAY)

func _on_score_updated(player_id):
	if current_state == GameState.PLAY:
		# Update score for the player who scored
		if player_id == 1:
			player1_score += 1
		else:
			player2_score += 1
			
		# Check if someone won
		if player1_score >= 7 or player2_score >= 7:
			change_state(GameState.WIN)
		else:
			# Reset to READY for next round
			change_state(GameState.READY)

# Helper functions to lock/unlock player input
func lock_player_input():
	SignalBus.emit_lock_player(true)

func unlock_player_input():
	SignalBus.emit_lock_player(false)

# Function to reset the game
func reset_game():
	player1_score = 0
	player2_score = 0
	change_state(GameState.READY)
