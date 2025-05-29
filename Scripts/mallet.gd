extends Node2D

const MOVE_SPEED_NORMAL = 8
const MOVE_SPEED_POWER = 3
const MAX_POWER_LVL = 5

@export var chevron_scene: PackedScene

@export var min_x: int
@export var max_x: int

@export var player: int

var can_control = true
var move_vertical = Input.get_joy_axis(0,JOY_AXIS_LEFT_X)
var move_horizontal = Input.get_joy_axis(0,JOY_AXIS_LEFT_Y)

var current_move_speed = 8

var power_is_held
var power_lvl = 0
var spin

var kb_input = true

var current_input_map
#currently arrays, should be dicts, so we can just reference input by name
var input_map_p1 = ["move_left","move_right","move_forward","move_back","power","block"]
var input_map_p2 = ["move_right_p2","move_left_p2","move_back_p2","move_forward_p2","power_p2","block_p2"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(player == 0):
		current_input_map = input_map_p1
	elif(player == 1):
		current_input_map = input_map_p2
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	print(event.device)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(!can_control):
		return
		
	move_vertical = Input.get_joy_axis(0,JOY_AXIS_LEFT_X)
	move_horizontal = Input.get_joy_axis(0,JOY_AXIS_LEFT_Y)
	if(kb_input):
		move_vertical = Input.get_axis(current_input_map[0],current_input_map[1])
		move_horizontal = Input.get_axis(current_input_map[2],current_input_map[3])
	
	power_is_held = Input.is_action_pressed(current_input_map[4])
	if(power_is_held):
		current_move_speed = MOVE_SPEED_POWER
	else:
		current_move_speed = MOVE_SPEED_NORMAL
		
	if(Input.is_action_just_pressed(current_input_map[4])):
		$PowerTimer.start()
	
	if(Input.is_action_just_released(current_input_map[4])):
		if power_lvl > 0:
			can_control = false
			$CooldownTimer.wait_time = .3
			$CooldownTimer.start()
			current_move_speed = 8 + 3 * power_lvl
			for chev in $Chevrons.get_children():
				chev.queue_free()
		$PowerTimer.stop()
		power_lvl = 0
		
	#print("x: ", move_vertical)
	#print("y: ", move_horizontal)
	
func _physics_process(delta: float) -> void:
	var move_amt = Vector2(move_horizontal * -1, move_vertical) * current_move_speed
	var oob = outside_move_boundaries(move_amt)
	if(!oob):
		#actually move if not out of bounds
		global_position += Vector2(move_horizontal * -1, move_vertical) * current_move_speed

	var move_vector = Vector2(move_horizontal * -1, move_vertical)
	#var angle = move_vector.angle_to(Vector2(1,0))
	var angle = rad_to_deg(move_vector.angle())
	if(move_vector == Vector2(0,0)):
		angle = 0.0
	#print(angle)
	$Chevrons.rotation_degrees = angle

func outside_move_boundaries(move_amount):
	if((global_position + move_amount).x > max_x ||
	(global_position + move_amount).x < min_x ||
	(global_position + move_amount).y < 0 ||
	(global_position + move_amount).y > 1080):
		return true
		
func _on_power_timer_timeout() -> void:
	if(power_lvl < MAX_POWER_LVL):
		var chev = chevron_scene.instantiate()
		$Chevrons.add_child(chev)
		chev.offset.x = 80 + (40 * power_lvl)
		power_lvl += 1

func _on_cooldown_timer_timeout() -> void:
	can_control = true
	$CooldownTimer.stop()
