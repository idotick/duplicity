extends Control

@onready var label: Label = $Label

# passed from the Area2D trigger
var next_level_path: String = ""


func _ready() -> void:
	name = "Win"
	# allows UI button clicks
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_next_level_pressed() -> void:
	if next_level_path != "":
		get_tree().paused = false
		get_tree().change_scene_to_file(next_level_path)


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_exit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/screens/main.tscn")
