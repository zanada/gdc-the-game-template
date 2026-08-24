extends MicroGame

@export var classmates : Array[NT_Classmate]
@export var progress_speed : float = 0.3

@onready var screen: AnimatedSprite2D = %ScreenAnim
@onready var writing_audio: AudioStreamPlayer = $WritingAudio
@onready var pencil_audio: AudioStreamPlayer = $PencilAudio

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
	_hide_classmates()
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
		
	enter_animation.connect(_intro)
	start.connect(_game_start)
	lose.connect(_game_over)
	win.connect(_game_won)
	
	writing_audio.finished.connect(func(): writing_audio.play())
	#_game_start()

func _intro() -> void:
	await get_tree().create_timer(2.0 * pre_game_time / 3.0).timeout
	_show_classmates() 
		
func _game_start() -> void:
	%CenterContainer.hide()
	screen.animation = "Class"
	
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
	if game_state != GameState.ACTIVE: return
	
	if blocked_areas.size() >= sample_count/2:
		seeing_screen = false
	else:
		seeing_screen = true
	
func _process(delta: float) -> void:
	if game_state != GameState.ACTIVE: 
		if writing_audio.playing: writing_audio.stop()
		return
	
	if seeing_screen:
		if !writing_audio.playing: writing_audio.play()
		if !pencil_audio.playing:
			var rng :float = randf()
			if rng < 0.01: pencil_audio.play()
		
		progress += progress_speed * delta
		%ProgressBar.value = progress
		
		if progress >= 1:
			game_state = GameState.OVER
			win.emit()
		return
	if writing_audio.playing: writing_audio.stop()
	
			
func _game_over() -> void:
	#for mate in classmates:
		#mate.stop()
	
	game_state = GameState.OVER
	_hide_classmates()
	screen.animation = "Over"
	
func _game_won() -> void:
	game_state = GameState.OVER
	
func _hide_classmates() -> void:
	$MidGround2Para.hide()
	
func _show_classmates() -> void:
	$MidGround2Para.show()
	for mate in classmates:
		mate.appear(mate.initialize)
