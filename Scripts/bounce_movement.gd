extends Node2D

const MAX_VELOCITY = 3000

var velocity = Vector2.ZERO
var speed = 200

var movement_paused = false
@export var has_impact_delay: bool
@export var impact_circle_curve: Curve
var impact_delay_cooldown = false
#flag to be set on collision so we don't check more than once
var impact_check = false
var draw_impact_circle = false
var impact_circle_pos
var impact_circle_time = 0.0
var impact_power_dict = {
	1: .4,
	2: .5,
	3: .6,
	4: .8,
	5: 1.0
}

var bounds = Rect2(Vector2(0, 0), Vector2(800, 600)) # Example edge limits (adjust as needed)
var rigid_body
var spin_push

func _ready():
	spin_push = 0
	rigid_body = $RigidPhysics
	# Initialize random direction
	SignalBus.lock_player.connect(_on_lock_player)


func _process(delta):
	#queue_redraw()
	if(draw_impact_circle):
		var circ_scale = impact_circle_curve.sample(impact_circle_time)
		$Circle.scale = Vector2(circ_scale,circ_scale)
		impact_circle_time += delta
		
func _physics_process(delta):
	if(movement_paused):
		rigid_body.linear_velocity = Vector2(0.0,0.0)
		return
	# Move and collide with walls if needed
	var collision_info = rigid_body.move_and_collide(velocity * delta)
	if collision_info:
		velocity = velocity.bounce(collision_info.get_normal())
		#print(collision_info.get_collider().name)
		var coll_obj = collision_info.get_collider()
		#hit a player mallet
		if(coll_obj.is_in_group("mallet")):
			if(has_impact_delay && coll_obj.power_lvl > 0 && !impact_check):
				impact_delay(coll_obj, 1.0, coll_obj.power_lvl)
			if(coll_obj.check_bunt()):
				velocity *= .4
			apply_spin(coll_obj.spin_power)
	if(spin_push != 0):
		#print(velocity)
		#var dir = velocity.rotated(deg_to_rad(-90)).normalized()
		#rigid_body.apply_force(dir)
		rigid_body.linear_velocity = rigid_body.linear_velocity.rotated(deg_to_rad(spin_push/10))
		#print("new:", velocity)
	#print(rigid_body.linear_velocity.length)
	rigid_body.linear_velocity = rigid_body.linear_velocity.limit_length(MAX_VELOCITY)
	#print("new velocity: ", rigid_body.linear_velocity.length)
	
func _integrate_forces(state):
	state.linear_velocity = state.linear_velocity.limit_length(MAX_VELOCITY)
	print(state.linear_velocity)

#func _draw():
	#if(draw_impact_circle):
		#draw_circle(impact_circle_pos, impact_circle_curve.sample(impact_circle_time), Color.WHITE)

func impact_delay(mallet, wait_time, pow_lvl):
	impact_check = true
	$Circle.global_position = rigid_body.global_position
	impact_circle_time = 0.0
	draw_impact_circle = true
	$Circle.visible = true
	#mallet
	mallet.set_control_mode("bullet_time")
	var mallet_vel = mallet.current_move_speed
	mallet.current_move_speed = 0
	mallet.movement_paused = true
	mallet.pause_cooldown_timer(true)
	#puck
	var puck_vel = rigid_body.linear_velocity
	movement_paused = true
	print("stored puck vel:", puck_vel)
	rigid_body.linear_velocity = Vector2(0.0,0.0)
	rigid_body.set_freeze_enabled(true)
	print("hi")
	await get_tree().create_timer(wait_time).timeout
	$Circle.visible = false
	draw_impact_circle = false
	impact_circle_time = 0.0
	#reset puck
	movement_paused = false
	rigid_body.set_freeze_enabled(false)
	rigid_body.linear_velocity = puck_vel
	#reset mallet
	mallet.set_control_mode("normal")
	mallet.pause_cooldown_timer(false)
	mallet.movement_paused = false
	mallet.current_move_speed = mallet_vel
	# fudging our escape velocity, manually slowing it down based on
	# what power level the impact was at
	velocity *= impact_power_dict[pow_lvl]
	# no more impact for a small time
	await get_tree().create_timer(.5).timeout
	impact_check = false
	
func apply_spin(spin_amt):
	spin_push = spin_amt
	if(spin_amt != 0):
		$SpinDecay.start(.1)
	
func _start():
	# Reset position and velocity when the game starts
	var angle = randf_range(0, 2 * PI) # PI
	velocity = Vector2(cos(angle), sin(angle)) * speed
	rigid_body.linear_velocity = velocity

func _reset():
	rigid_body.global_position = Vector2(960, 540) # Directly set the rigid body's position
	rigid_body.linear_velocity = Vector2.ZERO
	velocity = Vector2.ZERO # Reset internal velocity tracking

func _on_lock_player(locked):
	# Lock or unlock player input
	if locked:
		_reset() # Reset position
	else:
		_start() # Start moving again


func _on_spin_decay_timeout() -> void:
	if(spin_push > 0):
		spin_push -= 1
	if(spin_push < 0):
		spin_push += 1
