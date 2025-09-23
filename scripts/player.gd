extends CharacterBody2D

# --- MOVEMENT PARAMETERS ---
@export var speed: float = 200 ## Horizontal speed (pixels/sec)
@export_range(0.1, 1.0, 0.01) var air_speed_multiplier: float = 0.75 ## Fraction of speed in the air
@export var jump_height: float = 75.0 ## Jump height (pixels)
@export var jump_duration: float = 0.5 ## Time to reach jump apex (sec)
@export_range(0.0, 20.0, 1.0) var air_lerp_factor: float = 3.0  ## How fast horizontal speed transitions in the air
@export_range(0.0, 0.25, 0.01) var coyote_time: float = 0.1 ## Time after leaving a platform that jump is still possible (sec)

# --- INTERNAL STATE ---
var gravity: float
var jump_force: float
var speed_multiplier : float = 1.0 # Smoothed horizontal speed
var coyote_timer: float = 0.0 # Timer for coyote time

func _ready() -> void:
	# Pre-calculate gravity and jump force for desired jump height/duration
	gravity = (8.0 * jump_height) / (jump_duration * jump_duration)
	jump_force = -(4.0 * jump_height) / jump_duration

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_horizontal_movement(delta)
	_handle_jump()
	move_and_slide()

# --- HELPER FUNCTIONS ---
func _apply_gravity(delta: float) -> void:
	# Apply gravity if not on floor
	if is_on_floor():
		coyote_timer = coyote_time
		velocity.y = 0.0
	else:
		velocity.y += gravity * delta
		coyote_timer = max(coyote_timer - delta, 0.0)


func _handle_horizontal_movement(delta: float) -> void:
	# Smoothly interpolate speed_multiplier toward target
	var target_speed_multiplier = 1.0 if is_on_floor() else air_speed_multiplier
	speed_multiplier += (target_speed_multiplier - speed_multiplier) * air_lerp_factor * delta

	# Apply horizontal input
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed * speed_multiplier

func _handle_jump() -> void:
	# Single jump
	if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or coyote_timer > 0.0):
		velocity.y = jump_force
		coyote_timer = 0.0
