extends Node2D

@export var PlayerScene : PackedScene

signal level_compleated(level_name)

# Called when the node enters the scene tree for the first time.
func _ready():
	set_player_spawns()
# For each player in GameManager will assign a spawn location
func set_player_spawns():
	var index = 0
	for i in GameManager.players:
		var current_player = PlayerScene.instantiate()
		current_player.name = str(GameManager.players[i].id)
		current_player.add_name(GameManager.players[i].name)
		add_child(current_player)
		# Deactivate camara if player character is not user's
		if GameManager.current_player != i:
			current_player.deactivate_camara()
		# Iterates through all spawn point nodes in the scene
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			if spawn.name == str(index):
				current_player.global_position = spawn.global_position
		index += 1
		



func _on_level_level_compleated(level_name):
	change_level(level_name)
	
	
func change_level(next_level_name):
	# Removes previous level
	remove_child($Level)
	
	# Creates next level in memory
	var next_level = load(next_level_name).instantiate()
	next_level.name = "Level"
	add_child(next_level)

	# Moves players to the start of the level
	var index = 0
	for i in GameManager.players:
		var curr_player = get_node("%s" % i)
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			if spawn.name == str(index):
				curr_player.global_position = spawn.global_position
		index += 1
