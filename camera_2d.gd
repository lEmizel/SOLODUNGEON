extends Camera2D

var base_viewport_size : Vector2


func _ready() -> void:
	# Attendre que le viewport soit prêt
	await get_tree().process_frame
	
	base_viewport_size = get_viewport_rect().size
	get_tree().root.size_changed.connect(_on_viewport_changed)
	
	make_current()
	print("Camera init: base viewport = ", base_viewport_size)


func _on_viewport_changed() -> void:
	var current_size = get_viewport_rect().size
	print("Camera viewport changed: ", current_size)
