extends Control

signal pause
signal play
signal buffer_end(state: int)

@onready var title_path = "res://src/screens/menus/title.tscn"
@onready var pause_path = "res://src/screens/menus/pause.tscn"
@onready var game_path = "res://src/screens/game.tscn"
@onready var buffer_path = "res://src/screens/menus/buffer.tscn"

@onready var screen: Control = $Screen
@onready var camera: Camera2D = $Screen/Camera
@onready var cam_overlay: Control = $Screen/Camera/Canvas/Overlays
@onready var sound_manager: Node = $Music

var paused : bool = false
var restarting : bool = false
var buffering : bool = false
var win : bool = false
var lose : bool = false


func _ready() -> void:
	get_window().min_size = Vector2(1280, 720)
	sound_manager.play("title_music")


func check_state() -> void:
	if screen.find_child("Title*", false, false) != null:
		paused = false
	
	if paused:
		pause.emit()
		if cam_overlay.find_child("Pause*", false, false) == null:
			var pause_scene : PackedScene = load(pause_path)
			var menu = pause_scene.instantiate()
			cam_overlay.add_child(menu)
	else:
		play.emit()
		var pause_scene = cam_overlay.find_child("Pause*", false, false)
		if pause_scene != null:
			pause_scene.queue_free()
			await get_tree().process_frame
	
	if restarting:
		_level_reset(screen.find_child("Game*", false, false))
	
	if buffering:
		if cam_overlay.find_child("Buffer*", false, false) == null:
			var overlay_scene : PackedScene = load(buffer_path)
			var overlay = overlay_scene.instantiate()
			cam_overlay.add_child(overlay)
		
			if win:
				overlay.set_text("LEVEL COMPLETE")
			else:
				overlay.set_text("DIED")


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
	
	#if Input.is_action_just_pressed("restart"):
		#restarting = true
		#check_state()
	
	if buffering:
		check_state()
	
	if not $LevelBuffer.is_stopped():
		game_paused()


func _level_reset(game_screen: Control) -> void:
	fade_out(1.0)
	sound_manager.fade_out("", 1.0)
	await sound_manager.silenced
	
	if game_screen == null:
		return
	
	game_screen._change_level(game_screen.current_stage)


func _on_game_start() -> void:
	fade_out(1.0)
	sound_manager.fade_out("", 1.0)
	await sound_manager.silenced
	
	camera.enabled = false
	
	var title_screen = screen.find_child("Title*", false, false)
	if title_screen != null:
		title_screen.queue_free()
		await get_tree().process_frame
	
	var game_screen : PackedScene = load(game_path)
	var game = game_screen.instantiate()
	pause.connect(game.pause)
	play.connect(game.play)
	
	game.sound_manager = sound_manager
	game.paused.connect(game_paused)
	game.playing.connect(game_playing)
	game.lose.connect(game_lose)
	game.win.connect(game_win)
	
	screen.add_child(game)


func adjust_camera() -> void:
	var game_screen : Control = screen.find_child("Game*", false, false)
	if game_screen == null:
		return
	
	var game_cam : Camera2D = game_screen.get_child(0).find_child("PlayerCamera")
	camera.global_position.x = game_cam.global_position.x/2


func game_paused() -> void:
	adjust_camera()
	camera.enabled = true
	screen.modulate = Color("646464ff")
	screen.call_deferred("set_process_mode", PROCESS_MODE_DISABLED)
	await get_tree().process_frame


func game_playing() -> void:
	camera.enabled = false
	screen.modulate = Color("ffffffff")
	screen.call_deferred("set_process_mode", PROCESS_MODE_INHERIT)
	await get_tree().process_frame


func game_lose() -> void:
	buffering = true
	lose = true
	
	adjust_camera()
	camera.enabled = true
	
	sound_manager.play("inactive_ability")
	$LevelBuffer.start()


func game_win() -> void:
	buffering = true
	win = true
	
	adjust_camera()
	camera.enabled = true
	
	sound_manager.play("active_ability")
	$LevelBuffer.start()


func _on_level_buffer_timeout() -> void:
	var overlay = cam_overlay.find_child("Buffer*", false, false)
	if overlay != null:
		overlay.queue_free()
		await get_tree().process_frame
	
	game_playing()
	buffering = false
	camera.enabled = false
	
	if win:
		buffer_end.emit(1)
	if lose:
		buffer_end.emit(0)
	
	win = false
	lose = false
