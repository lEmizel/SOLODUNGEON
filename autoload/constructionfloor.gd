extends Node

## Autoload : ConstructionFloor

const TEXTURE_PATH: String = "res://ressource_base/"

var textures: Dictionary = {}
var _floors_container: Node2D = null
var floor_sprites: Dictionary = {}


func _ready() -> void:
	_preload_textures()


func _preload_textures() -> void:
	# Liste manuelle des textures (nécessaire pour l'export)
	var texture_files = [
		"base_01.png",
		"up_01.png",
		"down_01.png",
		"left_01.png",
		"right_01.png",
		# Ajoute ici les autres textures si tu en as
	]
	
	for file_name in texture_files:
		var base_name = file_name.get_basename()
		var parts = base_name.split("_")
		
		if parts.size() < 2:
			continue
		
		var prefix_parts = parts.slice(0, parts.size() - 1)
		var prefix = "_".join(prefix_parts).to_lower()
		
		if not textures.has(prefix):
			textures[prefix] = []
		
		var full_path = TEXTURE_PATH + file_name
		var tex = load(full_path)
		
		if tex:
			textures[prefix].append(tex)
	
	_print_loaded()


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
		if layers.has("base") and layers.base:
			layers.base.queue_free()
		if layers.has("up") and layers.up:
			layers.up.queue_free()
		if layers.has("down") and layers.down:
			layers.down.queue_free()
		if layers.has("left") and layers.left:
			layers.left.queue_free()
		if layers.has("right") and layers.right:
			layers.right.queue_free()
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
			"up": null,
			"down": null,
			"left": null,
			"right": null
		}
		
		var world_pos = DungeonManager.grid_to_world(pos)
		var neighbors: Array = DUNGEONREFERENCE.rooms[pos].neighbors
		
		var base_tex = _pick_random_texture("base")
		if base_tex:
			var base_sprite = Sprite2D.new()
			base_sprite.texture = base_tex
			base_sprite.centered = true
			base_sprite.position = world_pos
			base_sprite.z_index = 0
			_floors_container.add_child(base_sprite)
			layers.base = base_sprite
		
		if (pos + Vector2i.UP) in neighbors:
			var tex = _pick_random_texture("up")
			if tex:
				var sprite = Sprite2D.new()
				sprite.texture = tex
				sprite.centered = true
				sprite.position = world_pos
				sprite.z_index = 1
				_floors_container.add_child(sprite)
				layers.up = sprite
		
		if (pos + Vector2i.DOWN) in neighbors:
			var tex = _pick_random_texture("down")
			if tex:
				var sprite = Sprite2D.new()
				sprite.texture = tex
				sprite.centered = true
				sprite.position = world_pos
				sprite.z_index = 1
				_floors_container.add_child(sprite)
				layers.down = sprite
		
		if (pos + Vector2i.LEFT) in neighbors:
			var tex = _pick_random_texture("left")
			if tex:
				var sprite = Sprite2D.new()
				sprite.texture = tex
				sprite.centered = true
				sprite.position = world_pos
				sprite.z_index = 1
				_floors_container.add_child(sprite)
				layers.left = sprite
		
		if (pos + Vector2i.RIGHT) in neighbors:
			var tex = _pick_random_texture("right")
			if tex:
				var sprite = Sprite2D.new()
				sprite.texture = tex
				sprite.centered = true
				sprite.position = world_pos
				sprite.z_index = 1
				_floors_container.add_child(sprite)
				layers.right = sprite
		
		floor_sprites[pos] = layers


func get_floor_sprites(pos: Vector2i) -> Dictionary:
	return floor_sprites.get(pos, {})


func get_all_sprites_at(pos: Vector2i) -> Array[Sprite2D]:
	var result: Array[Sprite2D] = []
	var layers = floor_sprites.get(pos, {})
	if layers.has("base") and layers.base:
		result.append(layers.base)
	if layers.has("up") and layers.up:
		result.append(layers.up)
	if layers.has("down") and layers.down:
		result.append(layers.down)
	if layers.has("left") and layers.left:
		result.append(layers.left)
	if layers.has("right") and layers.right:
		result.append(layers.right)
	return result
