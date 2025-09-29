extends CharacterBody2D
class_name PlayerController

# --- MOVEMENT PARAMETERS ---
@export var speed: float = 200 ## Horizontal speed (pixels/sec)
@export_range(0.1, 1.0, 0.01) var air_speed_multiplier: float = 0.75 ## Fraction of speed in the air
@export var jump_height: float = 75.0 ## Jump height (pixels)
@export_range(0.0, 10, 0.1, "or_greater") var jump_duration: float = 0.5 ## Time to reach jump apex (sec)
@export_range(0.0, 20.0, 1.0) var air_lerp_factor: float = 3.0  ## How fast horizontal speed transitions in the air
@export_range(0.0, 0.25, 0.01) var coyote_time: float = 0.1 ## Time after leaving a platform that jump is still possible (sec)
@export_range(0.0, 0.25, 0.01) var jump_buffer_time: float = 0.1  ## Time before landing to buffer jump input
@export var max_fall_speed: float = 1000.0 ## Maximum downward speed (pixels/sec)

# --- INTERNAL STATE ---
var gravity: float
var jump_force: float
var speed_multiplier: float = 1.0 # Smoothed horizontal speed
var coyote_timer: float = 0.0 # Timer for coyote time
var jump_buffer_timer: float = 0.0 # Tracks remaining buffered jump time
var facing_direction: float = 1.0 # 1.0 = right, -1.0 = left

func _ready() -> void:
	# Pre-calculate gravity and jump force for desired jump height/duration
	gravity = (8.0 * jump_height) / (jump_duration * jump_duration)
	jump_force = -(4.0 * jump_height) / jump_duration

func _physics_process(delta: float) -> void:
	var on_floor = is_on_floor()

	_update_timers(delta, on_floor)
	_apply_gravity(delta, on_floor)
	_handle_horizontal_movement(delta, on_floor)
	_handle_jump()

	move_and_slide()

# --- HELPER FUNCTIONS ---

func _update_timers(delta: float, on_floor: bool) -> void:
	# Update coyote timer, jump buffer timer each frame
	if on_floor:
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

	jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

func _apply_gravity(delta: float, on_floor: bool) -> void:
	if not on_floor:
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)
	elif velocity.y > 0:
		velocity.y = 0

func _handle_horizontal_movement(delta: float, on_floor: bool) -> void:
	# Smoothly adjust speed multiplier based on whether on ground or in air
	var target_speed_multiplier = 1.0 if on_floor else air_speed_multiplier
	speed_multiplier = lerp(speed_multiplier, target_speed_multiplier, 1.0 - exp(-air_lerp_factor * delta))   

	var direction = Input.get_axis("ui_left", "ui_right") 
	var target_velocity_x = direction * speed * speed_multiplier

	velocity.x = target_velocity_x

	_update_facing_direction(direction)

func _handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time

	if jump_buffer_timer > 0.0 and _can_jump():
		_perform_jump()

func _can_jump() -> bool:
	return coyote_timer > 0.0

func _perform_jump() -> void:
	velocity.y = jump_force
	jump_buffer_timer = 0.0
	coyote_timer = 0.0

func _update_facing_direction(input_direction: float) -> void:
	if input_direction != 0:
		facing_direction = sign(input_direction)
