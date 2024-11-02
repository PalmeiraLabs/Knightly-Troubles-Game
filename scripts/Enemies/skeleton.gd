extends CharacterBody2D

class_name SkeletonEnemy

@export var idle_speed = 10
@export var tracking_speed = 60
const gravity = 900

var health = 10
@export var max_health = 10
@export var health_min = 0

var dead: bool = false
var is_chasing_player: bool = false
var taking_damage: bool = false
var is_dealing_damage: bool = false
var direction : Vector2
var is_roaming: bool = false

@export var damage_dealt = 1
@export var knockback = 2

var tracked_player : CharacterBody2D = null

var facing_right: bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	$DirectionTimer.start()
	health = max_health


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_dealing_damage:
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	if is_chasing_player and !is_dealing_damage:
		if position.distance_to(tracked_player.position) < 40:
			is_dealing_damage = true
			velocity = Vector2.ZERO
			
		else:
			var dir_to_player = position.direction_to(tracked_player.position)
			velocity.x = dir_to_player.x * tracking_speed
	else:
		velocity.x = direction.x * idle_speed
	handle_animation()
	move_and_slide()

func _on_direction_timer_timeout():
	if !is_chasing_player:
		direction = choose([Vector2.LEFT, Vector2.RIGHT, Vector2.ZERO])
		velocity.x = 0
		
func handle_animation():
	var anim_sprite = $AnimatedSprite2D
	if !dead and !taking_damage and !is_dealing_damage and velocity == Vector2.ZERO:
		anim_sprite.play("idle")
	if !dead and !taking_damage and !is_dealing_damage and velocity != Vector2.ZERO:
		anim_sprite.play("walk")
		if velocity.x < 0 and facing_right:
			self.scale.x *= -1.0
			facing_right = false
		elif velocity.x > 0 and !facing_right:
			self.scale.x *= -1.0
			facing_right = true
	
	if !dead and is_dealing_damage:
		anim_sprite.play("attack")
		$Hitbox/AttackHitbox.disabled = false
		await get_tree().create_timer(1.5).timeout
		$Hitbox/AttackHitbox.disabled = true
		is_dealing_damage = false
	
	if !dead and taking_damage and !is_dealing_damage:
		anim_sprite.play("hit")
		await get_tree().create_timer(0.6).timeout
	
func choose(array):
	array.shuffle()
	return array.front()

func _on_detection_area_body_entered(body):
	is_chasing_player = true
	tracked_player = body
