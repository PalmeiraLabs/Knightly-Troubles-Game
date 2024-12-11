extends Node2D

signal level_compleated(level_name)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_level_transition_level_compleated(next_level):
	print("DEBUG: level 2 completed...")
	level_compleated.emit(next_level)
