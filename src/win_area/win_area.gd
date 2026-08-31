extends Area2D

signal win

var emitted : bool = false

func _ready() -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	print("Something entered win area: ", body.name) # Check output console
	if body.name == "Player" and not emitted:
		win.emit.call_deferred()
		emitted = true
