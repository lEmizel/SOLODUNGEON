extends CharacterBody2D

var current_cell: Vector2i = Vector2i.ZERO
var is_moving: bool = false
var move_duration: float = 0.2  # Durée de l'animation

func _ready() -> void:
	# Positionner au centre de la case de départ
	current_cell = Vector2i.ZERO
	position = DungeonManager.grid_to_world(current_cell)


func _process(delta: float) -> void:
	if is_moving:
		return
	
	var direction = Vector2i.ZERO
	
	if Input.is_action_just_pressed("ui_up"):
		direction = Vector2i.UP
	elif Input.is_action_just_pressed("ui_down"):
		direction = Vector2i.DOWN
	elif Input.is_action_just_pressed("ui_left"):
		direction = Vector2i.LEFT
	elif Input.is_action_just_pressed("ui_right"):
		direction = Vector2i.RIGHT
	
	if direction != Vector2i.ZERO:
		_try_move(direction)


func _try_move(direction: Vector2i) -> void:
	var target_cell = current_cell + direction
	
	# Vérifier si la case est valide
	if not DUNGEONREFERENCE.has_room(target_cell):
		return
	
	# Déplacer
	current_cell = target_cell
	is_moving = true
	
	var target_pos = DungeonManager.grid_to_world(current_cell)
	
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, move_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(_on_move_finished)


func _on_move_finished() -> void:
	is_moving = false
	DUNGEONREFERENCE.visit_room(current_cell)
