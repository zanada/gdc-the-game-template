extends Node2D
class_name NT_Classmate

@export var vertical_range :Vector2 = Vector2(-100, 100)
@export var horizontal_range :Vector2 = Vector2(-200, 200)
@export var min_distance : float = 50

@export var rest_time_min : float = 1.0
@export var rest_time_max : float = 2.0

@export var move_time : float = 0.4

var active :bool = false
var origin : Vector2

func _ready() -> void:
	origin = position

func initialize():
	active = true
	_rest()
	
func stop():
	active = false
	
func _rest() -> void:
	if !active: return
	
	var timer : SceneTreeTimer = get_tree().create_timer(_random_time())
	await timer.timeout
	_move()
	
func _move() -> void:
	if !active: return
	
	var target : Vector2
	while true:
		var y = randf_range(vertical_range.x, vertical_range.y)
		var x = randf_range(horizontal_range.x, horizontal_range.y)
		target = origin + Vector2(x, y)
		#print(str(x), ", ", str(y))
		
		if position.distance_to(target) >= min_distance:
			break
	
	var tween : Tween = create_tween()\
	.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", target, move_time)
	tween.tween_callback(_rest)
	
func _random_time() -> float:
	return randf_range(rest_time_min, rest_time_max)
