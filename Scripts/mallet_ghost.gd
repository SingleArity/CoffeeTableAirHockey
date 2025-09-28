extends Node2D

@export var opacity_curve: Curve

var time_elapsed = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_elapsed += delta
	$AnimatedSprite2D.set_modulate(Color(1.0,1.0,1.0,opacity_curve.sample(time_elapsed)))
	pass
