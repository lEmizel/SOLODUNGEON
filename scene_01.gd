extends Node2D

@export var dungeon_size: int = 70
@export var branch_chance: float = 0.15
@export var max_branch_length: int = 3
@export var room_chance: float = 0.2
@export var floor_texture: Texture2D

func _ready():
	# Layer de fond
	var bg_layer = CanvasLayer.new()
	bg_layer.layer = -100
	add_child(bg_layer)
	
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 1)
	background.material = preload("uid://b8pg2s2mdu1iv")
	background.size = Vector2(16384, 16384)  # Très grand
	background.position = Vector2(-8192, -8192)  # Centré sur 0,0
	bg_layer.add_child(background)
	
	var container = Node2D.new()
	add_child(container)
	
	DungeonManager.setup(
		container,
		floor_texture,
		dungeon_size,
		branch_chance,
		max_branch_length,
		room_chance
	)
	
	DungeonManager.generate()
