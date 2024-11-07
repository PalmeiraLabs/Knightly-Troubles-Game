extends CharacterBody2D

class_name SkeletonEnemy

@export var idle_speed = 10
@export var tracking_speed = 60
const gravity = 900

var health = 10
@export var max_health = 10
@export var health_min = 1

var direction : Vector2

enum State {ROAMING, CHASING, ATTACKING, HURT, DEAD}

var curr_state : State = State.ROAMING

@export var damage_dealt = 1

var tracked_player : CharacterBody2D = null

var facing_right: bool = true

var in_hurt_animation = false
var in_death_animation = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$DirectionTimer.start()
	health = max_health


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	match curr_state:
		State.DEAD:
			return
		State.ROAMING:
			velocity.x = direction.x * idle_speed
		State.ATTACKING:
			velocity.x = 0
			move_and_slide()
			return
		State.HURT:
			velocity.x = 0
		State.CHASING:
			if position.distance_to(tracked_player.position) < 40:
				curr_state = State.ATTACKING
				velocity = Vector2.ZERO
			else:
				var dir_to_player = position.direction_to(tracked_player.position)
				velocity.x = dir_to_player.x * tracking_speed
				
	handle_animation()
	move_and_slide()

func _on_direction_timer_timeout():
	if curr_state == State.ROAMING:
		direction = choose([Vector2.LEFT, Vector2.RIGHT, Vector2.ZERO])
		velocity.x = 0
		
func handle_animation():
	if curr_state == State.DEAD:
		return
	var anim_sprite = $AnimatedSprite2D
	if curr_state == State.ROAMING or curr_state == State.CHASING:
		if velocity == Vector2.ZERO:
			anim_sprite.play("idle")
		else:
			anim_sprite.play("walk")
		if velocity.x < 0 and facing_right:
			self.scale.x *= -1.0
			facing_right = false
		elif velocity.x > 0 and !facing_right:
			self.scale.x *= -1.0
			facing_right = true
	
	if curr_state == State.ATTACKING:
		anim_sprite.play("attack")
		$Hitbox/AttackHitbox.disabled = false
		await get_tree().create_timer(1.5).timeout
		$Hitbox/AttackHitbox.disabled = true
		curr_state = State.CHASING
	
	if curr_state == State.HURT and !in_hurt_animation:
		if health < health_min:
			curr_state = State.DEAD
			anim_sprite.play("death")
			in_hurt_animation = true
			await get_tree().create_timer(1.4).timeout
			in_hurt_animation = false
			self.set_visible(false)
			self.queue_free()
		
		health = health - 1
		anim_sprite.play("hit")
		in_hurt_animation = true
		await get_tree().create_timer(0.6).timeout
		in_hurt_animation = false
		if tracked_player == null:
			#Safeguard. Should not be posible
			curr_state = State.ROAMING
		else:
			curr_state = State.CHASING
	
func choose(array):
	array.shuffle()
	return array.front()

func _on_detection_area_body_entered(body):
	curr_state = State.CHASING
	tracked_player = body

func _on_hurt_box_body_entered(body):
	curr_state = State.HURT


func _on_hurt_box_area_entered(area):
	curr_state = State.HURT
