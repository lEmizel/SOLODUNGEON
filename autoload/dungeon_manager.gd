extends Node

const CELL_SIZE: int = 1024

const DIRECTIONS = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT
]

## Configuration du donjon
var dungeon_size: int = 25
var branch_chance: float = 0.1
var max_branch_length: int = 2
var room_chance: float = 0.15

## Données des cases
var cells: Dictionary = {}
var start_cell: Vector2i = Vector2i.ZERO
var end_cell: Vector2i = Vector2i.ZERO

## Container pour les sprites
var _cells_container: Node2D = null
var floor_texture: Texture2D = null


class CellData:
	var position: Vector2i
	var texture: Texture2D = null
	var sprite: Sprite2D = null
	
	func _init(pos: Vector2i):
		position = pos


func setup(
	container: Node2D,
	texture: Texture2D,
	p_dungeon_size: int = 25,
	p_branch_chance: float = 0.1,
	p_max_branch_length: int = 2,
	p_room_chance: float = 0.15
) -> void:
	_cells_container = container
	floor_texture = texture
	dungeon_size = p_dungeon_size
	branch_chance = p_branch_chance
	max_branch_length = p_max_branch_length
	room_chance = p_room_chance


func generate(size: int = -1) -> void:
	if size > 0:
		dungeon_size = size
	_clear()
	_generate_layout()
	_place_visuals()
	
	# Passer au reference pour gérer les états
	DUNGEONREFERENCE.setup_from_dungeon()
	
	dungeon_generated.emit()
	print("Donjon généré : ", cells.size(), " cases")


func _clear() -> void:
	for pos in cells.keys():
		var cell = cells[pos]
		if cell.sprite:
			cell.sprite.queue_free()
	cells.clear()


func _generate_layout() -> void:
	start_cell = Vector2i.ZERO
	_add_cell(start_cell)
	
	var current = start_cell + Vector2i.UP
	_add_cell(current)
	
	var last_direction = Vector2i.UP
	var path: Array[Vector2i] = [start_cell, current]
	
	var max_attempts = dungeon_size * 50
	var attempts = 0
	
	while cells.size() < dungeon_size and attempts < max_attempts:
		attempts += 1
		
		var direction = _choose_corridor_direction(current, last_direction)
		
		if direction == Vector2i.ZERO:
			if path.size() > 2:
				path.pop_back()
				current = path.back()
				if path.size() >= 2:
					last_direction = current - path[path.size() - 2]
				continue
			else:
				var random_cells = cells.keys()
				random_cells.shuffle()
				var found = false
				for test_cell in random_cells:
					var test_dir = _choose_corridor_direction(test_cell, Vector2i.ZERO)
					if test_dir != Vector2i.ZERO:
						current = test_cell
						last_direction = test_dir
						path = [current]
						found = true
						break
				if not found:
					break
				continue
		
		var next_cell = current + direction
		
		if _is_valid_corridor_cell(next_cell):
			_add_cell(next_cell)
			last_direction = direction
			current = next_cell
			path.append(current)
			
			if randf() < room_chance:
				_create_room(current)
			elif randf() < branch_chance:
				_create_branch(current)
	
	end_cell = current
	print("Génération terminée : ", cells.size(), "/", dungeon_size, " cases après ", attempts, " tentatives")


func _add_cell(pos: Vector2i) -> CellData:
	var cell = CellData.new(pos)
	cells[pos] = cell
	return cell


func _choose_corridor_direction(from: Vector2i, last_dir: Vector2i) -> Vector2i:
	var valid: Array[Vector2i] = []
	var preferred: Array[Vector2i] = []
	
	for dir in DIRECTIONS:
		if dir == -last_dir:
			continue
		var next = from + dir
		if _is_valid_corridor_cell(next):
			valid.append(dir)
			if dir == last_dir:
				preferred.append(dir)
				preferred.append(dir)
			else:
				preferred.append(dir)
	
	if not preferred.is_empty():
		return preferred[randi() % preferred.size()]
	if not valid.is_empty():
		return valid[randi() % valid.size()]
	return Vector2i.ZERO


func _is_valid_corridor_cell(pos: Vector2i) -> bool:
	if cells.has(pos):
		return false
	
	for dir in DIRECTIONS:
		if pos + dir == start_cell:
			return false
	
	var neighbor_count = 0
	for dir in DIRECTIONS:
		if cells.has(pos + dir):
			neighbor_count += 1
	
	return neighbor_count == 1


func _is_valid_room_cell(pos: Vector2i) -> bool:
	if cells.has(pos):
		return false
	for dir in DIRECTIONS:
		if pos + dir == start_cell:
			return false
	return true


func _create_room(center: Vector2i) -> void:
	var offsets: Array[Vector2i]
	if randi() % 2 == 0:
		offsets = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	else:
		offsets = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	var added = 0
	for offset in offsets:
		if added >= 2:
			break
		var room_cell = center + offset
		if _is_valid_room_cell(room_cell):
			_add_cell(room_cell)
			added += 1


func _create_branch(from: Vector2i) -> void:
	var length = randi_range(1, max_branch_length)
	var current = from
	var last_dir = Vector2i.ZERO
	
	for i in range(length):
		var dir = _choose_corridor_direction(current, last_dir)
		if dir == Vector2i.ZERO:
			break
		var next = current + dir
		if _is_valid_corridor_cell(next):
			_add_cell(next)
			last_dir = dir
			current = next


func _place_visuals() -> void:
	if not _cells_container or not floor_texture:
		push_warning("DungeonManager: container ou texture manquant")
		return
	
	for pos in cells.keys():
		var cell = cells[pos]
		cell.texture = floor_texture
		
		cell.sprite = Sprite2D.new()
		cell.sprite.texture = floor_texture
		cell.sprite.centered = true
		cell.sprite.position = grid_to_world(pos)
		# Pas de modulate ici, c'est DUNGEONREFERENCE qui gère
		_cells_container.add_child(cell.sprite)


## API Publique

func get_cell(pos: Vector2i) -> CellData:
	return cells.get(pos)


func has_cell(pos: Vector2i) -> bool:
	return cells.has(pos)


func get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dir in DIRECTIONS:
		if cells.has(pos + dir):
			neighbors.append(pos + dir)
	return neighbors


func is_dead_end(pos: Vector2i) -> bool:
	return get_neighbors(pos).size() == 1 and pos != start_cell


func get_dead_ends() -> Array[Vector2i]:
	var dead_ends: Array[Vector2i] = []
	for pos in cells.keys():
		if is_dead_end(pos):
			dead_ends.append(pos)
	return dead_ends


func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori((world_pos.x + CELL_SIZE / 2) / CELL_SIZE),
		floori((world_pos.y + CELL_SIZE / 2) / CELL_SIZE)
	)


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * CELL_SIZE, grid_pos.y * CELL_SIZE)


signal dungeon_generated()
