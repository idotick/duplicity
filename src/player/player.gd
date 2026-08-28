extends CharacterBody2D

signal death

@export_node_path("Camera2D") var camera

const DASH_SPEED = 2000.0
const SPEED = 250.0
const JUMP_VELOCITY = -250.0

@onready var cam : Camera2D = get_node(camera)
@onready var falling : bool = not is_on_floor()

var jump_released : bool = false
var jump_multiplier : float = 1
var dash_limit : int = 1
var n_dashes : int = 0


func _process(_delta: float) -> void:
	if velocity.x > 0:
		$Sprite.play("walk")
		$Sprite.flip_h = false
	elif velocity.x < 0:
		$Sprite.play("walk")
		$Sprite.flip_h = true
	else:
		$Sprite.play("default")


func _physics_process(delta: float) -> void:
	var gravity = get_gravity()
	
	var collision = get_last_slide_collision()
	if collision:
		var collider : Node = collision.get_collider()
		if collider.name == "Antiplayer":
			death.emit()
			queue_free()
			collider.get_parent().get_parent().queue_free()
	
	var was_on_floor = is_on_floor()
	
	if is_on_floor():
		jump_multiplier = 1
		n_dashes = 0
	
	if Input.is_action_pressed("jump") and (is_on_floor() or not falling):
		jump_released = false
		if jump_multiplier < 2:
			jump_multiplier += 0.02
			
		velocity.y = JUMP_VELOCITY * jump_multiplier
		
	if Input.is_action_just_released("jump"):
		jump_released = true
		velocity.y /= 2
	
	if falling:
		if velocity.y >= 0 and not is_on_floor():
			if $AirHangTime.is_stopped():
				$AirHangTime.start()
		
		if jump_released:
			gravity = get_gravity()
		elif not $AirHangTime.is_stopped() and not is_on_floor():
			var mult = lerp(1.0, 0.1, $AirHangTime.time_left/$AirHangTime.wait_time)
			gravity = mult * get_gravity()
		
		
		velocity += gravity * delta
		$CoyoteTime.stop()
	
	# TO IMPLEMENT DASHING
	#var dash_velocity = 0
	#if Input.is_action_just_pressed("dash") and n_dashes < dash_limit:
		#if $Sprite.flip_h:
			#dash_velocity = -DASH_SPEED
		#else:
			#dash_velocity = DASH_SPEED
		#
		#velocity.x = dash_velocity
		#n_dashes += 1
	
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if abs(velocity) > Vector2.ZERO:
		cam.global_position = lerp(cam.global_position, global_position, 0.2)
	
	move_and_slide()
	
	if is_on_floor() != was_on_floor:
		$CoyoteTime.start()
		falling = false


func _on_coyote_time_timeout() -> void:
	falling = true
