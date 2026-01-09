extends Node2D

var hero_scene: PackedScene = preload("uid://bar21si275rk4")  # Ajuste le chemin
var hero: CharacterBody2D = null
var current_cell: Vector2i = Vector2i.ZERO

func _ready():
	_spawn_hero()


func _spawn_hero() -> void:
	hero = hero_scene.instantiate()
	hero.position = DungeonManager.grid_to_world(Vector2i.ZERO)
	add_child(hero)
	
	# Marquer la case de départ comme visitée
	current_cell = Vector2i.ZERO
	DUNGEONREFERENCE.visit_room(current_cell)


func _process(delta: float) -> void:
	if not hero:
		return
	
	# Vérifier sur quelle case le héros se trouve
	var hero_cell = DungeonManager.world_to_grid(hero.position)
	
	# Si on a changé de case
	if hero_cell != current_cell:
		# Vérifier que c'est une case valide du donjon
		if DUNGEONREFERENCE.has_room(hero_cell):
			current_cell = hero_cell
			DUNGEONREFERENCE.visit_room(current_cell)
