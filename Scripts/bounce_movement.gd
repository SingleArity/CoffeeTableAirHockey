extends Node2D

const MAX_VELOCITY = 3000

var velocity = Vector2.ZERO
var speed = 200

var movement_paused = false
@export var has_impact_delay: bool
var impact_delay_cooldown = false

var bounds = Rect2(Vector2(0, 0), Vector2(800, 600)) # Example edge limits (adjust as needed)
var rigid_body 
var spin_push

func _ready():
	spin_push = 0
	rigid_body = $RigidPhysics
	# Initialize random direction
	SignalBus.lock_player.connect(_on_lock_player)


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
			if(has_impact_delay && coll_obj.current_move_speed >= 15 && !impact_delay_cooldown):
				impact_delay(coll_obj, .5)
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

func impact_delay(mallet, wait_time):
	#mallet
	var mallet_vel = mallet.current_move_speed
	mallet.current_move_speed = 0
	mallet.movement_paused = true
	mallet.pause_cooldown_timer(true)
	#puck
	var puck_vel = rigid_body.linear_velocity
	movement_paused = true
	rigid_body.linear_velocity = Vector2(0.0,0.0)
	await get_tree().create_timer(wait_time).timeout
	#reset puck
	movement_paused = false
	rigid_body.linear_velocity = puck_vel
	#reset mallet
	mallet.pause_cooldown_timer(false)
	mallet.movement_paused = false
	mallet.current_move_speed = mallet_vel
	
	#no more for a small time
	impact_delay_cooldown = true
	await get_tree().create_timer(.2).timeout
	impact_delay_cooldown = false
	
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
