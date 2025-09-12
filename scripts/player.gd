extends CharacterBody2D

# -- Movement parameters --
@export var speed : float = 200
@export var jump_velocity : float = -400
@export var gravity : float = 900

func _physics_process(delta: float) -> void:
	# Reset horizontal movement each frame
	velocity.x = 0

	# -- Handle input --
	if Input.is_action_pressed("ui_right"):
		velocity.x += speed
	if Input.is_action_pressed("ui_left"):
		velocity.x -= speed

	# -- Apply gravity --
	if not is_on_floor():
		velocity.y += gravity * delta

	# -- Jump --
	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = jump_velocity

	# -- Move the character --
	move_and_slide()
