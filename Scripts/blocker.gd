extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	print("something entered")
	if(body.is_in_group("puck")):
		slow_puck(body)
		
func slow_puck(puck):
	print("slowing puck")
	puck.linear_damp = 10


func _on_area_2d_body_exited(body: Node2D) -> void:
	print("something exited")
	if(body.is_in_group("puck")):
		body.linear_damp = 0.0
		
