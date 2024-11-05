# Extends the functionality of a 2D node for multiplayer setup
extends Node2D

@onready var button_host = $HostButton
@onready var button_join = $JoinButton
@onready var button_play = $PlayButton

# The scene file to be loaded when starting the game
const INITIAL_SCENE = "res://world.tscn"

# Server IP for LAN connection
@export var address = "192.168.1.36" 
@export var port = 8900   # Port for server and client
@export var max_clients = 2  # Max clients that can connect
var peer  # Holds the ENet multiplayer peer (server or client)

# Called when the node is added to the scene. 
# It sets up signal connections for multiplayer events.
func _ready():
	# Connect signals for handling multiplayer events
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	
	self.disable_button(button_play)

# Triggered when "Play" button is pressed by user
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
	
	self.addScene(INITIAL_SCENE)
	#self.hide()

# Loads the scene and creates an instance of it
func addScene(sceneName):
	var scene = load(sceneName).instantiate()
	get_tree().root.add_child(scene)
	self.hide()
	
func disable_button(theButton):
	theButton.disabled = true
	theButton.focus_mode = Control.FOCUS_NONE

func enable_button(theButton):
	theButton.disabled = false
	theButton.focus_mode = Control.FOCUS_ALL

func peer_connected(id):
	self.enable_button(button_play)
	print("Player Connected: " + str(id))

# Called when a player disconnects from the server
# The id parameter is the unique identifier of the disconnected peer (player)
func peer_disconnected(id):
	self.disable_button(button_play)
	print("Player Disconnected: " + str(id))

# Called only on the client when it successfully connects to the server
func connected_to_server():
	self.enable_button(button_play)
	print("Connected to server")
	# Send the player's name and unique ID to the server via an RPC
	send_player_information.rpc_id(1, $PlayerName.text, multiplayer.get_unique_id())
	GameManager.current_player = multiplayer.get_unique_id()

# Called only on the client when the connection to the server fails
func connection_failed():
	self.disable_button(button_play)
	print("Connection Failed")

# This RPC function sends player information (name and ID) to all peers in the network
@rpc("any_peer")
func send_player_information(name, id):
	# If the GameManager does not already have a record for this player ID, add it
	if !GameManager.players.has(id):
		GameManager.players[id] = { "name": name, "id": id }
	# If this peer is the server, broadcast the player information to all connected clients		
	if multiplayer.is_server():
		for i in GameManager.players:
			send_player_information.rpc(GameManager.players[i].name, i)

# Host Setup
# Triggered when the "Host" button is pressed by the user
# This function sets up the server
func _on_host_button_button_down():
	self.disable_button(button_join)
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, max_clients)
	if error != OK:
		print("Error creating server: " + str(error))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer
	send_player_information($PlayerName.text, multiplayer.get_unique_id())
	GameManager.current_player = multiplayer.get_unique_id()
	print("Server is live, waiting for players")

# Join Setup
# Triggered when the "Join" button is pressed by the user
# This function sets up the client to join a server
func _on_join_button_button_down():
	self.disable_button(button_host)
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)  # Ensure `address` is set to host’s IP on LAN
	
	# Apply data compression to reduce bandwidth usage (both hosts must have matching compression settings)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	# Set the multiplayer peer to the client peer
	multiplayer.multiplayer_peer = peer
	print("Attempting connection to server at " + address + ":" + str(port))
