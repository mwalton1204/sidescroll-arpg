extends CharacterBody2D

# --- MOVEMENT PARAMETERS ---
@export var speed: float = 200 ## Horizontal speed (pixels/sec)
@export_range(0.1, 1.0, 0.01) var air_speed_multiplier: float = 0.75 ## Fraction of speed in the air
@export var jump_height: float = 75.0 ## Jump height (pixels)
@export var jump_duration: float = 0.5 ## Time to reach jump apex (sec)
@export_range(0.0, 20.0, 1.0) var air_lerp_factor: float = 3.0  ## How fast horizontal speed transitions in the air
@export_range(0.0, 0.25, 0.01) var coyote_time: float = 0.1 ## Time after leaving a platform that jump is still possible (sec)
@export_range(0.0, 1.0, 0.01) var jump_buffer_time: float = 0.1  ## Time before landing to buffer jump input
@export var max_jumps: int = 1 ## Maximum number of jumps (1 = single jump, 2 = double jump, etc.)

# --- INTERNAL STATE ---
var gravity: float
var jump_force: float
var speed_multiplier: float = 1.0 # Smoothed horizontal speed
var coyote_timer: float = 0.0 # Timer for coyote time
var jump_buffer_timer: float = 0.0 # Tracks remaining buffered jump time
var jump_count: int = 0 # Tracks number of jumps used

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
	# Reset coyote timer and jump count if on floor
	if on_floor:
		coyote_timer = coyote_time
		jump_count = 0
	# Countdown coyote timer if in air
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

	# Countdown jump buffer
	jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

func _apply_gravity(delta: float, on_floor: bool) -> void:
	# Apply gravity if not on floor
	if not on_floor:
		velocity.y += gravity * delta

func _handle_horizontal_movement(delta: float, on_floor: bool) -> void:
	# Smoothly interpolate speed_multiplier toward target
	var target_speed_multiplier = 1.0 if on_floor else air_speed_multiplier
	speed_multiplier += (target_speed_multiplier - speed_multiplier) * air_lerp_factor * delta

	# Apply horizontal input
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed * speed_multiplier

func _handle_jump() -> void:
	# Check for jump input and perform jump if possible
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time

	if jump_buffer_timer > 0 and _can_jump():
		_perform_jump()

func _can_jump() -> bool:
	# Check if jump is possible based on current state
	if (coyote_timer > 0) and jump_count < max_jumps: # Ground jump
		return true
	if not is_on_floor() and jump_count > 0 and jump_count < max_jumps: # Air jumps
		return true
	return false

func _perform_jump() -> void:
	# Execute jump
	velocity.y = jump_force
	jump_buffer_timer = 0
	jump_count += 1
	coyote_timer = 0
