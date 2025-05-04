extends Node2D

var velocity = Vector2.ZERO
var speed = 200
var bounds = Rect2(Vector2(0, 0), Vector2(800, 600)) # Example edge limits (adjust as needed)
var rigid_body 

func _ready():
	rigid_body = $RigidPhysics
	# Initialize random direction
	SignalBus.lock_player.connect(_on_lock_player)


func _physics_process(delta):
	# Move and collide with walls if needed
	var collision_info = rigid_body.move_and_collide(velocity * delta)
	if collision_info:
		velocity = velocity.bounce(collision_info.get_normal())

func _start():
	# Reset position and velocity when the game starts
	var angle = PI # randf_range(0, 2 * PI)
	velocity = Vector2(cos(angle), sin(angle)) * speed
	rigid_body.linear_velocity = velocity

func _reset():
	rigid_body.global_position = Vector2(700, 500) # Directly set the rigid body's position
	rigid_body.linear_velocity = Vector2.ZERO
	velocity = Vector2.ZERO # Reset internal velocity tracking

func _on_lock_player(locked):
	# Lock or unlock player input
	if locked:
		_reset() # Reset position
	else:
		_start() # Start moving again

