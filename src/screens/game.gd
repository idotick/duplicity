extends Control

signal paused
signal playing
signal lose
signal win

@onready var sound_manager: Node
@onready var camera: Camera2D

var is_paused : bool = false
var current_stage : int = 3


func handle_end() -> void:
	var title = load("res://src/screens/menus/title.tscn").instantiate()
	
	title.set_text("THANKS FOR PLAYING!")
	get_tree().current_scene.screen.add_child(title)
	sound_manager.override("title_music")
	
	queue_free()
	await get_tree().process_frame


func add_level(lvl_num: int) -> Control:
	if lvl_num > 3:
		handle_end()
		return null
	
	var path : String = "res://src/levels/level%s.tscn" % lvl_num
	var level_scene : PackedScene = load(path)
	var level : Control = level_scene.instantiate()
	
	add_child(level)
	
	return level


func _ready() -> void:
	name = "Game"
	
	var level = add_level(current_stage)
	camera = level.get_camera()


func _process(_delta: float) -> void:
	pass


func pause() -> void:
	camera = get_child(0).get_camera()
	if not is_paused:
		camera.call_deferred("set_enabled", false)
		is_paused = true
	
	paused.emit()


func play() -> void:
	camera = get_child(0).get_camera()
	if is_paused:
		camera.call_deferred("set_enabled", true)
		is_paused = false
	
	playing.emit()


func _on_player_death() -> void:
	lose.emit()


func _on_level_play(title: String) -> void:
	sound_manager.play(title)


func _buffer_next() -> void:
	pause()
	win.emit()


func _buffer_again() -> void:
	pause()
	lose.emit()


func _change_level(level: int) -> void:
	play()
	current_stage = level
	get_child(0).queue_free()
	await get_tree().process_frame
	
	var new_level = add_level(current_stage)
	if new_level != null:
		camera = new_level.get_camera()


func _add_level_index(n: int) -> void:
	current_stage += n
	_change_level(current_stage)


func _on_child_entered_tree(node: Node) -> void:
	if node.name.begins_with("Level"):
		if !node.play.is_connected(_on_level_play):
			node.play.connect(_on_level_play)
		if !node.next_level.is_connected(_buffer_next):
			node.next_level.connect(_buffer_next)
		if !node.lose.is_connected(_buffer_again):
			node.lose.connect(_buffer_again)
		if !get_tree().current_scene.buffer_end.is_connected(_add_level_index):
			get_tree().current_scene.buffer_end.connect(_add_level_index)


func _on_child_order_changed() -> void:
	if get_children().size() == 1:
		get_child(0).start_music()
