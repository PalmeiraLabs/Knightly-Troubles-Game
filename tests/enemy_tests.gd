extends Node

const ENEMY_SCENE = "res://scenes/Enemies/enemy.tscn"
const MOCK_PLAYER_SCENE = "res://scenes/Player/player_character_body_2d.tscn"

var enemy: Enemy
var mock_player: CharacterBody2D

func _ready():
	print("Running tests...")
	
	var enemy_scene = preload(ENEMY_SCENE)
	enemy = enemy_scene.instantiate()
	add_child(enemy)

	var mock_player_scene = preload(MOCK_PLAYER_SCENE)
	mock_player = mock_player_scene.instantiate()
	mock_player.name = "Player"
	mock_player.add_to_group("Player")
	add_child(mock_player)
	enemy.tracked_player = mock_player
	
	run_tests()

func run_tests():
	test_initial_state()
	test_roaming()
	test_chasing()
	test_attacking()
	test_hurt()

	print("All tests completed!")
	get_tree().quit()

# Test Cases
func test_initial_state():
	print("Running: test_initial_state")

	assert(enemy.health == enemy.max_health, "Health did not initialize to max_health")
	assert(enemy.curr_state == Enemy.State.ROAMING, "Initial state is not ROAMING")
	assert(enemy.velocity == Vector2.ZERO, "Initial velocity is not zero")
	
	print("Passed: test_initial_state")

func test_roaming():
	print("Running: test_roaming")

	enemy.curr_state = Enemy.State.ROAMING
	enemy.direction = Vector2.RIGHT
	enemy._process(0.1)

	assert(enemy.velocity.x == enemy.idle_speed, "Enemy did not move at idle speed in ROAMING state")

	print("Passed: test_roaming")

func test_chasing():
	print("Running: test_chasing")

	enemy.curr_state = Enemy.State.CHASING
	mock_player.position = Vector2(300, 100)
	enemy.position = Vector2(100, 100)
	enemy._process(0.1)
	assert(enemy.velocity.x > 0, "Enemy did not move towards the player in CHASING state")
	print("Passed: test_chasing")

func test_attacking():
	print("Running: test_attacking")

	enemy.curr_state = Enemy.State.CHASING
	enemy.position = mock_player.position + Vector2(30, 0)
	enemy._process(0.1)

	assert(enemy.curr_state == Enemy.State.ATTACKING, "Enemy did not transition to ATTACKING state")
	assert(enemy.velocity == Vector2.ZERO, "Enemy velocity is not zero during ATTACKING state")

	print("Passed: test_attacking")

func test_hurt():
	print("Running: test_hurt")

	enemy.health = 5
	enemy.curr_state = Enemy.State.HURT
	enemy._process(0.1)

	assert(enemy.health == 4, "Enemy health did not decrease in HURT state")
	print("Passed: test_hurt")
