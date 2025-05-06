extends Node2D

const MOVE_SPEED_NORMAL = 8
const MOVE_SPEED_POWER = 3

@export var chevron_scene: PackedScene

var can_control = true
var move_vertical = Input.get_joy_axis(0,JOY_AXIS_LEFT_X)
var move_horizontal = Input.get_joy_axis(0,JOY_AXIS_LEFT_Y)

var current_move_speed = 8

var power_is_held
var power_lvl = 0
var spin

var kb_input = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(!can_control):
		return
		
	move_vertical = Input.get_joy_axis(0,JOY_AXIS_LEFT_X)
	move_horizontal = Input.get_joy_axis(0,JOY_AXIS_LEFT_Y)
	if(kb_input):
		move_vertical = Input.get_axis("move_left","move_right")
		move_horizontal = Input.get_axis("move_forward","move_back")
	
	power_is_held = Input.is_action_pressed("power")
	if(power_is_held):
		current_move_speed = MOVE_SPEED_POWER
	else:
		current_move_speed = MOVE_SPEED_NORMAL
		
	if(Input.is_action_just_pressed("power")):
		$PowerTimer.start()
	
	if(Input.is_action_just_released("power")):
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
	
	global_position += Vector2(move_horizontal * -1, move_vertical) * current_move_speed
	var move_vector = Vector2(move_horizontal * -1, move_vertical)
	#var angle = move_vector.angle_to(Vector2(1,0))
	var angle = rad_to_deg(move_vector.angle())
	if(move_vector == Vector2(0,0)):
		angle = 0.0
	#print(angle)
	$Chevrons.rotation_degrees = angle

func _on_power_timer_timeout() -> void:
	var chev = chevron_scene.instantiate()
	$Chevrons.add_child(chev)
	chev.offset.x = 80 + (40 * power_lvl)
	power_lvl += 1

func _on_cooldown_timer_timeout() -> void:
	can_control = true
	$CooldownTimer.stop()
