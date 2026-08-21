extends Resource
class_name EncounterEntry

@export var species_id: StringName
@export_range(1, 100, 1) var min_level: int = 2
@export_range(1, 100, 1) var max_level: int = 4
@export_range(1, 1000, 1) var weight: int = 100
