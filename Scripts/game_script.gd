extends Node
const GameState = preload("res://Scripts/game_state.gd")


@export var computer_mode: bool
@export var goals_disabled: bool

# States in the game state machine
#enum GameState {
	#READY,
	#PLAY,
	#WIN
#}


# Current state of the game
var current_state = GameState.READY

# Player scores
var player1_score = 0
var player2_score = 0

# UI elements (assuming these will be assigned in the inspector)
@onready var main_label = $Display/Main
@onready var player1_score_label = $Display/ScoreP1
@onready var player2_score_label = $Display/ScoreP2

var title_velocity = Vector2(200,200)

@onready var p1 = $Mallet_P1
@onready var p2 = $Mallet_P2

var paused_control_player
var dev_console_active = false

func _ready():
	if(goals_disabled):
		set_goals_enabled(false)
	# Initialize the game in TITLE state
	change_state(GameState.TITLE)
	
	# Connect to the signal that triggers the start of play
	SignalBus.start_play.connect(_on_start_play)
	
	SignalBus.pause.connect(on_pause_pressed)
	
	# Connect to the signal that indicates a score
	SignalBus.score_updated.connect(_on_score_updated)

func _process(delta: float) -> void:
	if(Input.is_action_just_pressed("dev_console")):
		if(!$UI/DevConsole.active):
			$UI/DevConsole.visible = true
			$UI/DevConsole.set_active(true)
			dev_console_active = true
		else:
			$UI/DevConsole.visible = false
			$UI/DevConsole.set_active(false)
			dev_console_active = false
	
	match current_state:
		GameState.TITLE:
			var collision_info = $TitleRigidBody.move_and_collide(title_velocity * delta)
			if collision_info:
				title_velocity = title_velocity.bounce(collision_info.get_normal())
			if(Input.is_action_just_pressed("ready_p1")):
				change_state(GameState.READY)
				$TitleRigidBody.visible = false
			
				
func change_state(new_state):
	current_state = new_state
	
	player1_score_label.text = str(player1_score)
	player2_score_label.text = str(player2_score)
	match current_state:
		GameState.TITLE:
			pass
		GameState.READY:
			
			# Lock player input
			lock_player_input()
			
			# Reset player positions and zero input
			p1.position = Vector2(170,540)
			p1.current_move_speed = 0
			p2.position = Vector2(1750,540)
			p2.current_move_speed = 0
			
			p1.reset_player()
			p2.reset_player()
			
			# Display READY text
			main_label.text = "READY"
			main_label.visible = true
			
			# Timer to hide GO text
			var timer = get_tree().create_timer(1.0)
			await timer.timeout

		GameState.PLAY:
			# Unlock player input
			unlock_player_input()

			# Show GO text briefly
			main_label.text = "GO!"
			main_label.visible = true
			
			# Timer to hide GO text
			var timer = get_tree().create_timer(1.0)
			await timer.timeout # TODO: Be able to cancel this timer if needed
			main_label.visible = false
			
		GameState.WIN:
			# Lock player input
			lock_player_input()
			
			# Determine winner and display
			var winner_text = "Player 1 Wins!" if player1_score >= 7 else "Player 2 Wins!"
			main_label.text = winner_text
			main_label.visible = true

# Signal handlers
func _on_start_play():
	if current_state == GameState.READY:
		change_state(GameState.PLAY)
	if current_state == GameState.WIN:
		# Reset scores and change to READY state
		reset_game()

#currently just restarts game
func on_pause_pressed(player_id):
	paused_control_player = player_id
	get_tree().reload_current_scene()
	
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
	
func set_goals_enabled(state):
	$Table/Goal1/CollisionShape2D.disabled = !state
	$Table/Goal2/CollisionShape2D.disabled = !state
