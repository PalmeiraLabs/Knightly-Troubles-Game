extends Node

# Global object
# It is always accesible

var players = {}
var current_player

var ready_to_next_level_players = {}


@rpc("any_peer")
func player_add_ready_next_level(player_id):
	pass
	
@rpc("any_peer")
func player_remove_ready_next_level(player_id):
	pass
