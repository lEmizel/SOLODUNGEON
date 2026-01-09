@tool
extends Node
class_name DungeonGenerator

## Référence au GridManager
@export var grid_manager: GridManager

## Textures pour les cases
@export var floor_texture: Texture2D

## Configuration du donjon
@export var dungeon_size: int = 200
@export var branch_chance: float = 0.1
@export var max_branch_length: int = 2
@export var room_chance: float = 0.15  # Chance de créer une pièce
@export var reveal_on_generate: bool = true  # Pour debug

## Debug
@export var generate_on_ready: bool = false

## Données du donjon généré
var dungeon_cells: Array[Vector2i] = []
var start_cell: Vector2i = Vector2i.ZERO
var end_cell: Vector2i = Vector2i.ZERO

const DIRECTIONS = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT
]


func _ready() -> void:
	if generate_on_ready and not Engine.is_editor_hint():
		generate()


func generate() -> void:
	if not grid_manager:
		push_error("DungeonGenerator: GridManager non assigné")
		return
	
	if not floor_texture:
		push_error("DungeonGenerator: floor_texture non assignée")
		return
	
	_clear_dungeon()
	_generate_layout()
	_place_textures()
	dungeon_generated.emit()


func _clear_dungeon() -> void:
	for pos in dungeon_cells:
		grid_manager.clear_cell(pos)
	dungeon_cells.clear()


func _generate_layout() -> void:
	start_cell = Vector2i.ZERO
	dungeon_cells.append(start_cell)
	
	# Premier pas TOUJOURS vers le nord
	var first_direction = Vector2i.UP
	var current = start_cell + first_direction
	dungeon_cells.append(current)
	
	var last_direction = first_direction
	
	var max_attempts = dungeon_size * 20
	var attempts = 0
	
	while dungeon_cells.size() < dungeon_size and attempts < max_attempts:
		attempts += 1
		
		var direction = _choose_corridor_direction(current, last_direction)
		if direction == Vector2i.ZERO:
			var idx = dungeon_cells.find(current)
			if idx > 1:
				current = dungeon_cells[idx - 1]
				continue
			else:
				break
		
		var next_cell = current + direction
		
		if _is_valid_corridor_cell(next_cell):
			dungeon_cells.append(next_cell)
			last_direction = direction
			current = next_cell
			
			# Chance de créer une pièce
			if randf() < room_chance:
				_create_room(current)
			# Sinon chance de créer une branche
			elif randf() < branch_chance:
				_create_short_branch(current)
	
	end_cell = current


func _choose_corridor_direction(from: Vector2i, last_dir: Vector2i) -> Vector2i:
	var valid_directions: Array[Vector2i] = []
	var preferred_directions: Array[Vector2i] = []
	
	for dir in DIRECTIONS:
		if dir == -last_dir:
			continue
		
		var next = from + dir
		if _is_valid_corridor_cell(next):
			valid_directions.append(dir)
			if dir == last_dir:
				preferred_directions.append(dir)
				preferred_directions.append(dir)
			else:
				preferred_directions.append(dir)
	
	if preferred_directions.is_empty():
		if valid_directions.is_empty():
			return Vector2i.ZERO
		return valid_directions[randi() % valid_directions.size()]
	
	return preferred_directions[randi() % preferred_directions.size()]


func _is_valid_corridor_cell(pos: Vector2i) -> bool:
	if pos in dungeon_cells:
		return false
	
	# JAMAIS adjacent au start (sauf la première case qui est déjà placée)
	for dir in DIRECTIONS:
		if pos + dir == start_cell:
			return false
	
	# Filiforme : un seul voisin existant
	var neighbor_count = 0
	for dir in DIRECTIONS:
		var neighbor = pos + dir
		if neighbor in dungeon_cells:
			neighbor_count += 1
	
	return neighbor_count == 1


func _is_valid_room_cell(pos: Vector2i) -> bool:
	if pos in dungeon_cells:
		return false
	
	# JAMAIS adjacent au start
	for dir in DIRECTIONS:
		if pos + dir == start_cell:
			return false
	
	# Pour les pièces, on autorise plusieurs voisins
	return true


func _create_room(center: Vector2i) -> void:
	# Créer une petite pièce 2x2 ou 3x3
	var room_type = randi() % 2
	
	if room_type == 0:
		# Pièce 2x2
		var offsets = [
			Vector2i(1, 0),
			Vector2i(0, 1),
			Vector2i(1, 1)
		]
		for offset in offsets:
			var room_cell = center + offset
			if _is_valid_room_cell(room_cell):
				dungeon_cells.append(room_cell)
	else:
		# Pièce en croix (plus filiforme)
		var offsets = [
			Vector2i(1, 0),
			Vector2i(-1, 0),
			Vector2i(0, 1),
			Vector2i(0, -1)
		]
		var added = 0
		for offset in offsets:
			if added >= 2:  # Max 2 cases ajoutées
				break
			var room_cell = center + offset
			if _is_valid_room_cell(room_cell):
				dungeon_cells.append(room_cell)
				added += 1


func _create_short_branch(from: Vector2i) -> void:
	var branch_length = randi_range(1, max_branch_length)
	var current = from
	var last_dir = Vector2i.ZERO
	
	for i in range(branch_length):
		var direction = _choose_corridor_direction(current, last_dir)
		if direction == Vector2i.ZERO:
			break
		
		var next = current + direction
		if _is_valid_corridor_cell(next):
			dungeon_cells.append(next)
			last_dir = direction
			current = next
		else:
			break


func _place_textures() -> void:
	for pos in dungeon_cells:
		grid_manager.set_cell_texture(pos, floor_texture)
		if reveal_on_generate:
			grid_manager.reveal_cell(pos)


func get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dir in DIRECTIONS:
		var neighbor = pos + dir
		if neighbor in dungeon_cells:
			neighbors.append(neighbor)
	return neighbors


func is_dead_end(pos: Vector2i) -> bool:
	return get_neighbors(pos).size() == 1 and pos != start_cell


func get_dead_ends() -> Array[Vector2i]:
	var dead_ends: Array[Vector2i] = []
	for pos in dungeon_cells:
		if is_dead_end(pos):
			dead_ends.append(pos)
	return dead_ends


signal dungeon_generated()
