extends Node2D

@export var max_distance : float = 300.0
@export var curve : Curve

var origin : Vector2

func _ready() -> void:
	origin = get_viewport_rect().get_center()
	position = origin

func _input(event) -> void:
	if event is InputEventMouseMotion:
		print(event.position)
		_look(event.position)
		
		
func _look(mouse_pos: Vector2):
	var direction :Vector2 = origin.direction_to(mouse_pos)
	var magnitude :float = origin.distance_to(mouse_pos)
	
	position = origin + direction * _curve_scaling(magnitude)
	
func _limit_scaling(x: float) -> float:
	return min(x, max_distance)
	
func _curve_scaling(x: float) -> float:
	assert(curve)
	return max_distance * curve.sample(x/max_distance)
