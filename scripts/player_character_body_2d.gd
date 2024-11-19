extends CharacterBody2D

class_name Player

@export var speed = 300.0
@export var jump_velocity = -400.0
@export var attack_time = 0.7

var health = 50
@export var max_health = 50
@export var health_min = 1

var continues := 3 

# Default Player spawn position
var spawn_point: Vector2 = Vector2(100, 100)  

signal player_freed

@onready var ap = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var cs2D = $Sprite2D/WeaponArea2D/CollisionShape2D
@onready var weaponArea = $Sprite2D/WeaponArea2D
@onready var timer: Timer = $Timer

func _ready():
	add_to_group("Player")
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	timer.connect("timeout", Callable(self, "_on_timeout"))

#To make it move.
func _physics_process(delta: float) -> void:
	if !$MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		return
	
	if not timer.is_stopped():
		return
		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Get the input direction and handle the movement/deceleration.
	var horizontal_direction := Input.get_axis("move_left", "move_right")
	if horizontal_direction:
		velocity.x = horizontal_direction * speed
		sprite.flip_h = (horizontal_direction == -1)
		weaponArea.scale.x = -1 if horizontal_direction == -1 else 1
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	update_animations(horizontal_direction)

func update_animations(horizontal_direction):
	if is_on_floor():
		if horizontal_direction == 0:
			if !isAttacking():
				ap.play("idle")
		else:
			if !isAttacking():
				ap.play("run")
	else:
		if velocity.y < 0:
			if !isAttacking():
				ap.play("jump")
		elif velocity.y > 0:
			if !isAttacking():
				ap.play("fall")
				
	if Input.is_action_just_pressed("attack") and is_on_floor():
		ap.play("attack")
		start_action_cooldown()

func isAttacking():
	return ap.current_animation == "attack"

func start_action_cooldown():
	timer.wait_time = attack_time
	timer.one_shot = true
	disable_input()
	timer.start()

func disable_input():
	set_process_input(false)

func enable_input():
	set_process_input(true)

func _on_timeout():
	enable_input()
	
func deactivate_camara():
	$Camera2D.enabled = false
	
func add_name(name):
	$Name.text = name
	
func take_damage(amount: int):
	print("Player: take_damage")
	health -= amount
	if health <= 0:
		health = 0
		die()

func die():
	$Camera2D.get_parent().hide()
	print("Player: the player has died! :(")
	ap.play("death")
	disable_input()
	continues -= 1

	if continues > 0:
		await get_tree().create_timer(2.0).timeout
		respawn()
	else:
		print("Game Over: No continues left!")
		emit_signal("player_freed")  # Notify other nodes
		queue_free()
		#emit_signal("game_over")

func respawn():
	print("Player: Respawning...")
	health = max_health
	position = spawn_point
	$Camera2D.make_current()  # Detach the camera
	$Camera2D.get_parent().show()  # Ensure the camera's parent node is visible
	enable_input()
	show()

func _on_area_entered(area):
	print("Player: _on_area_entered")
