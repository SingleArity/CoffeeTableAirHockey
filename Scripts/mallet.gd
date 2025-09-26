extends AnimatableBody2D

@onready var game = get_node("/root/Game")

const GameState = preload("res://Scripts/game_state.gd")
const MalletState = preload("res://Scripts/mallet_state.gd")
#const BlockMode = preload("res://Scripts/block_mode.gd")

var MOVE_SPEED_NORMAL = 8
var MOVE_SPEED_POWER = 3
var MOVE_SPEED_UP = 40
var MAX_POWER_LVL = 5

@export var chevron_scene: PackedScene
@export var blocker_scene: PackedScene

@export var min_x: int
@export var max_x: int

@export var player: int

@export var block_mode: BlockMode.BLOCK_MODE

var state
var can_control = true
var move_vertical = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
var move_horizontal = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
var movement_paused = false

var block_active: bool = false
var blocker

var current_move_speed = 8
var spin_decay = 4

var power_is_held
var power_held_frames = 0

var consecutive_countdown = false
var consecutive_power_taps = 0
var consecutive_power_tap_frames = 20

var power_pressed_dir: Vector2
var dash_angle_degrees
var dash_adjust_speed = 4
var power_lvl = 0
var spin_power
var MAX_SPIN_POWER = 27

var kb_input = true

var current_input_map
#currently arrays, should be dicts? so we can just reference input by name
var input_map_p1 = ["move_left","move_right","move_forward","move_back","power","block","spin_left_p1","spin_right_p1","up_p1"]
var input_map_p1_comp_mode = ["move_forward","move_back","move_right","move_left","power","block","spin_left_p1","spin_right_p1","up_p1"]
var input_map_p2 = ["move_right_p2","move_left_p2","move_back_p2","move_forward_p2","power_p2","block_p2","spin_left_p2","spin_right_p2","up_p2"]
var input_map_p2_comp_mode = ["move_forward_p2","move_back_p2","move_right_p2","move_left_p2","power_p2","block_p2","spin_left_p2","spin_right_p2","up_p2"]

var power_times = [.1,.2,.3,.5,.7,.9]

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
	#init state
	state = MalletState.DOWN
	
func _input(event: InputEvent) -> void:
	pass
	#print(event.device)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(Input.is_action_just_released(current_input_map[4])):
		if(state == MalletState.UP):
			# if we are ghost-dashing, interrupt normal cooldown
			_on_cooldown_timer_timeout()
	
	#otherwise no input taken while !can_control
	if (!can_control or movement_paused or game.dev_console_active):
		return
		
	move_vertical = Input.get_joy_axis(0,JOY_AXIS_LEFT_X)
	move_horizontal = Input.get_joy_axis(0,JOY_AXIS_LEFT_Y)
	if(kb_input):
		move_vertical = Input.get_axis(current_input_map[0],current_input_map[1])
		move_horizontal = Input.get_axis(current_input_map[2],current_input_map[3])
	
	#holding power button
	power_is_held = Input.is_action_pressed(current_input_map[4])
	if(power_is_held):
		power_held_frames += 1
		if(power_held_frames == 20):
			start_power_charging()
	else:
		if(state == MalletState.DOWN):
			current_move_speed = MOVE_SPEED_NORMAL
	
	#checking consecutive power taps
	
	#block button is held
	if(Input.is_action_pressed(current_input_map[5]) && !Input.is_action_pressed(current_input_map[4])):
		if(block_mode == BlockMode.BLOCK_MODE.SLOW):
			handle_block_slow()
		elif(block_mode == BlockMode.BLOCK_MODE.BUNT):
			handle_block_bunt()
		elif(block_mode == BlockMode.BLOCK_MODE.ORBIT):
			handle_block_orbit()
	else:
		if(block_mode == BlockMode.BLOCK_MODE.SLOW):
			release_block_slow()
		elif(block_mode == BlockMode.BLOCK_MODE.BUNT):
			release_block_bunt()
		elif(block_mode == BlockMode.BLOCK_MODE.ORBIT):
			release_block_orbit()
		
		
	#just pressed 'power' button
	if(Input.is_action_just_pressed(current_input_map[4]) && state == MalletState.DOWN):
		if(consecutive_power_tap_frames == 20):
			consecutive_countdown = true
			consecutive_power_taps = 1
		elif(consecutive_power_tap_frames > 0):
			consecutive_power_taps += 1
			if(consecutive_power_taps == 2):
				#print("ghost-dash!")
				ghost_dash()
				#reset taps check
				consecutive_power_taps = 0
				consecutive_countdown = false
				consecutive_power_tap_frames = 20
				
	
	if(consecutive_countdown):
		#print(consecutive_power_tap_frames)
		consecutive_power_tap_frames -= 1
		if(consecutive_power_tap_frames == 0):
			#time out, reset taps check
			consecutive_power_taps = 0
			consecutive_countdown = false
			consecutive_power_tap_frames = 20
			
		#state = MalletState.CHARGING
		#$PowerTimer.wait_time = power_times[power_lvl]
		#$PowerTimer.start()
		#power_pressed_dir = Vector2(move_horizontal * -1, move_vertical)
		#if(power_pressed_dir == Vector2(0,0)):
			#if(player == 0):
				#power_pressed_dir = Vector2(1,0)
			#if(player == 1):
				#power_pressed_dir = Vector2(-1,0)
				
	#just released power button while charging
	if(Input.is_action_just_released(current_input_map[4])):
		power_held_frames = 0
		if power_lvl > 0:
			state = MalletState.PUSHING
			can_control = false
			$CooldownTimer.wait_time = .3
			$CooldownTimer.start()
			current_move_speed = 8 + 3 * power_lvl
			for chev in $Chevrons.get_children():
				chev.queue_free()
		$PowerTimer.stop()
		power_lvl = 0
	
	#spin pressed, power and raiseup are not
	#if(Input.is_action_pressed(current_input_map[6]) &&
		#!Input.is_action_pressed(current_input_map[4]) && 
		#!Input.is_action_pressed(current_input_map[7])):
		#move_vertical = 0.0
		#move_horizontal = 0.0
	check_apply_spin()
	
	#'ghost mode'
	#if(Input.is_action_just_pressed(current_input_map[7]) and state == MalletState.DOWN):
		#state = MalletState.UP
		#current_move_speed = MOVE_SPEED_UP
		#lift_up()
		#
	#if(Input.is_action_just_released(current_input_map[7]) and state == MalletState.UP):
		#drop_down()
		

func start_power_charging():
	#no more double-tap check
	consecutive_power_tap_frames = 20
	consecutive_power_taps = 0
	consecutive_countdown = false
	#start charging up
	state = MalletState.CHARGING
	current_move_speed = MOVE_SPEED_POWER
	#pretend the charging timer timed out once immediately
	_on_power_timer_timeout()
	#$PowerTimer.wait_time = power_times[power_lvl]
	$PowerTimer.start()
	power_pressed_dir = Vector2(move_horizontal * -1, move_vertical)
	if(power_pressed_dir == Vector2(0,0)):
		if(player == 0):
			power_pressed_dir = Vector2(1,0)
		if(player == 1):
			power_pressed_dir = Vector2(-1,0)

func ghost_dash():
	var move_vector = Vector2(move_horizontal * -1, move_vertical)
	dash_angle_degrees = rad_to_deg(move_vector.angle())
	#print("ghost dash angle:", dash_angle_degrees)
	state = MalletState.UP
	current_move_speed = MOVE_SPEED_UP
	can_control = false
	$CooldownTimer.wait_time = .3
	$CooldownTimer.start()
	lift_up()

#every frame, if block button held, and charge not
func handle_block_slow():
	if(!block_active and state == MalletState.DOWN):
		state = MalletState.BLOCKING_SLOW
		block_active = true
		blocker = blocker_scene.instantiate()
		add_child(blocker)
	
#every frame, if block button held, and charge not
func handle_block_bunt():
	if(!block_active and state == MalletState.DOWN):
		state = MalletState.BLOCKING_BUNT
		block_active = true
		$Ring.visible = true
		physics_material_override.absorbent = true

func check_bunt():
	return state == MalletState.BLOCKING_BUNT
	
func handle_block_orbit():
	pass

func release_block_slow():
	if(block_active && Input.is_action_just_released(current_input_map[5])):
		block_active = false
		state = MalletState.DOWN
		blocker.queue_free()
	
func release_block_bunt():
	if(block_active && Input.is_action_just_released(current_input_map[5])):
		block_active = false
		state = MalletState.DOWN
		$Ring.visible = false
		physics_material_override.absorbent = false
	
func release_block_orbit():
	pass
	
func check_apply_spin():
	var left = current_input_map[6]
	var right = current_input_map[7]
	if(player == 1):
		left = current_input_map[6]
		right = current_input_map[7]
	if(game.computer_mode):
		left = current_input_map[6]
		right = current_input_map[7]
	#right
	if(Input.is_action_just_pressed(left)):
		if(spin_power > 0):
			spin_power -= 8
			spin_power = max(spin_power,0)
		elif(spin_power > -16):
			spin_power = -16
		elif(spin_power > -22):
			spin_power = -22
		else:
			spin_power = -MAX_SPIN_POWER
		update_spin_ui()
		#cap spin_power
		spin_power = max(spin_power, MAX_SPIN_POWER * -1)
		$SpinDischarge.start(1.0)
	#p1 right
	if(Input.is_action_just_pressed(right)):
		#currently hard coded here, would like to have it based on a curve/map somehow
		#curves don't seem to have necessary range
		if(spin_power < 0):
			spin_power += 8
			spin_power = min(spin_power,0)
		elif(spin_power < 16):
			spin_power = 16
		elif(spin_power < 22):
			spin_power = 22
		else:
			spin_power = MAX_SPIN_POWER
		update_spin_ui()
		#cap spin_power
		spin_power = min(spin_power,MAX_SPIN_POWER)
		$SpinDischarge.start(1.0)

func adjust_dash_direction(angle):
	var pressed_dir_angle = rad_to_deg(power_pressed_dir.angle())
	if(angle < 0.0):
		pressed_dir_angle += dash_adjust_speed
	elif(angle > 0.0):
		pressed_dir_angle -= dash_adjust_speed
	power_pressed_dir = Vector2.from_angle(deg_to_rad(pressed_dir_angle))
	return pressed_dir_angle

func lift_up():
	var tween = get_tree().create_tween()
	tween.tween_property($AnimatedSprite2D, "scale", Vector2(1.5,1.5), .1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	var tween2 = get_tree().create_tween()
	tween2.tween_property($AnimatedSprite2D, "modulate", Color(1.0,1.0,1.0,.5), .1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	$CollisionShape2D.disabled = true
	
func drop_down():
	var tween = get_tree().create_tween()
	tween.tween_property($AnimatedSprite2D, "scale", Vector2(1.0,1.0), .1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	var tween2 = get_tree().create_tween()
	tween2.tween_property($AnimatedSprite2D, "modulate", Color(1.0,1.0,1.0,1.0), .1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(.1).timeout
	$CollisionShape2D.disabled = false
	
	#current_move_speed = MOVE_SPEED_NORMAL
	
func _physics_process(delta: float) -> void:
	if(movement_paused):
		return
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
		#if currently attack dashing
		if(state == MalletState.PUSHING):
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
			#print("angle:", dash_angle_degrees)
			#print(Vector2.from_angle(deg_to_rad(dash_angle_degrees)))
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

#mostly used by the 'impact delay' func in puck script
func pause_cooldown_timer(state) -> void:
	if($CooldownTimer.time_left > 0.0):
		$CooldownTimer.paused = state
	
# power charge attack finished
func _on_cooldown_timer_timeout() -> void:
	can_control = true
	current_move_speed = MOVE_SPEED_NORMAL
	$CooldownTimer.stop()
	if(state == MalletState.UP):
		drop_down()
	state = MalletState.DOWN
	
func _on_lock_player_input(locked: bool) -> void:
	can_control = !locked

func _on_spin_discharge_timeout() -> void:
	#less spin each timeout
	if(spin_power > 0):
		spin_power -= spin_decay
		#clamp at 0 if we go under
		spin_power = max(spin_power,0)
	elif(spin_power < 0):
		spin_power += spin_decay
		#clamp at 0 if we go over
		spin_power = min(spin_power,0)
	update_spin_ui()
	#if spin not fully dissipated, continue
	if(spin_power != 0):
		$SpinDischarge.start(1.0)

func set_spin_decay(val_string):
	print("hi")
	print(int(val_string))
	spin_decay = int(val_string)

func update_spin_ui():
	if(spin_power < -22):
		$Spin.animation = "left_3"
	elif(spin_power < -16 && spin_power >= -22):
		$Spin.animation = "left_2"
	elif(spin_power < -1 && spin_power >= -16):
		$Spin.animation = "left_1"
	elif(spin_power >= -1 && spin_power <= 1):
		$Spin.animation = "0"
	elif(spin_power > 1 && spin_power <= 16):
		$Spin.animation = "right_1"
	elif(spin_power > 16 && spin_power <= 22):
		$Spin.animation = "right_2"
	elif(spin_power > 22):
		$Spin.animation = "right_3"
