extends CharacterBody2D

class_name SkeletonEnemy

const idle_speed = 10
const tracking_speed = 60
const gravity = 900

var health = 10
var max_health = 10
var health_min = 0

var dead: bool = false
var is_chasing_player: bool = false
var taking_damage: bool = false
var is_dealing_damage: bool = false
var direction : Vector2
var is_roaming: bool = false

var damage_dealt = 1
var knockback = 2

var tracked_player : CharacterBody2D = null

# Called when the node enters the scene tree for the first time.
func _ready():
	$DirectionTimer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	if is_chasing_player:
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
	if !dead and !taking_damage and !is_dealing_damage and direction == Vector2.ZERO:
		anim_sprite.play("idle")
	if !dead and !taking_damage and !is_dealing_damage and direction != Vector2.ZERO:
		anim_sprite.play("walk")
		if velocity.x < 0:
			anim_sprite.flip_h = true
		elif velocity.x > 0:
			anim_sprite.flip_h = false
	
	if !dead and taking_damage and !is_dealing_damage:
		anim_sprite.play("hit")
		await get_tree().create_timer(0.6).timeout
	
func choose(array):
	array.shuffle()
	return array.front()

func _on_detection_area_body_entered(body):
	is_chasing_player = true
	tracked_player = body
