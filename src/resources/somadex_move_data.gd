extends AttackData
class_name SomadexMoveData

## Presentation and SOMADEX-specific battle metadata layered on top of godotmon AttackData.
@export var display_name: String = ""
@export var priority: int = 0
@export var status_id: StringName
@export_range(0, 100, 1) var status_chance: int = 0
@export var effect_id: StringName
@export_range(0, 100, 1) var resonance_gain: int = 0
@export_range(0, 100, 1) var resonance_cost: int = 0
@export var tags: Array[StringName] = []

func is_resonance_move() -> bool:
	return resonance_gain > 0 || resonance_cost > 0 || tags.has(&"rezonans")
