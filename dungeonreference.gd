extends Node

## Autoload : DUNGEONREFERENCE
## Gère l'état des salles

var rooms: Dictionary = {}

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


func setup_from_dungeon() -> void:
	rooms.clear()
	
	for pos in DungeonManager.cells.keys():
		rooms[pos] = {
			"type": 0,
			"visited": false,
			"neighbors": DungeonManager.get_neighbors(pos)
		}
	
	rooms[DungeonManager.start_cell].type = -1
	rooms[DungeonManager.end_cell].type = 4
	
	ConstructionFloor.setup()
	
	print("DungeonReference: ", rooms.size(), " salles")


func get_room(pos: Vector2i) -> Dictionary:
	return rooms.get(pos, {})


func has_room(pos: Vector2i) -> bool:
	return rooms.has(pos)


func set_room_type(pos: Vector2i, type: int) -> void:
	if rooms.has(pos):
		rooms[pos].type = type


func visit_room(pos: Vector2i) -> void:
	if not rooms.has(pos):
		return
	
	if rooms[pos].visited:
		return
	
	rooms[pos].visited = true
	room_visited.emit(pos)


func is_visited(pos: Vector2i) -> bool:
	if rooms.has(pos):
		return rooms[pos].visited
	return false


func list_all() -> void:
	for pos in rooms.keys():
		print(pos, " -> ", rooms[pos])


signal room_visited(pos: Vector2i)
