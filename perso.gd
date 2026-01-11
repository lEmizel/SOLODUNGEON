extends CharacterBody2D

var current_cell: Vector2i = Vector2i.ZERO
var is_moving: bool = false

@export var move_speed: float = 0.15  # Durée du déplacement
@export var fade_duration: float = 0.1  # Durée du fondu

const DIRECTIONS_CARDINAL = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT
]


func _ready() -> void:
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


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_moving:
				_handle_click(event.position)


func _handle_click(mouse_pos: Vector2) -> void:
	var world_pos = get_canvas_transform().affine_inverse() * mouse_pos
	var target_cell = DungeonManager.world_to_grid(world_pos)
	var diff = target_cell - current_cell
	
	if diff in DIRECTIONS_CARDINAL:
		_try_move(diff)


func _try_move(direction: Vector2i) -> void:
	var target_cell = current_cell + direction
	
	if not DUNGEONREFERENCE.has_room(target_cell):
		return
	
	current_cell = target_cell
	is_moving = true
	
	var target_pos = DungeonManager.grid_to_world(current_cell)
	
	var tween = create_tween()
	
	# 1. Fade out complet
	tween.tween_property(self, "modulate:a", 0.0, fade_duration).set_ease(Tween.EASE_IN)
	
	# 2. Déplacement (invisible)
	tween.tween_property(self, "position", target_pos, move_speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# 3. Fade in complet
	tween.tween_property(self, "modulate:a", 1.0, fade_duration).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(_on_move_finished)


func _on_move_finished() -> void:
	is_moving = false
	DUNGEONREFERENCE.visit_room(current_cell)
