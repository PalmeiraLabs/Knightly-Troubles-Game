# This script extends the functionality of a 2D node
extends Node2D

# The scene file to be loaded when starting the game
const INITIAL_SCENE = "res://world.tscn"

# These variables are exported so they can be configured from the Godot editor
@export var address = "127.0.0.1"  # The server IP address (default is localhost for testing)
@export var port = 8900  # The port used for server and client connections
@export var max_clients = 2  # Maximum number of clients that can connect to the server
var peer  # Variable to hold the ENet multiplayer peer (server or client)

# Called when the node is added to the scene. 
# It sets up signal connections for multiplayer events.
func _ready():
	# Connect multiplayer signals to corresponding functions for handling connection events
	multiplayer.peer_connected.connect(peer_connected)  # Called when a player connects
	multiplayer.peer_disconnected.connect(peer_disconnected)  # Called when a player disconnects
	multiplayer.connected_to_server.connect(connected_to_server)  # Called when the client connects to the server
	multiplayer.connection_failed.connect(connection_failed)  # Called if the client fails to connect to the server

# Triggered when the "Play" button is pressed by the user
func _on_play_button_pressed():
	# Calls the start_game function via an RPC (Remote Procedure Call)
	# This allows the function to be executed across the network
	start_game.rpc()

# This is an RPC function that can be called by any peer in the network
# It is also executed locally on the peer that calls it
@rpc("any_peer", "call_local")
func start_game():
	# Stops any audio playback (assumes there is an AudioStreamPlayer in the scene)
	$AudioStreamPlayer.stop()
	
	# Loads the initial scene and creates an instance of it
	var scene = load(INITIAL_SCENE).instantiate()
	
	# Adds the new scene as a child of the root node of the scene tree
	get_tree().root.add_child(scene)
	
	# Hides the current UI (likely the menu)
	self.hide()

# Called when a player connects to the server
# The id parameter is the unique identifier of the connected peer (player)
func peer_connected(id):
	print("Player Connected " + str(id))

# Called when a player disconnects from the server
# The id parameter is the unique identifier of the disconnected peer (player)
func peer_disconnected(id):
	print("Player Disconnected " + str(id))  # Log that a player disconnected

# Called only on the client when it successfully connects to the server
func connected_to_server():
	print("Connected to server")  # Log that the client successfully connected to the server
	
	# Send the player's name and unique ID to the server via an RPC
	send_player_information.rpc_id(1, $PlayerName.text, multiplayer.get_unique_id())
	
	GameManager.current_player = multiplayer.get_unique_id()

# Called only on the client when the connection to the server fails
func connection_failed():
	print("Connection Failed")

# This RPC function sends player information (name and ID) to all peers in the network
@rpc("any_peer")
func send_player_information(name, id):
	# If the GameManager does not already have a record for this player ID, add it
	if !GameManager.players.has(id):
		GameManager.players[id] = {
			"name" : name,
			"id" : id
		}
	
	# If this peer is the server, broadcast the player information to all connected clients
	if multiplayer.is_server():
		for i in GameManager.players:
			send_player_information.rpc(GameManager.players[i].name, i)

# Triggered when the "Host" button is pressed by the user
# This function sets up the server
func _on_host_button_button_down():
	peer = ENetMultiplayerPeer.new()  # Create a new ENet multiplayer peer for hosting the server
	
	# Attempt to create a server on the specified port with a maximum number of clients
	var error = peer.create_server(port, max_clients)
	
	# If there was an error creating the server, log the error and return
	if error != OK:
		print("Error creating server: " + str(error))
		return
	
	# Apply data compression to reduce bandwidth usage (both hosts must have matching compression settings)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	# Set the multiplayer peer to the server peer
	multiplayer.multiplayer_peer = peer
	
	# Send the host's player information to all connected peers
	send_player_information($PlayerName.text, multiplayer.get_unique_id())
	
	# Set the host's unique ID in the GameManager
	GameManager.current_player = multiplayer.get_unique_id()
	
	print("Waiting for players")  # Log that the server is waiting for players to connect

# Triggered when the "Join" button is pressed by the user
# This function sets up the client to join a server
func _on_join_button_button_down():
	# Create a new ENet multiplayer peer for joining as a client
	peer = ENetMultiplayerPeer.new()  
	
	# Attempt to connect to the server at the specified address and port
	peer.create_client(address, port)
	
	# Apply data compression (both client and server must have matching compression settings)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	# Set the multiplayer peer to the client peer
	multiplayer.multiplayer_peer = peer
