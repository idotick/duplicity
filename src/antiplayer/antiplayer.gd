extends Path2D


@export_node_path("CharacterBody2D") var user

@onready var player : CharacterBody2D = get_node(user)
@onready var follow: PathFollow2D = $PathFollow2D
@onready var tracker_delay: Timer = $TrackerDelay

var tracking : bool = false

func _ready() -> void:
	tracker_delay.start()


func _process(_delta: float) -> void:
	if tracking:
		var tracker = player.global_position
		curve.add_point(tracker)


func _on_tracker_delay_timeout() -> void:
	curve.clear_points()
	curve.add_point(global_position)
	tracking = true
