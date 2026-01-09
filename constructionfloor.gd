extends Node

## Autoload : ConstructionFloor
## Système de construction de sols par couches superposées

# Dictionnaires de textures par couche
var base: Dictionary = {
	"base_1": preload("uid://s34jq31yajbj"),
	"base_2": preload("uid://dbqic5rksux61"),
}

var detail_a: Dictionary = {
	"detail_a_1": preload("uid://lob10tvqsvq5"),
	"detail_a_2": preload("uid://brgeesdvpu1p8"),
	"detail_a_3": preload("uid://duk0hmdhbshdu"),
}

var detail_b: Dictionary = {
	"detail_b_1": preload("uid://bsdbcrcyx85yu"),
	"detail_b_2": preload("uid://cm6qi4kmcfnrp"),
}

# Chances d'apparition des détails (0.0 à 1.0)
const DETAIL_A_CHANCE: float = 0.2
const DETAIL_B_CHANCE: float = 0.2

# Container pour les sols
var _floors_container: Node2D = null

# Référence aux sprites par position
var floor_sprites: Dictionary = {}  # Vector2i -> { "base": Sprite2D, "detail_a": Sprite2D, "detail_b": Sprite2D }


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
		
		# Base obligatoire (z = 0)
		var base_sprite = Sprite2D.new()
		base_sprite.texture = _pick_random_texture(base)
		base_sprite.centered = true
		base_sprite.position = DungeonManager.grid_to_world(pos)
		base_sprite.z_index = 0
		_floors_container.add_child(base_sprite)
		layers.base = base_sprite
		
		# Detail A (20% de chance, z = 1)
		if randf() < DETAIL_A_CHANCE:
			var detail_a_sprite = Sprite2D.new()
			detail_a_sprite.texture = _pick_random_texture(detail_a)
			detail_a_sprite.centered = true
			detail_a_sprite.position = DungeonManager.grid_to_world(pos)
			detail_a_sprite.z_index = 1
			_floors_container.add_child(detail_a_sprite)
			layers.detail_a = detail_a_sprite
		
		# Detail B (20% de chance, z = 2)
		if randf() < DETAIL_B_CHANCE:
			var detail_b_sprite = Sprite2D.new()
			detail_b_sprite.texture = _pick_random_texture(detail_b)
			detail_b_sprite.centered = true
			detail_b_sprite.position = DungeonManager.grid_to_world(pos)
			detail_b_sprite.z_index = 2
			_floors_container.add_child(detail_b_sprite)
			layers.detail_b = detail_b_sprite
		
		floor_sprites[pos] = layers


func _pick_random_texture(dict: Dictionary) -> Texture2D:
	var keys = dict.keys()
	if keys.is_empty():
		return null
	var random_key = keys[randi() % keys.size()]
	return dict[random_key]


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
