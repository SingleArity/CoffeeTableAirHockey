extends Node2D

@onready var goal1_region = $Goal1
@onready var goal2_region = $Goal2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect signals to handle goal detection
	goal1_region.connect("body_entered", _on_goal1_body_entered)
	goal2_region.connect("body_entered", _on_goal2_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Check if the space bar is pressed to start the game
	if Input.is_action_just_pressed("ui_accept"):
		# Emit signal to start the game
		print("Starting game...")
		SignalBus.emit_start_play()

# Check if the object is a Puck
func is_puck(body: Node) -> bool:
	# Check if the body is a Puck
	return body.get_parent().name == "Puck"

func _on_goal1_body_entered(body: Node) -> void:
	# Check if the body is the Puck
	if is_puck(body):
		# Emit signal to update score for player 1
		print("Player 1 scored!")
		SignalBus.emit_score_updated(1)

func _on_goal2_body_entered(body: Node) -> void:
	# Check if the body is the Puck
	if is_puck(body):
		# Emit signal to update score for player 2
		print("Player 2 scored!")
		SignalBus.emit_score_updated(2)
