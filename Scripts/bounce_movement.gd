extends Sprite2D

var velocity = Vector2.ZERO
var speed = 200
var bounds = Rect2(Vector2(0, 0), Vector2(800, 600)) # Example edge limits (adjust as needed)
var rigid_body

func _ready():
	# Initialize random direction
	var angle = randf_range(0, 2 * PI)
	velocity = Vector2(cos(angle), sin(angle)) * speed
	rigid_body = $RigidPhysics

func _physics_process(delta):
	# Move the node
	position += velocity * delta

	# Check for collisions with bounds and bounce
	if position.x < bounds.position.x or position.x > bounds.position.x + bounds.size.x:
		velocity.x = - velocity.x
		position.x = clamp(position.x, bounds.position.x, bounds.position.x + bounds.size.x)
	if position.y < bounds.position.y or position.y > bounds.position.y + bounds.size.y:
		velocity.y = - velocity.y
		position.y = clamp(position.y, bounds.position.y, bounds.position.y + bounds.size.y)
	rigid_body.linear_velocity.x = velocity.x
	rigid_body.linear_velocity.y = velocity.y
