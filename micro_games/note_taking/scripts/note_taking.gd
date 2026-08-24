extends MicroGame

@export var blockers : Array[Area2D]

var sample_areas : Array[Area2D]
var sample_count : int = 0
var blocked_areas : Dictionary[Area2D, bool]

var seeing_screen : bool = false
var progress : float = 0

enum GameState {
	BEFORE, ACTIVE, OVER
}
var game_state : GameState = GameState.BEFORE

func _ready() -> void:
	# create area 2d's at marker positions
	for child in %TestPoints.get_children():
		var area2d : Area2D = Area2D.new()
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		var shape: Shape2D = CircleShape2D.new()
		shape.radius = 5.0
		collision_shape.shape = shape
		area2d.add_child(collision_shape)
		child.add_child(area2d)
		sample_areas.append(area2d)
		
		area2d.area_entered.connect(_area_blocked.bind(area2d, collision_shape))
		area2d.area_exited.connect(_area_unblocked.bind(area2d, collision_shape))
		
		sample_count += 1
		
	%ScreenRect.color = Color.DARK_SEA_GREEN
	
	game_state = GameState.ACTIVE
		
func _area_blocked(_blocking_area:Area2D, blocked_area:Area2D, shape:CollisionShape2D) -> void:
	blocked_areas[blocked_area] = true
	shape.debug_color = Color("001eb36b")
	_update_blockings() 
	
func _area_unblocked(_blocking_area:Area2D, blocked_area:Area2D, shape:CollisionShape2D) -> void:
	if !blocked_areas.has(blocked_area) or blocked_area.has_overlapping_areas(): return
	blocked_areas.erase(blocked_area)
	shape.debug_color = Color("0099b36b")
	_update_blockings() 
	
func _update_blockings() -> void:
	if blocked_areas.size() >= sample_count/2:
		%ScreenRect.color = Color.INDIAN_RED
		seeing_screen = false
	else:
		%ScreenRect.color = Color.DARK_SEA_GREEN
		seeing_screen = true
	
func _process(delta: float) -> void:
	
	if game_state == GameState.ACTIVE:
		if seeing_screen:
			progress += 0.2 * delta
			%ProgressBar.value = progress
			
			if progress >= 1:
				game_state = GameState.OVER
				win.emit()
			
	
