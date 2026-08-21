extends Resource
class_name EncounterTable

@export var entries: Array[EncounterEntry] = []
@export_range(1, 20, 1) var minimum_steps: int = 4
@export_range(0.0, 1.0, 0.01) var chance_per_step: float = 0.16

func roll(rng: RandomNumberGenerator) -> Dictionary:
	if entries.is_empty():
		return {}

	var total_weight := 0
	for entry in entries:
		total_weight += max(entry.weight, 0)
	if total_weight <= 0:
		return {}

	var ticket := rng.randi_range(1, total_weight)
	var cursor := 0
	for entry in entries:
		cursor += max(entry.weight, 0)
		if ticket <= cursor:
			var low := min(entry.min_level, entry.max_level)
			var high := max(entry.min_level, entry.max_level)
			return {
				"species_id": entry.species_id,
				"level": rng.randi_range(low, high)
			}
	return {}
