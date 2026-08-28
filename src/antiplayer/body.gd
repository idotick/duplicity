extends CharacterBody2D


@export var point_interval : int = 6
@export var distance_threshold : float = 3

const SPEED = 300.0

@onready var path: Path2D = $"../.."
@onready var sprite: AnimatedSprite2D = $Sprite

var path_index : int = 0

func _process(_delta: float) -> void:
	if velocity.x > 0:
		sprite.play("walk")
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.play("walk")
		sprite.flip_h = true
	else:
		$Sprite.play("default")


func _physics_process(_delta: float) -> void:
	var points = path.curve.get_baked_points()
	
	if (path_index + point_interval) >= points.size():
		return
	
	if position.distance_to(points[path_index]) <= distance_threshold:
		path_index += point_interval
	
	velocity = (points[path_index] - position).normalized() * SPEED
	
	move_and_slide()
