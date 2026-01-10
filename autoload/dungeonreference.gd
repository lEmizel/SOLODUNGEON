extends Node

## Autoload : DUNGEONREFERENCE
## Gère l'état des salles

var rooms: Dictionary = {}
var start_cell: Vector2i = Vector2i.ZERO
var exit_cell: Vector2i = Vector2i.ZERO

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
	
	start_cell = DungeonManager.start_cell
	exit_cell = _find_farthest_room(start_cell)
	
	rooms[start_cell].type = -1
	rooms[exit_cell].type = 4
	
	ConstructionFloor.setup()
	DungeonEvent.setup()  # Générer les événements
	
	print("DungeonReference: ", rooms.size(), " salles")
	print("Départ: ", start_cell, " | Sortie: ", exit_cell)


func _find_farthest_room(from: Vector2i) -> Vector2i:
	var visited: Dictionary = {}
	var queue: Array = []
	var farthest: Vector2i = from
	
	queue.append(from)
	visited[from] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		farthest = current
		
		var neighbors = rooms[current].neighbors
		for neighbor in neighbors:
			if not visited.has(neighbor) and rooms.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	
	return farthest


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
	
	# Déclencher l'événement de la case
	DungeonEvent.trigger_event(pos)
	
	# Vérifier si c'est la sortie
	if pos == exit_cell:
		print("=== SORTIE ATTEINTE ! ===")
		reached_exit.emit()
	
	room_visited.emit(pos)


func is_visited(pos: Vector2i) -> bool:
	if rooms.has(pos):
		return rooms[pos].visited
	return false


func is_exit(pos: Vector2i) -> bool:
	return pos == exit_cell


func list_all() -> void:
	for pos in rooms.keys():
		print(pos, " -> ", rooms[pos])


signal room_visited(pos: Vector2i)
signal reached_exit
