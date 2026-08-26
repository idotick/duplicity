extends Control

@onready var title_path = "res://src/screens/menus/title.tscn"
@onready var pause_path = "res://src/screens/menus/pause.tscn"
@onready var screen = $Screen

var paused : bool = false

func _ready() -> void:
	get_window().min_size = Vector2(1280, 720)


func use_name(node: Node, id: String) -> bool:
	return node.name == id


func check_state() -> void:
	if paused:
		screen.modulate = Color("646464ff")
		screen.process_mode = Node.PROCESS_MODE_DISABLED
		
		if get_children().find_custom(use_name.bind("Pause")) == -1:
			var pause : PackedScene = load(pause_path)
			var menu = pause.instantiate()
			add_child(menu)
	else:
		screen.modulate = Color("ffffffff")
		screen.process_mode = Node.PROCESS_MODE_INHERIT
		
		var i = get_children().find_custom(use_name.bind("Pause"))
		
		if i != -1:
			get_children()[i].queue_free()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		paused = !paused
	
	check_state()
