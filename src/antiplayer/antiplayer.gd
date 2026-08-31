extends CharacterBody2D


@export_node_path("CharacterBody2D") var target

const DASH_SPEED = 250.0
const SPEED = 150.0
const JUMP_VELOCITY = -250.0
const DASH_DISTANCE_THRESHOLD = 200.0
const DISTANCE_THRESHOLD = 300.0

@onready var player : CharacterBody2D = get_node(target)
@onready var RNG := RandomNumberGenerator.new()

@onready var navigator: NavigationAgent2D = $Navigator
@onready var wake_delay: Timer = $WakeDelay
@onready var ray_cast: RayCast2D = $RayCast
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var dash_particles: CPUParticles2D = $DashParticles

@onready var kabooie: AnimatedSprite2D = $KABOOIE
@onready var sfx: Node = $"../Effects"

var dashing = false
var awake = false


func _ready() -> void:
	wake_delay.start()


func _process(_delta: float) -> void:
	if not awake:
		return
	
	if velocity.x > 0:
		sprite.play("walk")
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.play("walk")
		sprite.flip_h = true


func _physics_process(_delta: float) -> void:
	if not awake:
		return
	
	navigator.target_position = player.global_position
	var direction = global_position.direction_to(player.global_position)
	ray_cast.target_position = direction * 16
	if !navigator.is_target_reached():
		var locator = to_local(navigator.get_next_path_position()).normalized()
		var distance = global_position.distance_to(player.global_position)
		velocity = locator * SPEED
		
		if distance >= DASH_DISTANCE_THRESHOLD and is_on_floor() and not dashing:
			dashing = true
			$DashTime.start()
		
		if distance >= DISTANCE_THRESHOLD and $RenavigateTimer.is_stopped():
			$RenavigateTimer.start()
		else:
			$RenavigateTimer.stop()
		
		if dashing:
			velocity.x += locator.x * DASH_SPEED
		
		dash_particles.emitting = dashing
		dash_particles.gravity = -direction * Vector2(980, 0)
		
		if global_position.y > get_viewport_rect().size.y:
			awake = false
			$WakeDelay.start()
			return
	
	if ray_cast.is_colliding() and direction.y > 0:
		velocity.y = JUMP_VELOCITY * 1.5
	
	move_and_slide()


func _on_dash_time_timeout() -> void:
	dashing = false


func _on_wake_delay_timeout() -> void:
	velocity = Vector2.ZERO
	global_position = navigator.get_next_path_position()
	sfx.play("kabooie")
	kabooie.play("respawn")


func _on_kabooie_animation_finished() -> void:
	if kabooie.animation == "respawn":
		awake = true
	kabooie.play("default")


func _on_renavigate_timer_timeout() -> void:
	navigator.target_position = player.global_position
