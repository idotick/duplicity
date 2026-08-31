extends CharacterBody2D

signal death

@export_node_path("Camera2D") var camera

const DASH_SPEED = 300.0
const SPEED = 250.0
const JUMP_VELOCITY = -55.0
const PEAK_JUMP_TICK = 8
const G_MULT = 2.0

@onready var dash_particles: CPUParticles2D = $DashParticles
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hurtbox: Area2D = $Hurtbox
@onready var sfx: Node = $"../Effects"

@onready var coyote_time: Timer = $CoyoteTime
@onready var dash_time: Timer = $DashTime
@onready var dash_cooldown: Timer = $DashCooldown
@onready var rest_timer: Timer = $RestTimer
@onready var climb_limit: Timer = $ClimbLimit


@onready var cam : Camera2D = get_node(camera)
@onready var falling : bool = not is_on_floor()
@onready var RNG := RandomNumberGenerator.new()

var moving : bool = false
var jumping : bool = false
var jump_tick : int = 0

var dash_limit : int = 1
var n_dashes : int = 0
var dashing : bool = false

var climbing : bool = false
var can_climb : bool = false
var tired : bool = false


func kill() -> void:
	sfx.play("death")
	death.emit()
	queue_free()


func _process(_delta: float) -> void:
	RNG.randomize()
	
	if climbing:
		if $Sprite.animation != "sweat":
			$Sprite.play("sweat")
	elif moving:
		var direction := Input.get_axis("left", "right")
		$Sprite.flip_h = direction < 0
		$Sprite.play("walk")
	elif jumping and not is_on_floor():
		$Sprite.play("jump")
		$ClimbBuffer.start()
	else:
		if not rest_timer.is_stopped():
			$Sprite.play("idle")
		elif $Sprite.animation != "rest":
			rest_timer.wait_time = RNG.randi_range(5, 10)
			rest_timer.start()
	
	if dashing:
		$Sprite.play("dash")
	
	if Input.is_action_just_pressed("jump"):
		sfx.play("jump")
	
	if Input.is_action_just_pressed("dash"):
		sfx.play("dash")


func handle_jumping() -> void:
	if Input.is_action_pressed("jump") and (is_on_floor() or not falling):
		jumping = true
		
		if jump_tick < PEAK_JUMP_TICK:
			velocity.y += JUMP_VELOCITY
			
		jump_tick += 1
		
	if Input.is_action_just_released("jump"):
		jumping = false
		jump_tick = 0
		velocity.y /= 2


func handle_climbing(_gravity: Vector2) -> void:
	if Input.is_action_just_pressed("climb"):
		climb_limit.start()
	
	if Input.is_action_pressed("climb") and can_climb \
		and (not jumping or not $ClimbBuffer.is_stopped()) and not dashing:
		$ClimbBuffer.start()
		_gravity = Vector2.ZERO
		velocity.y = 0
		if Input.is_action_pressed("jump"):
			climbing = true
			var climb_delta = climb_limit.time_left
			var mult = 2 * inverse_lerp(0.0, climb_limit.wait_time, climb_delta)
			
			velocity.y = (mult + 0.5) * JUMP_VELOCITY
		
		coyote_time.start()
	
	if Input.is_action_just_released("climb"):
		coyote_time.stop()
		climb_limit.stop()
		climbing = false


func handle_gravity(gravity: Vector2, delta: float) -> void:
	if falling:
		if jumping:
			var jump_delta = inverse_lerp(0, PEAK_JUMP_TICK * 2, jump_tick)
			var mult = lerp(G_MULT, 1.5, jump_delta)
			gravity = mult * get_gravity()
		else:
			gravity = G_MULT * get_gravity()
	
		velocity += gravity * delta
		coyote_time.stop()


func handle_dashing() -> void:
	if Input.is_action_just_pressed("dash") and n_dashes < dash_limit:
		$Hurtbox.set_collision_mask_value(3, false)
		dash_time.start()
		can_climb = false
		dashing = true
		
		dash_cooldown.start()
		n_dashes += 1
	
	if not moving and dashing:
		if $Sprite.flip_h:
			velocity.x = -(DASH_SPEED + SPEED)
			$DashParticles.gravity = Vector2(980, 0)
		else:
			velocity.x = (DASH_SPEED + SPEED)
			$DashParticles.gravity = -Vector2(980, 0)
		
		$DashParticles.emitting = true
		$Sprite.play("dash")


func _physics_process(delta: float) -> void:
	var was_on_floor = is_on_floor()
	var gravity = get_gravity()
	
	if is_on_floor():
		if dash_cooldown.is_stopped():
			n_dashes = 0
		climbing = false
		tired = false
	
	if (not climbing and not jumping):
		falling = true
	
	handle_jumping()
	handle_climbing(gravity)
	handle_dashing()
	handle_gravity(gravity, delta)
	
	var direction := Input.get_axis("left", "right")
	if direction:
		moving = true
		velocity.x = direction * SPEED
		if dashing:
			$DashParticles.emitting = true
			$DashParticles.gravity = -direction * Vector2(980, 0)
			velocity.x += direction * DASH_SPEED
	else:
		moving = false
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if abs(velocity) > Vector2.ZERO:
		cam.global_position = lerp(cam.global_position, global_position, 0.2)
	
	if global_position.y > $"../PlayerCamera".limit_bottom:
		kill()
		await get_tree().process_frame
	
	move_and_slide()
	
	if is_on_floor() != was_on_floor:
		coyote_time.start()
		falling = false


func _on_coyote_time_timeout() -> void:
	falling = true


func _on_dash_time_timeout() -> void:
	$Hurtbox.set_collision_mask_value(3, true)
	dashing = false


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Hitbox":
		kill()
		area.owner.queue_free()
		await get_tree().process_frame


func _on_rest_timer_timeout() -> void:
	$Sprite.play("rest")


func _on_climbbox_body_entered(body: Node2D) -> void:
	if body is TileMapLayer and not tired:
		can_climb = true


func _on_climbbox_body_exited(body: Node2D) -> void:
	if body is TileMapLayer:
		can_climb = false


func _on_climb_limit_timeout() -> void:
	can_climb = false
	tired = true


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		sfx.play("death")
		death.emit()
		queue_free()
		$"../Antiplayer".queue_free()
