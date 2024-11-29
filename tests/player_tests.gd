extends Node

# Load the Player scene for testing
const PLAYER_SCENE = "res://player_character_body_2d.tscn"

# Player instance for testing
var player: Player

func _ready():
	print("Running tests...")
	# Load the player scene
	var player_scene = preload(PLAYER_SCENE)
	player = player_scene.instantiate()
	add_child(player)  # Add the player to the scene tree for testing
	
	# Run the tests
	run_tests()

func run_tests():
	# Run each test method
	test_take_damage()
	test_death()
	test_respawn()

	print("All tests completed!")
	get_tree().quit()

# Test Cases
func test_take_damage():
	print("Running: test_take_damage")

	player.health = 50
	player.take_damage(10)
	assert(player.health == 40, "Health did not reduce correctly")
	
	# Test death logic
	player.health = 1
	player.take_damage(10)
	assert(player.is_dead, "Player did not die when health dropped to zero")

	print("Passed: test_take_damage")

func test_death():
	print("Running: test_death")

	# Simulate death
	player.die()
	assert(player.is_dead, "Player did not die")

func test_respawn():
	print("Running: test_respawn")

	# Simulate death
	player.die()
	assert(player.is_dead, "Player did not die")

	# Respawn player
	player.respawn()
	assert(not player.is_dead, "Player did not respawn")
	assert(player.health == player.max_health, "Health did not reset on respawn")
	assert(player.position == player.spawn_point, "Position did not reset on respawn")

	print("Passed: test_respawn")
