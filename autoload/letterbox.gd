extends Node

const RESOLUTIONS : Array[Vector2i] = [
	Vector2i(640, 480),
	Vector2i(800, 600),
	Vector2i(1024, 768),
	Vector2i(1280, 720),
	Vector2i(1280, 800),
	Vector2i(1366, 768),
	Vector2i(1440, 900),
	Vector2i(1600, 900),
	Vector2i(1680, 1050),
	Vector2i(1920, 1080),
	Vector2i(1920, 1200),
	Vector2i(2560, 1440),
	Vector2i(2560, 1600),
	Vector2i(3840, 2160),
]

var current_index : int = 9


func _ready() -> void:
	pass


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug1"):
		current_index = max(0, current_index - 1)
		_apply_resolution()
	elif event.is_action_pressed("debug2"):
		current_index = min(RESOLUTIONS.size() - 1, current_index + 1)
		_apply_resolution()


func _apply_resolution() -> void:
	var res = RESOLUTIONS[current_index]
	
	# Changer la taille du viewport root
	get_tree().root.size = res
	
	# Changer la taille de la fenêtre
	DisplayServer.window_set_size(res)
	
	# Centrer la fenêtre
	var screen_size = DisplayServer.screen_get_size()
	var window_pos = (screen_size - res) / 2
	DisplayServer.window_set_position(window_pos)
	
	print("Resolution [", current_index, "]: ", res)
