extends Node2D

signal level_compleated(level_name)
@export var next_level: PackedScene
var players_ready = {}

func _on_area_2d_body_entered(body):
	add_name.rpc(body.name)

@rpc("any_peer", "call_local")
func add_name(player_name):
	print("DEBUG: add_name in LevelTransition...")
	
	# Ensure GameManager is valid
	if GameManager == null or GameManager.players == null:
		print("ERROR: GameManager or players dictionary is null!")
		return
	
	players_ready[player_name] = null
	if players_ready.size() == GameManager.players.size():
		print("DEBUG: Level transition...")
		print("DEBUG: next level path: ", next_level.get_path())
		level_compleated.emit(next_level.get_path())
		
@rpc("any_peer", "call_local")
func remove_name(player_name):
	players_ready.erase(player_name)

func _on_area_2d_body_exited(body):
	add_name.rpc(body.name)
