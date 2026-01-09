extends Node

## Autoload : DUNGEONREFERENCE
## Gère l'état des salles et leur affichage

var rooms: Dictionary = {}
var walls: Dictionary = {}
var wall_collisions: Dictionary = {}  # Vector2i -> StaticBody2D

const COLOR_HIDDEN = Color(0, 0, 0, 1.0)
const COLOR_REVEALED = Color(0.5, 0.5, 0.5, 1.0)
const COLOR_VISIBLE = Color(1.0, 1.0, 1.0, 1.0)

const DIRECTIONS_CARDINAL = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT
]

const DIRECTIONS_ALL = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i(-1, -1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(1, 1)
]

var wall_texture: Texture2D = preload("uid://dlxr8jwg04upv")
var hidden_material: ShaderMaterial = preload("uid://b8pg2s2mdu1iv")
var dissolve_material: ShaderMaterial = preload("uid://cvyc6mqsk8qv2")
var _walls_container: Node2D = null
var _collisions_container: Node2D = null

const DISSOLVE_DURATION: float = 0.5


func setup_from_dungeon() -> void:
	rooms.clear()
	_clear_walls()
	
	for pos in DungeonManager.cells.keys():
		rooms[pos] = {
			"type": 0,
			"revealed": false,
			"visited": false,
			"neighbors": DungeonManager.get_neighbors(pos)
		}
	
	rooms[DungeonManager.start_cell].type = -1
	rooms[DungeonManager.end_cell].type = 4
	
	_generate_walls()
	
	ConstructionFloor.setup()
	
	_hide_all()
	
	visit_room(DungeonManager.start_cell)
	
	print("DungeonReference: ", rooms.size(), " salles, ", walls.size(), " murs")


func _clear_walls() -> void:
	for pos in walls.keys():
		if walls[pos]:
			walls[pos].queue_free()
	walls.clear()
	
	for pos in wall_collisions.keys():
		if wall_collisions[pos]:
			wall_collisions[pos].queue_free()
	wall_collisions.clear()
	
	if _walls_container:
		_walls_container.queue_free()
	_walls_container = null
	
	if _collisions_container:
		_collisions_container.queue_free()
	_collisions_container = null


func _generate_walls() -> void:
	_walls_container = Node2D.new()
	_walls_container.name = "WallsContainer"
	DungeonManager._cells_container.add_sibling(_walls_container)
	
	_collisions_container = Node2D.new()
	_collisions_container.name = "CollisionsContainer"
	DungeonManager._cells_container.add_sibling(_collisions_container)
	
	var wall_positions: Dictionary = {}
	
	for pos in rooms.keys():
		for dir in DIRECTIONS_ALL:
			var neighbor = pos + dir
			if not rooms.has(neighbor) and not wall_positions.has(neighbor):
				wall_positions[neighbor] = true
	
	for pos in wall_positions.keys():
		# Sprite du mur
		var sprite = Sprite2D.new()
		sprite.texture = wall_texture
		sprite.centered = true
		sprite.position = DungeonManager.grid_to_world(pos)
		sprite.modulate = COLOR_HIDDEN
		sprite.material = hidden_material
		_walls_container.add_child(sprite)
		walls[pos] = sprite
		
		# Collision du mur
		var body = StaticBody2D.new()
		body.position = DungeonManager.grid_to_world(pos)
		
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(DungeonManager.CELL_SIZE, DungeonManager.CELL_SIZE)
		collision.shape = shape
		
		body.add_child(collision)
		_collisions_container.add_child(body)
		wall_collisions[pos] = body


func _hide_all() -> void:
	for pos in rooms.keys():
		var cell = DungeonManager.get_cell(pos)
		if cell and cell.sprite:
			cell.sprite.modulate = COLOR_HIDDEN
			cell.sprite.material = hidden_material
		
		var floor_sprites = ConstructionFloor.get_all_sprites_at(pos)
		for sprite in floor_sprites:
			sprite.modulate = COLOR_HIDDEN
			sprite.material = hidden_material
	
	for pos in walls.keys():
		if walls[pos]:
			walls[pos].modulate = COLOR_HIDDEN
			walls[pos].material = hidden_material


func _animate_dissolve_to_visible(sprite: Sprite2D) -> void:
	if not sprite:
		return
	
	var mat = dissolve_material.duplicate()
	mat.set_shader_parameter("dissolve_amount", 0.0)
	sprite.material = mat
	sprite.modulate = COLOR_VISIBLE
	
	var tween = sprite.create_tween()
	tween.tween_method(func(value): mat.set_shader_parameter("dissolve_amount", value), 0.0, 1.0, DISSOLVE_DURATION)
	tween.tween_callback(func(): sprite.material = null)


func _reveal_adjacent_walls(pos: Vector2i) -> void:
	for dir in DIRECTIONS_ALL:
		var wall_pos = pos + dir
		if walls.has(wall_pos):
			walls[wall_pos].modulate = COLOR_VISIBLE
			walls[wall_pos].material = null


func _reveal_adjacent_rooms(pos: Vector2i) -> void:
	for dir in DIRECTIONS_ALL:
		var neighbor = pos + dir
		if rooms.has(neighbor):
			reveal_room(neighbor)


func get_room(pos: Vector2i) -> Dictionary:
	return rooms.get(pos, {})


func has_room(pos: Vector2i) -> bool:
	return rooms.has(pos)


func set_room_type(pos: Vector2i, type: int) -> void:
	if rooms.has(pos):
		rooms[pos].type = type


func reveal_room(pos: Vector2i) -> void:
	if not rooms.has(pos):
		return
	if rooms[pos].revealed:
		return
	
	rooms[pos].revealed = true
	var cell = DungeonManager.get_cell(pos)
	if cell and cell.sprite:
		cell.sprite.modulate = COLOR_REVEALED
		cell.sprite.material = null
	
	var floor_sprites = ConstructionFloor.get_all_sprites_at(pos)
	for sprite in floor_sprites:
		sprite.modulate = COLOR_REVEALED
		sprite.material = null
	
	room_revealed.emit(pos)


func visit_room(pos: Vector2i) -> void:
	if not rooms.has(pos):
		return
	
	if rooms[pos].visited:
		return
	
	var was_revealed = rooms[pos].revealed
	rooms[pos].visited = true
	rooms[pos].revealed = true
	
	var cell = DungeonManager.get_cell(pos)
	if cell and cell.sprite:
		if was_revealed:
			_animate_dissolve_to_visible(cell.sprite)
		else:
			cell.sprite.modulate = COLOR_VISIBLE
			cell.sprite.material = null
	
	var floor_sprites = ConstructionFloor.get_all_sprites_at(pos)
	for sprite in floor_sprites:
		if was_revealed:
			_animate_dissolve_to_visible(sprite)
		else:
			sprite.modulate = COLOR_VISIBLE
			sprite.material = null
	
	_reveal_adjacent_walls(pos)
	_reveal_adjacent_rooms(pos)
	
	room_visited.emit(pos)


func is_revealed(pos: Vector2i) -> bool:
	if rooms.has(pos):
		return rooms[pos].revealed
	return false


func is_visited(pos: Vector2i) -> bool:
	if rooms.has(pos):
		return rooms[pos].visited
	return false


func list_all() -> void:
	for pos in rooms.keys():
		print(pos, " -> ", rooms[pos])


signal room_revealed(pos: Vector2i)
signal room_visited(pos: Vector2i)
