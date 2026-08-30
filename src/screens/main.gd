extends Control

signal pause
signal play

@onready var title_path = "res://src/screens/menus/title.tscn"
@onready var pause_path = "res://src/screens/menus/pause.tscn"
@onready var game_path = "res://src/screens/game.tscn"

@onready var screen: Control = $Screen
@onready var camera: Camera2D = $Screen/Camera
@onready var cam_overlay: Control = $Screen/Camera/Canvas/Overlays
@onready var sound_manager: Node = $Music

var paused : bool = false
var restarting : bool = false


func _ready() -> void:
	get_window().min_size = Vector2(1280, 720)
	sound_manager.play("title_music")


func check_state() -> void:
	if screen.find_child("Title*", false, false) != null:
		paused = false
	
	if paused:
		pause.emit()
		sound_manager.change_volume("", 0.25, 0.01)
		if cam_overlay.find_child("Pause*", false, false) == null:
			var pause_scene : PackedScene = load(pause_path)
			var menu = pause_scene.instantiate()
			cam_overlay.add_child(menu)
	else:
		play.emit()
		sound_manager.change_volume("", 1, 0.01)
		var pause_scene = cam_overlay.find_child("Pause*", false, false)
		if pause_scene != null:
			pause_scene.queue_free()
	
	if restarting:
		if screen.find_child("Game*", false, false) == null:
			return
		
		_on_game_start()


func fade_out(duration: float) -> void:
	var tween = create_tween()
	
	tween.tween_property(screen, "modulate", Color("000000"), duration)
	
	await tween.finished
	screen.modulate = Color("ffffff")


func _process(_delta: float) -> void:
	restarting = false
	if Input.is_action_just_pressed("pause"):
		paused = !paused
		check_state()
	
	if Input.is_action_just_pressed("restart"):
		restarting = true
		check_state()


func _on_game_start() -> void:
	fade_out(1.0)
	sound_manager.fade_out("", 1.0)
	await sound_manager.silenced
	
	camera.enabled = false
	sound_manager.play("forest_music")
	
	for child in screen.get_children():
		if child.name != "Camera":
			child.queue_free()
	
	var game_screen : PackedScene = load(game_path)
	var game = game_screen.instantiate()
	pause.connect(game.pause)
	play.connect(game.play)
	
	game.paused.connect(game_paused)
	game.playing.connect(game_playing)
	game.lose.connect(game_lose)
	
	screen.add_child(game)


func adjust_camera() -> void:
	var game_screen : Control = screen.find_child("Game*", false, false)
	if game_screen == null:
		return
	
	var game_cam : Camera2D = game_screen.find_child("PlayerCamera")
	camera.global_position.x = game_cam.global_position.x/2


func game_paused() -> void:
	adjust_camera()
	camera.enabled = true
	screen.modulate = Color("646464ff")
	screen.process_mode = Node.PROCESS_MODE_DISABLED


func game_playing() -> void:
	camera.enabled = false
	screen.modulate = Color("ffffffff")
	screen.process_mode = Node.PROCESS_MODE_INHERIT


func game_lose() -> void:
	adjust_camera()
	camera.enabled = true
