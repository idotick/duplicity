extends Area2D

@export var win_screen_scene: PackedScene

# next level scene selection
@export_file("*.tscn") var next_level_path: String


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	print("Something entered win area: ", body.name) # Check output console
	if body.name == "Player":
		show_win_overlay()


func show_win_overlay() -> void:
	# pause gameplay
	get_tree().paused = true
	
	# instantiate and overlay win scene
	if win_screen_scene:
		var win_overlay = win_screen_scene.instantiate()
		
		# pass path to win screen script for next lvl button
		win_overlay.next_level_path = next_level_path
		
		get_tree().current_scene.add_child(win_overlay)
