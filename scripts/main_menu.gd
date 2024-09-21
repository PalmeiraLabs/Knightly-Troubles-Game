extends Node2D

const INITIAL_SCENE = "res://world.tscn"

@export var address = "127.0.0.1"
@export var port = 8900
@export var max_clients = 2
var peer

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

func _on_play_button_pressed():
	start_game.rpc()
	
@rpc("any_peer", "call_local")
func start_game():
	var scene = load(INITIAL_SCENE).instantiate()
	get_tree().root.add_child(scene)
	self.hide()

func peer_connected(id):
	# Called on server and client
	# Called when player connects
	print("Player Connected " + str(id))
	
func peer_disconnected(id):
	# Called on server and client
	# Called when player disconnects
	print("Player Disconnected " + str(id))
	
func connected_to_server():
	# Called only on client
	# Called when connected to server
	print("Connected to server")
	
func connection_failed():
	# Called only on client
	# Called when connected to server
	print("Connection Failed")

func _on_host_button_button_down():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, max_clients)
	if error != OK:
		print("Error creating server: " + str(error))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		
	multiplayer.multiplayer_peer = peer
	print("Waiting for players")
	
func _on_join_button_button_down():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer
	
	pass # Replace with function body.
