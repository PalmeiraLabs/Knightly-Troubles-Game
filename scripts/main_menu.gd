extends Node2D

const INITIAL_SCENE = "res://world.tscn"


func _on_play_button_pressed():
	get_tree().change_scene_to_file(INITIAL_SCENE)
