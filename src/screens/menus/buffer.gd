extends Control

@onready var label: Label = $Label


func _ready() -> void:
	name = "Buffer"


func set_text(text: String) -> void:
	label.text = text
