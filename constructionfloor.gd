extends Node

## Autoload : ConstructionFloor
## Système de construction de sols par couches superposées
## Charge automatiquement les textures selon la nomenclature

const TEXTURE_PATH: String = "res://ressource_base/"
const SUPPORTED_EXTENSIONS: Array = ["png", "jpg", "webp"]

const DETAIL_A_CHANCE: float = 0.2
const DETAIL_B_CHANCE: float = 0.2

var textures: Dictionary = {}
var _floors_container: Node2D = null
var floor_sprites: Dictionary = {}


func _ready() -> void:
	_scan_textures()


func _scan_textures() -> void:
	var dir = DirAccess.open(TEXTURE_PATH)
	if not dir:
		push_warning("ConstructionFloor: Impossible d'ouvrir " + TEXTURE_PATH)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			_try_load_texture(file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	_print_loaded()


func _try_load_texture(file_name: String) -> void:
	if file_name.ends_with(".import"):
		return
	
	var extension = file_name.get_extension().to_lower()
	if extension not in SUPPORTED_EXTENSIONS:
		return
	
	var base_name = file_name.get_basename()
	var parts = base_name.split("_")
	
	if parts.size() < 2:
		return
	
	# Prefix = tout sauf le dernier élément (le numéro)
	var prefix_parts = parts.slice(0, parts.size() - 1)
	var prefix = "_".join(prefix_parts).to_lower()
	
	if not textures.has(prefix):
		textures[prefix] = []
	
	var full_path = TEXTURE_PATH + file_name
	var tex = load(full_path)
	
	if tex:
		textures[prefix].append(tex)


func _print_loaded() -> void:
	print("=== ConstructionFloor chargé ===")
	for key in textures.keys():
		print("  ", key, ": ", textures[key].size(), " textures")


func _pick_random_texture(type: String) -> Texture2D:
	if not textures.has(type) or textures[type].is_empty():
		return null
	return textures[type][randi() % textures[type].size()]


func setup() -> void:
	_clear()
	_create_container()
	_generate_floors()
	print("ConstructionFloor: ", floor_sprites.size(), " sols créés")


func _clear() -> void:
	for pos in floor_sprites.keys():
		var layers = floor_sprites[pos]
		if layers.base:
			layers.base.queue_free()
		if layers.detail_a:
			layers.detail_a.queue_free()
		if layers.detail_b:
			layers.detail_b.queue_free()
	floor_sprites.clear()
	
	if _floors_container:
		_floors_container.queue_free()
	_floors_container = null


func _create_container() -> void:
	_floors_container = Node2D.new()
	_floors_container.name = "FloorsContainer"
	_floors_container.z_index = -10
	DungeonManager._cells_container.add_sibling(_floors_container)


func _generate_floors() -> void:
	for pos in DUNGEONREFERENCE.rooms.keys():
		var layers = {
			"base": null,
			"detail_a": null,
			"detail_b": null
		}
		
		var base_tex = _pick_random_texture("base")
		if base_tex:
			var base_sprite = Sprite2D.new()
			base_sprite.texture = base_tex
			base_sprite.centered = true
			base_sprite.position = DungeonManager.grid_to_world(pos)
			base_sprite.z_index = 0
			_floors_container.add_child(base_sprite)
			layers.base = base_sprite
		
		if randf() < DETAIL_A_CHANCE:
			var detail_a_tex = _pick_random_texture("detaila")
			if detail_a_tex:
				var detail_a_sprite = Sprite2D.new()
				detail_a_sprite.texture = detail_a_tex
				detail_a_sprite.centered = true
				detail_a_sprite.position = DungeonManager.grid_to_world(pos)
				detail_a_sprite.z_index = 1
				_floors_container.add_child(detail_a_sprite)
				layers.detail_a = detail_a_sprite
		
		if randf() < DETAIL_B_CHANCE:
			var detail_b_tex = _pick_random_texture("detailb")
			if detail_b_tex:
				var detail_b_sprite = Sprite2D.new()
				detail_b_sprite.texture = detail_b_tex
				detail_b_sprite.centered = true
				detail_b_sprite.position = DungeonManager.grid_to_world(pos)
				detail_b_sprite.z_index = 2
				_floors_container.add_child(detail_b_sprite)
				layers.detail_b = detail_b_sprite
		
		floor_sprites[pos] = layers


func get_floor_sprites(pos: Vector2i) -> Dictionary:
	return floor_sprites.get(pos, {})


func get_all_sprites_at(pos: Vector2i) -> Array[Sprite2D]:
	var result: Array[Sprite2D] = []
	var layers = floor_sprites.get(pos, {})
	if layers.has("base") and layers.base:
		result.append(layers.base)
	if layers.has("detail_a") and layers.detail_a:
		result.append(layers.detail_a)
	if layers.has("detail_b") and layers.detail_b:
		result.append(layers.detail_b)
	return result
