extends MicroGame

@export var progress_speed : float = 0.3
@export var student_positions: Array[Marker2D] 

@onready var screen: AnimatedSprite2D = %ScreenAnim
@onready var writing_audio: AudioStreamPlayer = $WritingAudio
@onready var pencil_audio: AudioStreamPlayer = $PencilAudio
@onready var focus: Node2D = $Focus
@onready var classmates_layer: Parallax2D = $Classmates

# scenes of students to choose from
const possible_classmates: Array[PackedScene] = [
	preload("res://micro_games/note_taking/scenes/classmate_miku.tscn"),
	preload("res://micro_games/note_taking/scenes/classmate_teto.tscn"),
	preload("res://micro_games/note_taking/scenes/classmate_neru.tscn")
]

var classmates : Array[NT_Classmate]
var sample_areas : Array[Area2D]
var sample_count : int = 0
var blocked_areas : Dictionary[Area2D, bool]

var seeing_screen : bool = false
var progress : float = 0

enum GameState {
	BEFORE, ACTIVE, OVER
}
var game_state : GameState = GameState.BEFORE

# STATIC VARIABLES
static var play_count := 0
static var _hook_installed := false
# previously selected classmates from previous iterations in the same run
# where key is the index from possible_classmates
static var selected_classmates: Dictionary[int, bool]

func _init() -> void:
	play_count += 1
	if not _hook_installed:
		_hook_installed = true
		GameManager.exit_screen.connect(_on_screen_exited)
		
static func _on_screen_exited(screen: GameManager.Screen) -> void:
	if screen == GameManager.Screen.Game:
		play_count = 0
		selected_classmates.clear()

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
		
	# add classmates
	assert(student_positions.size() != 0)
	assert(possible_classmates.size() != 0)
	
	# loop for the amount of students that need to be added
	assert(_required_classmates() + selected_classmates.size() <= student_positions.size())
	for _i in range(_required_classmates()):
		var mate_index : int
		while true:
			mate_index = randi() % possible_classmates.size()
			if !selected_classmates.has(mate_index):
				break
		selected_classmates[mate_index] = true		
		
	# add selected classmates in random order
	var randomized_mates = selected_classmates.keys()
	randomized_mates.sort_custom(func(): return randi()%2)
	for i in range(randomized_mates.size()):
		var mate_index = randomized_mates[i]
		var classmate: NT_Classmate = possible_classmates[mate_index].instantiate()
		
		classmate.rest_time_max = 2.5
		if i == 0:
			classmate.vertical_range = Vector2(-75, 40)
			classmate.horizontal_range = Vector2(-150, 150)
		else:
			classmate.vertical_range = Vector2(-20, 0)
			classmate.horizontal_range = Vector2(-100, 100)
			classmate.rest_time_min = 1.5
		classmate.position = student_positions[i].position
		classmates_layer.add_child(classmate)
		classmates.append(classmate)
	
	_hide_classmates()
		
	# connect signals
	enter_animation.connect(_intro)
	start.connect(_game_start)
	lose.connect(_game_over)
	win.connect(_game_won)
	
	# set writing to loop
	writing_audio.finished.connect(func(): writing_audio.play())
	
	if is_launched_via_f6():
		get_window().content_scale_size = Vector2i(1920, 1080)
		focus.initialize()
		#get_viewport().size_2d_override.x = info.width
		#get_viewport().size_2d_override.y = info.height
		enter_animation.emit()
		await get_tree().create_timer(pre_game_time).timeout
		start.emit()
		
func _required_classmates() -> int:
	return max(min(play_count, possible_classmates.size()) - selected_classmates.size(), 0)

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
	#if game_state != GameState.ACTIVE: return
	
	if blocked_areas.size() >= sample_count/2:
		seeing_screen = false
		screen.modulate = Color.WHITE
	else:
		seeing_screen = true
		screen.modulate = Color.WEB_GREEN
	
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
	classmates_layer.hide()
	
func _show_classmates() -> void:
	classmates_layer.show()
	for mate in classmates:
		mate.appear(mate.initialize)
		
		
# for debugging
func is_launched_via_f6() -> bool:
	var main_setting = ProjectSettings.get_setting("application/run/main_scene")
	var main_scene_path = ResourceUID.get_id_path(ResourceUID.text_to_id(main_setting))
	var current_scene_path = get_tree().current_scene.scene_file_path
	return current_scene_path != main_scene_path
