extends Control

signal next_level
signal play(title: String)
signal lose

@onready var player: CharacterBody2D = $Player
@onready var cam : Camera2D = $PlayerCamera
@onready var win_area: Area2D = $winArea

var music_id = [ "forest_music", "forest_music", "cave_music" ]
var stage : int = 1

func _ready() -> void:
	var metadata = self.scene_file_path.get_file().get_basename()
	stage = metadata.to_int()
	
	name = "Level " + str(stage)
	
	if !player.death.is_connected(_on_player_death):
		player.death.connect(_on_player_death)
	
	if !win_area.win.is_connected(_on_win):
		win_area.win.connect(_on_win)


func get_camera() -> Camera2D:
	return $PlayerCamera


func start_music() -> void:
	var index = stage - 1
	
	if index > 0:
		if music_id[index] == music_id[index - 1]:
			print("Same soundtrack, skipping action...")
			return
	
	play.emit(music_id[index])


func _on_win() -> void:
	next_level.emit.call_deferred()


func _on_player_death() -> void:
	lose.emit.call_deferred()
