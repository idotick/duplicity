extends Control

signal paused
signal playing
signal lose

@onready var camera: Camera2D

var is_paused : bool = false


func _ready() -> void:
	await get_child(0).ready
	camera = get_child(0).level_cam
	name = "Game"


func _process(_delta: float) -> void:
	pass


func pause() -> void:
	if not is_paused:
		#camera.enabled = false
		is_paused = true
	
	paused.emit()


func play() -> void:
	if is_paused:
		#camera.enabled = true
		is_paused = false
	
	playing.emit()


func _on_player_death() -> void:
	lose.emit()
