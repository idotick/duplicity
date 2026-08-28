extends CharacterBody2D

signal death

@export_node_path("Camera2D") var camera

const DASH_SPEED = 300.0
const SPEED = 250.0
const JUMP_VELOCITY = -50.0
const PEAK_JUMP_TICK = 8

@onready var cam : Camera2D = get_node(camera)
@onready var falling : bool = not is_on_floor()

var moving : bool = false
var jump_released : bool = false
var jump_tick : int = 0
var dash_limit : int = 1
var n_dashes : int = 0
var dashing : bool = false


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
	var was_on_floor = is_on_floor()
	
	if is_on_floor() and $DashCooldown.is_stopped():
		n_dashes = 0
	
	if Input.is_action_pressed("jump") and (is_on_floor() or not falling):
		jump_released = false
		
		if jump_tick < PEAK_JUMP_TICK:
			velocity.y += JUMP_VELOCITY
		
			var mult = lerp(1.0, 0.75, jump_tick)
			gravity = mult * get_gravity()
			
		jump_tick += 1
		
	if Input.is_action_just_released("jump"):
		jump_released = true
		velocity.y /= 2
		jump_tick = 0
	
	if falling:
		if jump_released:
			gravity = 2 * get_gravity()
		
		velocity += gravity * delta
		$CoyoteTime.stop()
	
	if Input.is_action_just_pressed("dash") and n_dashes < dash_limit:
		$Hurtbox.set_collision_mask_value(3, false)
		$DashTime.start()
		was_on_floor = true
		dashing = true
		
		$DashCooldown.start()
		n_dashes += 1
	
	if not moving and dashing:
		if $Sprite.flip_h:
			velocity.x = -(DASH_SPEED + SPEED)
		else:
			velocity.x = (DASH_SPEED + SPEED)
	
	var direction := Input.get_axis("left", "right")
	if direction:
		moving = true
		velocity.x = direction * SPEED
		
		if dashing:
			velocity.x += direction * DASH_SPEED
	else:
		moving = false
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	
	if abs(velocity) > Vector2.ZERO:
		cam.global_position = lerp(cam.global_position, global_position, 0.2)
	
	move_and_slide()
	
	if is_on_floor() != was_on_floor:
		$CoyoteTime.start()
		falling = false


func _on_coyote_time_timeout() -> void:
	falling = true


func _on_dash_time_timeout() -> void:
	$Hurtbox.set_collision_mask_value(3, true)
	dashing = false


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Hitbox":
		death.emit()
		queue_free()
		area.owner.queue_free()
