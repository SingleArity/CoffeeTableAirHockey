extends Node2D

var move_vertical = Input.get_joy_axis(0,JOY_AXIS_LEFT_X)
var move_horizontal = Input.get_joy_axis(0,JOY_AXIS_LEFT_Y)

var move_speed = 8
var move_speed_powering = 3

var spin

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_vertical = Input.get_joy_axis(0,JOY_AXIS_LEFT_X)
	move_horizontal = Input.get_joy_axis(0,JOY_AXIS_LEFT_Y)
	var move_x_kb = Input.get_axis("move_left","move_right")
	var move_y_kb = Input.get_axis("move_down","move_up")
	#print("x: ", move_vertical)
	#print("y: ", move_horizontal)
	
func _physics_process(delta: float) -> void:
	global_position += Vector2(move_horizontal * -1, move_vertical) * move_speed
