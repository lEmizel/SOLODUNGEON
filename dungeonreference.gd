extends Node

## Autoload : DUNGEONREFERENCE
## Gère l'état des salles et leur affichage

var rooms: Dictionary = {}

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

var hidden_material: ShaderMaterial = preload("uid://b8pg2s2mdu1iv")
var dissolve_material: ShaderMaterial = preload("uid://cvyc6mqsk8qv2")

const DISSOLVE_DURATION: float = 0.5


func setup_from_dungeon() -> void:
	rooms.clear()
	
	for pos in DungeonManager.cells.keys():
		rooms[pos] = {
			"type": 0,
			"revealed": false,
			"visited": false,
			"neighbors": DungeonManager.get_neighbors(pos)
		}
	
	rooms[DungeonManager.start_cell].type = -1
	rooms[DungeonManager.end_cell].type = 4
	
	ConstructionFloor.setup()
	
	_hide_all()
	
	visit_room(DungeonManager.start_cell)
	
	print("DungeonReference: ", rooms.size(), " salles")


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
