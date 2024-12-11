extends Node2D

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
	if next_level == GAME_ENDING_SCENE:
		self.addScene(GAME_ENDING_SCENE)
	else:
		level_compleated.emit(next_level)

func addScene(sceneName):
	var scene = load(sceneName).instantiate()
	get_tree().root.add_child(scene)
	self.hide()
