extends CharacterBody2D

class_name Player

const GAME_OVER_SCENE = "res://scenes/Menus/game_over.tscn"

@export var speed = 300.0
@export var jump_velocity = -400.0
@export var attack_time = 0.7

var health = 50
@export var max_health = 50
@export var health_min = 1

var continues := 2
var is_dead_forever := false
var is_dead := false

# Default Player spawn position (after dying)
var spawn_point: Vector2 = Vector2(100, 100)  

signal player_freed

@onready var ap = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var cs2D = $Sprite2D/WeaponArea2D/CollisionShape2D
@onready var weaponArea = $Sprite2D/WeaponArea2D
@onready var timer: Timer = $Timer
@onready var healthProgressBar: ProgressBar = $HealthProgressBar
@onready var continuesLabel: Label = $ContinuesLabel
@onready var audioStreamPlayer = $AnimationPlayer/AudioStreamPlayer2D

func _ready():
	add_to_group("Player")
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	timer.connect("timeout", Callable(self, "_on_timeout"))

#To make the player move
func _physics_process(delta: float) -> void:
	if !$MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		return

	if not timer.is_stopped():
		return

	if is_dead or is_dead_forever:
		return

	self.set_health_bar()
	self.set_continues_label()

	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration
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
	var animation_to_play = ""
	var flip_h = sprite.flip_h  # Keep track of the current flip state.

	if is_on_floor():
		if horizontal_direction == 0:
			if !isAttacking():
				animation_to_play = "idle"
		else:
			if !isAttacking():
				animation_to_play = "run"
	else:
		if velocity.y < 0:
			if !isAttacking():
				animation_to_play = "jump"
		elif velocity.y > 0:
			if !isAttacking():
				animation_to_play = "fall"

	if Input.is_action_just_pressed("attack") and is_on_floor():
		animation_to_play = "attack"
		start_action_cooldown()

	if horizontal_direction != 0:
		flip_h = horizontal_direction == -1

	if animation_to_play != "" or sprite.flip_h != flip_h:
		# Send the animation and flip state to the other peer
		rpc("set_animation_and_flip", animation_to_play, flip_h)
		# Apply the animation locally 
		if animation_to_play != "":
			ap.play(animation_to_play)
		sprite.flip_h = flip_h

@rpc("call_remote", "any_peer", "reliable")
func set_animation_and_flip(animation_name: String, flip_h: bool):
	# Synchronize animation and the flip state
	if ap.current_animation != animation_name:
		ap.play(animation_name)
	sprite.flip_h = flip_h

@rpc("call_remote", "any_peer", "reliable")
func set_animation(animation_name: String):
	ap.play(animation_name)

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
	print("Player taking damage...")
	if is_dead:
		return
	
	health -= amount
	health = max(0, health)

	# Synchronize the player health across the network
	rpc("sync_health", health)  # Sync health across peers
	set_health_bar()

	if health == 0:
		die()

func die():
	if is_dead_forever or is_dead:
		return

	is_dead = true
	
	_play_death_effect()
	
	# Play death effect and wait for it to finish
	await _play_death_animation()

	disable_input()
	$Camera2D.get_parent().hide()

	if continues > 0:
		continues -= 1
		self.set_continues_label()
		print("Respawning... Continues left:", continues)
		await get_tree().create_timer(2.0).timeout
		respawn()
	else:
		print("DEBUG: Else condition.. player die! ...")
		present_game_over_scene.rpc()

@rpc("any_peer","call_local")
func present_game_over_scene():
	get_tree().call_group("players", "kill_all_players")
	
func kill_all_players():
	print("Game Over: No continues left!")
	emit_signal("player_freed")
	is_dead_forever = true
	remove_player()
	addScene(GAME_OVER_SCENE)
	
	
func remove_player():
	print("Removing player" )
	self.queue_free()

func addScene(sceneName):
	if $MultiplayerSynchronizer.is_multiplayer_authority():
		var scene = load(sceneName).instantiate()
		get_tree().root.add_child(scene)
		self.hide()

func respawn():
	print("Player: Respawning...")

	is_dead = false
	health = max_health
	rpc("sync_health", health)  # Sync health to all peers
	set_health_bar()

	# Reset position and other state
	position = spawn_point
	
	sprite.visible = true
	sprite.modulate = Color(1, 1, 1, 1)  # Reset to fully visible
	
	# Detach the camera
	$Camera2D.make_current()
	
	# Ensure that the camera's parent node is visible
	$Camera2D.get_parent().show()

	enable_input()
	show()
	#ap.play("idle")

func _play_death_effect():
	print("Attempting to play death sound effect...")
	var mp3_stream: AudioStream = load("res://resources/effects/player_dies.mp3")

	if mp3_stream == null:
		print("Error: Failed to load audio file.")
		return

	if not is_instance_valid(audioStreamPlayer):
		print("Error: AudioStreamPlayer2D is missing or invalid.")
		return
		
	# Ensure any previous sound is stopped
	audioStreamPlayer.stop()

	audioStreamPlayer.stream = mp3_stream
	audioStreamPlayer.play()
	print("Death sound effect played successfully.")

func set_continues_label():
	self.continuesLabel.text = str(self.continues)

func set_health_bar():
	self.healthProgressBar.value = self.health

func _on_area_entered(area):
	print("Player: _on_area_entered")

@rpc("any_peer", "reliable")
func sync_health(new_health):
	health = new_health
	set_health_bar()

func _play_death_animation():
	for i in range(100):
		sprite.modulate.a = 1.0 - (i / 100.0)  # Gradually fade out
		await get_tree().create_timer(0.02).timeout  # Delay for smooth transition
	sprite.visible = false
