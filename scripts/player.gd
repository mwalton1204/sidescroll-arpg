"""
TODO: 
	- Finish dash implementation
	- Add dash_distance parameter
	- Modify dash to use distance instead of time
	- Allow dashing from standing still
	- Review dash implementation to ensure that I understand it
	- Allow air dashes toggleable in the inspector
	- Move dash input to custom action
	- Lerp velocity.y back into gravity instead of just instantly reapplying
"""

extends CharacterBody2D

# --- MOVEMENT PARAMETERS ---

@export var speed: float = 200 ## Horizontal speed (pixels/sec)
@export_range(0.1, 1.0, 0.01) var air_speed_multiplier: float = 0.75 ## Fraction of speed in the air
@export var jump_height: float = 75.0 ## Jump height (pixels)
@export_range(0.0, 10, 0.1, "or_greater") var jump_duration: float = 0.5 ## Time to reach jump apex (sec)
@export_range(0.0, 20.0, 1.0) var air_lerp_factor: float = 3.0  ## How fast horizontal speed transitions in the air
@export_range(0.0, 0.25, 0.01) var coyote_time: float = 0.1 ## Time after leaving a platform that jump is still possible (sec)
@export_range(0.0, 1.0, 0.01) var jump_buffer_time: float = 0.1  ## Time before landing to buffer jump input
@export var max_jumps: int = 1 ## Maximum number of jumps (1 = single jump, 2 = double jump, etc.)
@export var max_fall_speed: float = 1000.0 ## Maximum downward speed (pixels/sec)
@export var dash_speed: float = 600.0 ## Dash speed (pixels/sec)
@export var dash_duration: float = 0.2 ## Duration of dash (sec)
@export var dash_cooldown: float = 1.0 ## Cooldown time between dashes (sec)

# --- INTERNAL STATE ---

var gravity: float
var jump_force: float
var speed_multiplier: float = 1.0 # Smoothed horizontal speed
var coyote_timer: float = 0.0 # Timer for coyote time
var jump_buffer_timer: float = 0.0 # Tracks remaining buffered jump time
var jump_count: int = 0 # Tracks number of jumps used
var dash_timer: float = 0.0 # Timer for dash duration
var dash_cooldown_timer: float = 0.0 # Timer for dash cooldown
var is_dashing: bool = false # Whether the player is currently dashing
var dash_direction: int = 0 # -1 = left, 1 = right, 0 = none

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
	_handle_dash(delta, on_floor)

	move_and_slide()

# --- HELPER FUNCTIONS ---

func _update_timers(delta: float, on_floor: bool) -> void:
	# Update coyote timer, jump buffer timer, and jump count each frame
	if on_floor:
		coyote_timer = coyote_time
		jump_count = 0
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

	jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

func _apply_gravity(delta: float, on_floor: bool) -> void:
	# Apply gravity if not on the ground and limit to max fall speed
	if not on_floor:
		velocity.y += gravity * delta
		if velocity.y > max_fall_speed:
			velocity.y = max_fall_speed

func _handle_horizontal_movement(delta: float, on_floor: bool) -> void:
	# Smoothly adjust speed multiplier based on whether on ground or in air
	var target_speed_multiplier = 1.0 if on_floor else air_speed_multiplier
	speed_multiplier = lerp(speed_multiplier, target_speed_multiplier, 1.0 - exp(-air_lerp_factor * delta))   
	
	var direction = Input.get_axis("ui_left", "ui_right") 
	var target_velocity_x = direction * speed * speed_multiplier

	velocity.x = target_velocity_x

func _handle_jump() -> void:
	# Check for jump input and perform jump if possible
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time

	if jump_buffer_timer > 0 and _can_jump():
		_perform_jump()

func _can_jump() -> bool:
	# Determine if a jump can be performed based on timers and jump count
	if (coyote_timer > 0) and jump_count < max_jumps: # Ground jump
		return true
	if not is_on_floor() and jump_count > 0 and jump_count < max_jumps: # Air jump
		return true
	return false

func _perform_jump() -> void:
	# Execute jump and update timers/counters
	velocity.y = jump_force
	jump_buffer_timer = 0
	jump_count += 1
	coyote_timer = 0

func _handle_dash(delta: float, on_floor: bool) -> void:
	# Handle dash input, duration, and cooldown
	dash_cooldown_timer = max(dash_cooldown_timer - delta, 0.0)

	# Start dash if input is detected and not on cooldown
	if Input.is_action_just_pressed("ui_down") and not is_dashing and dash_cooldown_timer <= 0:
		var input_direction = Input.get_axis("ui_left", "ui_right")
		if input_direction != 0:
			is_dashing = true
			dash_timer = dash_duration
			dash_cooldown_timer = dash_cooldown
			dash_direction = sign(input_direction)
			velocity = Vector2(dash_direction * dash_speed, 0)
			return

	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_direction * dash_speed
		velocity.y = 0 # Neutralize vertical movement during dash

		if dash_timer <= 0:
			is_dashing = false
			dash_direction = 0
