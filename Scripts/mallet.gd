extends Node2D

@onready var game = get_node("/root/Game")

const GameState = preload("res://Scripts/game_state.gd")

const MOVE_SPEED_NORMAL = 8
const MOVE_SPEED_POWER = 3
const MAX_POWER_LVL = 5

@export var chevron_scene: PackedScene
@export var blocker_scene: PackedScene

@export var min_x: int
@export var max_x: int

@export var player: int

var can_control = true
var move_vertical = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
var move_horizontal = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)

var block_active: bool = false
var blocker

var current_move_speed = 8

var power_is_held
var power_pressed_dir: Vector2
var dash_angle_degrees
var power_lvl = 0
var spin_power
const MAX_SPIN_POWER = 30

var kb_input = true

var current_input_map
#currently arrays, should be dicts? so we can just reference input by name
var input_map_p1 = ["move_left","move_right","move_forward","move_back","power","block","spin_p1"]
var input_map_p1_comp_mode = ["move_forward","move_back","move_right","move_left","power","block","spin_p1"]
var input_map_p2 = ["move_right_p2","move_left_p2","move_back_p2","move_forward_p2","power_p2","block_p2","spin_p2"]
var input_map_p2_comp_mode = ["move_forward_p2","move_back_p2","move_right_p2","move_left_p2","power_p2","block_p2","spin_p2"]

var power_times = [.1,.3,.5,.8,1.0,1.2]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.lock_player.connect(_on_lock_player_input)
	spin_power = 0
	#set player-specific vars
	if(player == 0):
		if(game.computer_mode):
			current_input_map = input_map_p1_comp_mode
		else:
			current_input_map = input_map_p1
		power_pressed_dir = Vector2(1,0)
	elif(player == 1):
		if(game.computer_mode):
			current_input_map = input_map_p2_comp_mode
		else:
			current_input_map = input_map_p2
		power_pressed_dir = Vector2(-1,0)
	#set initial dash angle
	dash_angle_degrees = rad_to_deg(power_pressed_dir.angle())

func _input(event: InputEvent) -> void:
	pass
	#print(event.device)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (!can_control):
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
	
	#turn on block
	if(Input.is_action_pressed(current_input_map[5])):
		if(!block_active):
			block_active = true
			blocker = blocker_scene.instantiate()
			add_child(blocker)
	else:
		if(block_active && Input.is_action_just_released(current_input_map[5])):
			block_active = false
			blocker.queue_free()
		
	#just pressed 'power' button
	if(Input.is_action_just_pressed(current_input_map[4])):
		$PowerTimer.wait_time = power_times[power_lvl]
		$PowerTimer.start()
		power_pressed_dir = Vector2(move_horizontal * -1, move_vertical)
		if(power_pressed_dir == Vector2(0,0)):
			if(player == 0):
				power_pressed_dir = Vector2(1,0)
			if(player == 1):
				power_pressed_dir = Vector2(-1,0)
				
	#just released power button
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
	
	#spin pressed, power and block are not
	if(Input.is_action_pressed(current_input_map[6]) &&
		!Input.is_action_pressed(current_input_map[4]) && 
		!Input.is_action_pressed(current_input_map[5])):
		check_apply_spin()
	

func check_apply_spin():
	var left = current_input_map[0]
	var right = current_input_map[1]
	if(player == 1):
		left = current_input_map[1]
		right = current_input_map[0]
	if(game.computer_mode):
		left = current_input_map[3]
		right = current_input_map[2]
	#right
	if(Input.is_action_just_pressed(left)):
		spin_power -= 2
		#cap spin_power
		spin_power = max(spin_power, MAX_SPIN_POWER * -1)
		$SpinDischarge.start(1.0)
	#p1 right
	if(Input.is_action_just_pressed(right)):
		spin_power += 2
		#cap spin_power
		spin_power = min(spin_power,MAX_SPIN_POWER)
		$SpinDischarge.start(1.0)

func adjust_dash_direction(angle):
	var pressed_dir_angle = rad_to_deg(power_pressed_dir.angle())
	if(angle < 0.0):
		pressed_dir_angle += 1
	elif(angle > 0.0):
		pressed_dir_angle -= 1
	power_pressed_dir = Vector2.from_angle(deg_to_rad(pressed_dir_angle))
	return pressed_dir_angle
	
func _physics_process(delta: float) -> void:
	var move_amt = Vector2(move_horizontal * -1, move_vertical) * current_move_speed
	var oob = outside_move_boundaries(move_amt)
	
	#don't process player movement if not in "play" state
	if(game.current_state != GameState.PLAY):
		return
	
	if(spin_power != 0):
		$AnimatedSprite2D.rotation_degrees += spin_power
		
	var move_vector = Vector2(move_horizontal * -1, move_vertical)
	#var angle = move_vector.angle_to(Vector2(1,0))
	
	if(can_control):
		dash_angle_degrees = rad_to_deg(move_vector.angle())
	else:
		#currently dashing
		var angle_from_initial_pow_dir = rad_to_deg(move_vector.angle_to(power_pressed_dir))
		dash_angle_degrees = adjust_dash_direction(angle_from_initial_pow_dir)
		
	#if power button is held down, and we are not yet dashing
	if(Input.is_action_pressed(current_input_map[4]) && can_control):
		var angle_from_initial_pow_dir = rad_to_deg(move_vector.angle_to(power_pressed_dir))
		dash_angle_degrees = adjust_dash_direction(angle_from_initial_pow_dir)

	#print(angle)
	$Chevrons.rotation_degrees = dash_angle_degrees

	if(!oob):
		#actually move if not out of bounds
		if(!can_control):
			#dash movement
			global_position += Vector2.from_angle(deg_to_rad(dash_angle_degrees)) * current_move_speed
			print("angle:", dash_angle_degrees)
			print(Vector2.from_angle(deg_to_rad(dash_angle_degrees)))
		else:
			#regular movement
			global_position += Vector2(move_horizontal * -1, move_vertical) * current_move_speed
		
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
		$PowerTimer.wait_time = power_times[power_lvl]

func _on_cooldown_timer_timeout() -> void:
	can_control = true
	$CooldownTimer.stop()

func _on_lock_player_input(locked: bool) -> void:
	can_control = !locked

func _on_spin_discharge_timeout() -> void:
	#less spin each timeout
	if(spin_power > 0):
		spin_power -= 1
	elif(spin_power < 0):
		spin_power += 1
	#if spin not fully dissipated, continue
	if(spin_power != 0):
		$SpinDischarge.start(1.0)
