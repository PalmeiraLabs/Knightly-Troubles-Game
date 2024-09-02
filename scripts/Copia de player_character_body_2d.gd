extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

#To make it move.
func _physics_process(delta: float) -> void:
	print("Executing physics process")
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var horizontal_direction := Input.get_axis("move_left", "move_right")
	if horizontal_direction:
		velocity.x = horizontal_direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
