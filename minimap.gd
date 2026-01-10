extends Node2D

## Minimap - Affiche la structure du donjon en petits carrés

const CELL_SIZE: int = 16
const CELL_COLOR_HIDDEN: Color = Color(0, 0, 0, 1.0)
const CELL_COLOR_REVEALED: Color = Color(0.08, 0.16, 0.329, 1.0)
const CELL_COLOR_VISITED: Color = Color(0.3, 0.5, 0.8, 1.0)
const PLAYER_COLOR: Color = Color(0.3, 1.0, 0.3, 1.0)
const BG_COLOR: Color = Color(0, 0, 0, 1.0)

const DIRECTIONS_CARDINAL = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT
]

var _minimap_container: Node2D = null
var _cells: Dictionary = {}
var _player_marker: ColorRect = null
var _current_player_cell: Vector2i = Vector2i.ZERO
var _background: ColorRect = null
var _camera: Camera2D = null
var _visited_cells: Dictionary = {}
var _revealed_cells: Dictionary = {}


func _ready() -> void:
	await get_tree().process_frame
	_generate_minimap()


func _process(delta: float) -> void:
	_update_player_position()


func _generate_minimap() -> void:
	_background = ColorRect.new()
	_background.size = Vector2(8192, 8192)
	_background.position = Vector2(-4096, -4096)
	_background.color = BG_COLOR
	_background.z_index = -1
	add_child(_background)
	
	_minimap_container = Node2D.new()
	_minimap_container.name = "MinimapContainer"
	add_child(_minimap_container)
	
	# Toutes les cases en noir au départ
	for pos in DUNGEONREFERENCE.rooms.keys():
		var rect = ColorRect.new()
		rect.size = Vector2(CELL_SIZE, CELL_SIZE)
		rect.position = Vector2(pos.x * CELL_SIZE, pos.y * CELL_SIZE)
		rect.color = CELL_COLOR_HIDDEN
		_minimap_container.add_child(rect)
		_cells[pos] = rect
	
	_player_marker = ColorRect.new()
	_player_marker.size = Vector2(CELL_SIZE, CELL_SIZE)
	_player_marker.color = PLAYER_COLOR
	_player_marker.z_index = 1
	_minimap_container.add_child(_player_marker)
	
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 10.0
	add_child(_camera)
	_camera.make_current()
	
	# Récupérer la position actuelle du joueur
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_current_player_cell = players[0].current_cell
		_player_marker.position = Vector2(_current_player_cell.x * CELL_SIZE, _current_player_cell.y * CELL_SIZE)
		_camera.position = _player_marker.position + Vector2(CELL_SIZE / 2, CELL_SIZE / 2)
	
	# Visiter la case de départ
	_visit_cell(_current_player_cell)
	
	print("Minimap: ", _cells.size(), " cases")


func _visit_cell(pos: Vector2i) -> void:
	if not _cells.has(pos):
		return
	
	if _visited_cells.has(pos):
		return
	
	_visited_cells[pos] = true
	_cells[pos].color = CELL_COLOR_VISITED
	
	for dir in DIRECTIONS_CARDINAL:
		var neighbor = pos + dir
		if _cells.has(neighbor) and not _visited_cells.has(neighbor) and not _revealed_cells.has(neighbor):
			_revealed_cells[neighbor] = true
			_cells[neighbor].color = CELL_COLOR_REVEALED


func _update_player_position() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	
	var player = players[0]
	if player.current_cell != _current_player_cell:
		_current_player_cell = player.current_cell
		_player_marker.position = Vector2(_current_player_cell.x * CELL_SIZE, _current_player_cell.y * CELL_SIZE)
		_visit_cell(_current_player_cell)
	
	if _camera:
		_camera.position = _player_marker.position + Vector2(CELL_SIZE / 2, CELL_SIZE / 2)
