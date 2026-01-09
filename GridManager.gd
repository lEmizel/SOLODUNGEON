@tool
extends Node2D
class_name GridManager

const CELL_SIZE: int = 512

## Texture de debug pour la case origine
@export var origin_texture: Texture2D:
	set(value):
		origin_texture = value
		_update_origin_cell()

## Données des cases (dictionnaire infini)
var cells: Dictionary = {}  # Vector2i -> CellData

## Sprite de la case origine (toujours visible pour debug)
var _origin_sprite: Sprite2D

class CellData:
	var position: Vector2i
	var revealed: bool = false
	var content_type: int = 0
	var texture: Texture2D = null
	var sprite: Sprite2D = null
	
	func _init(pos: Vector2i):
		position = pos


func _ready() -> void:
	_setup_origin_cell()


func _setup_origin_cell() -> void:
	if _origin_sprite:
		return
	_origin_sprite = Sprite2D.new()
	_origin_sprite.centered = true  # Centre du sprite = centre de la case = 0,0
	_origin_sprite.position = Vector2.ZERO
	add_child(_origin_sprite)
	_update_origin_cell()


func _update_origin_cell() -> void:
	if _origin_sprite and origin_texture:
		_origin_sprite.texture = origin_texture


## API publique

func get_cell(pos: Vector2i) -> CellData:
	return cells.get(pos)


func get_or_create_cell(pos: Vector2i) -> CellData:
	if not cells.has(pos):
		cells[pos] = CellData.new(pos)
	return cells[pos]


func set_cell_texture(pos: Vector2i, texture: Texture2D) -> void:
	var cell = get_or_create_cell(pos)
	cell.texture = texture
	
	if not cell.sprite:
		cell.sprite = Sprite2D.new()
		cell.sprite.centered = true
		add_child(cell.sprite)
	
	cell.sprite.texture = texture
	cell.sprite.position = grid_to_world(pos)
	
	if not cell.revealed:
		cell.sprite.modulate = Color(0.1, 0.1, 0.1, 1.0)


func reveal_cell(pos: Vector2i) -> void:
	var cell = get_cell(pos)
	if cell and not cell.revealed:
		cell.revealed = true
		if cell.sprite:
			cell.sprite.modulate = Color(1, 1, 1, 1)
		cell_revealed.emit(pos, cell)


func clear_cell(pos: Vector2i) -> void:
	var cell = get_cell(pos)
	if cell:
		if cell.sprite:
			cell.sprite.queue_free()
		cells.erase(pos)


func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori((world_pos.x + CELL_SIZE / 2) / CELL_SIZE),
		floori((world_pos.y + CELL_SIZE / 2) / CELL_SIZE)
	)


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	# Centre de la case
	return Vector2(grid_pos.x * CELL_SIZE, grid_pos.y * CELL_SIZE)


func grid_to_world_corner(grid_pos: Vector2i) -> Vector2:
	# Coin supérieur gauche de la case
	return Vector2(
		grid_pos.x * CELL_SIZE - CELL_SIZE / 2,
		grid_pos.y * CELL_SIZE - CELL_SIZE / 2
	)


## Signals
signal cell_revealed(pos: Vector2i, cell: CellData)
