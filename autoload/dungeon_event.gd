extends Node

## Autoload : DungeonEvent
## Gère les événements dans le donjon

enum EventType {
	NONE,
	COMBAT,
}

const COMBAT_CHANCE: float = 0.25  # 25%

var events: Dictionary = {}  # Vector2i -> EventType


func setup() -> void:
	events.clear()
	_generate_events()
	print("DungeonEvent: ", _count_events(EventType.COMBAT), " combats générés")


func _generate_events() -> void:
	for pos in DUNGEONREFERENCE.rooms.keys():
		# Pas d'événement sur le départ et la sortie
		if pos == DUNGEONREFERENCE.start_cell:
			continue
		if pos == DUNGEONREFERENCE.exit_cell:
			continue
		
		# Générer événement aléatoire
		if randf() < COMBAT_CHANCE:
			events[pos] = EventType.COMBAT
		else:
			events[pos] = EventType.NONE


func _count_events(type: EventType) -> int:
	var count = 0
	for pos in events.keys():
		if events[pos] == type:
			count += 1
	return count


func get_event(pos: Vector2i) -> EventType:
	return events.get(pos, EventType.NONE)


func has_combat(pos: Vector2i) -> bool:
	return get_event(pos) == EventType.COMBAT


func clear_event(pos: Vector2i) -> void:
	if events.has(pos):
		events[pos] = EventType.NONE


func trigger_event(pos: Vector2i) -> void:
	var event_type = get_event(pos)
	
	match event_type:
		EventType.COMBAT:
			print("=== COMBAT ! ===")
			combat_triggered.emit(pos)
		EventType.NONE:
			pass


signal combat_triggered(pos: Vector2i)
