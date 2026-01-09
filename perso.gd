extends CharacterBody2D

const SPEED = 700.0

func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO
	
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	
	# Normaliser pour éviter d'aller plus vite en diagonale
	if direction.length() > 0:
		direction = direction.normalized()
	
	velocity = direction * SPEED
	move_and_slide()
