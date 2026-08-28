extends TextureRect


@export var spring_constant : float = 0.02
@export var mass : float = 20

var force : float
var velocity : float
var equilibrium : float

@onready var window_size = get_viewport_rect().size

func _ready() -> void:
	equilibrium = offset_transform_position.y
	
	offset_transform_position.y = 10


func _process(_delta: float) -> void:
	var deltay = offset_transform_position.y - equilibrium
	
	force = -spring_constant * deltay
	velocity += force/mass 
	
	offset_transform_position.y += velocity
