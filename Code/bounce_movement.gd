extends RigidBody2D

var velocity = Vector2.ZERO
var speed = 200
var bounds = Rect2(Vector2(0, 0), Vector2(800, 600)) # Example edge limits (adjust as needed)
var rigid_body

func _ready():
	# Initialize random direction
	var angle = PI # randf_range(0, 2 * PI)
	velocity = Vector2(cos(angle), sin(angle)) * speed
	linear_velocity = velocity

func _physics_process(delta):
	# Move and collide with walls if needed
	var collision_info = move_and_collide(velocity * delta)
	if collision_info:
		velocity = velocity.bounce(collision_info.get_normal())
