extends CharacterBody2D

@export var speed : float = 200
@export var air_speed_factor : float = 0.75       # fraction of speed while in air
@export var jump_height : float = 85           # maximum jump height in pixels
@export var jump_duration_factor : float = 0.6  # scales total jump time
@export var air_lerp_factor : float = 0.2       # smoothing factor for horizontal speed in air

func _physics_process(delta):
	# Determine input direction
	var input_direction = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var target_speed = speed * input_direction

	# Reduce target speed if in air
	if not is_on_floor():
		target_speed *= air_speed_factor
		# Smoothly interpolate from current x velocity to target
		velocity.x = lerp(velocity.x, target_speed, air_lerp_factor)
	else:
		# On the ground, move directly
		velocity.x = target_speed

	# Compute effective gravity and jump velocity to preserve apex
	var time_to_apex = 0.5 * sqrt(2 * jump_height / 100) * jump_duration_factor
	var effective_gravity = 2 * jump_height / (time_to_apex * time_to_apex)
	var jump_velocity_corrected = effective_gravity * time_to_apex

	# Jump
	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = -jump_velocity_corrected  # up is negative in Godot

	# Apply gravity
	if not is_on_floor():
		velocity.y += effective_gravity * delta

	# Move the character
	move_and_slide()
