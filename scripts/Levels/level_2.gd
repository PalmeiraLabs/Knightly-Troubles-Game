class_name Level2 extends Node2D

const GAME_ENDING_SCENE = "res://scenes/Menus/game_ending.tscn"
signal level_compleated(level_name)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_level_transition_level_compleated(next_level):
	print("DEBUG: level 2 completed...")
	
	next_level = GAME_ENDING_SCENE
	
	if next_level == GAME_ENDING_SCENE:
		print("DEBUG: next_level == GAME_ENDING_SCENE in Level 2...")
		self.replace_all_scenes(GAME_ENDING_SCENE)
	else:
		print("DEBUG: next_level != GAME_ENDING_SCENE in Level 2...")
		level_compleated.emit(next_level)

func addScene(sceneName):
	print("DEBUG: Adding scene... ", sceneName)
	var scene = load(sceneName).instantiate()
	get_tree().root.add_child(scene)
	self.hide()

func replace_all_scenes(new_scene_path: String):
	# Remove all existing scenes
	var root = get_tree().root
	for child in root.get_children():
		child.queue_free()
	# Add the new scene
	var new_scene = load(new_scene_path).instantiate()
	root.add_child(new_scene)
