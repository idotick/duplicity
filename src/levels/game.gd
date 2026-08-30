extends Control

signal paused
signal playing
signal lose

@onready var camera: Camera2D = $PlayerCamera

var is_paused : bool = false


func _ready() -> void:
	name = "Game"


func _process(_delta: float) -> void:
	pass


func pause() -> void:
	if not is_paused:
		camera.enabled = false
		is_paused = true
	
	paused.emit()


func play() -> void:
	if is_paused:
		camera.enabled = true
		is_paused = false
	
	playing.emit()


func _on_player_death() -> void:
	lose.emit()


func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
