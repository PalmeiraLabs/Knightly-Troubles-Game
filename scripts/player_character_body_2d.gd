extends CharacterBody2D

@export var speed = 300.0
@export var jump_velocity = -400.0

@onready var ap = $AnimationPlayer
@onready var sprite = $Sprite2D
var is_attacking: bool = false

func _ready():
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())

#To make it move.
func _physics_process(delta: float) -> void:
	if !$MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		
	if Input.is_action_just_pressed("attack") and is_on_floor():
		self.is_attacking = true

	# Get the input direction and handle the movement/deceleration.
	var horizontal_direction := Input.get_axis("move_left", "move_right")
	if horizontal_direction:
		velocity.x = horizontal_direction * speed
		sprite.flip_h = (horizontal_direction == -1)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	
	update_animations(horizontal_direction)


func update_animations(horizontal_direction):
	if !self.is_attacking:
		if is_on_floor():
			if horizontal_direction == 0:
				ap.play("idle")
			else:
				ap.play("run")
		else:
			if velocity.y < 0:
				ap.play("jump")
			elif velocity.y > 0:
				ap.play("fall")
	else:
		ap.play("attack")
		self.is_attacking = false
	
func deactivate_camara():
	$Camera2D.enabled = false
	
func add_name(name):
	$Name.text = name

"""
extends CharacterBody2D

@export var speed = 300.0
@export var jump_velocity = -400.0

@onready var ap = $AnimationPlayer
@onready var sprite = $Sprite2D

func _ready():
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())

#To make it move.
func _physics_process(delta: float) -> void:
	var is_attacking: bool = false

	if !$MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		
	if Input.is_action_just_pressed("attack") and is_on_floor():
		is_attacking = true

	# Get the input direction and handle the movement/deceleration.
	var horizontal_direction := Input.get_axis("move_left", "move_right")
	if horizontal_direction:
		velocity.x = horizontal_direction * speed
		sprite.flip_h = (horizontal_direction == -1)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	
	update_animations(horizontal_direction, is_attacking)


func update_animations(horizontal_direction, is_attacking):
	if !is_attacking:
		if is_on_floor():
			if horizontal_direction == 0:
				ap.play("idle")
			else:
				ap.play("run")
		else:
			if velocity.y < 0:
				ap.play("jump")
			elif velocity.y > 0:
				ap.play("fall")
	else:
		ap.play("attack")
	
func deactivate_camara():
	$Camera2D.enabled = false
	
func add_name(name):
	$Name.text = name
"""
