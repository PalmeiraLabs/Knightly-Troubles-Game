extends Node2D

signal level_compleated(level_name)
@export var next_level: PackedScene
var players_ready = {}

func _on_area_2d_body_entered(body):
	add_name.rpc(body.name)

@rpc("any_peer", "call_local")
func add_name(player_name):
	players_ready[player_name] = null
	if players_ready.size() == GameManager.players.size():
		level_compleated.emit(next_level.get_path())
		

@rpc("any_peer", "call_local")
func remove_name(player_name):
	players_ready.erase(player_name)

func _on_area_2d_body_exited(body):
	add_name.rpc(body.name)
