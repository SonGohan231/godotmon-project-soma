extends RefCounted
class_name SomaskanCatalog

static func get_species(species_id: StringName) -> Dictionary:
	var species := CreatureDex.get_species(species_id)
	var result := species.duplicate(true)
	result["moves"] = SomadexMoveCatalog.natural_moves(Array(species.get("types", ["KONTAKT"])), int(species.get("stage", 1)))
	return result

static func move_ids(species_id: StringName) -> Array[StringName]:
	var species := CreatureDex.get_species(species_id)
	return SomadexMoveCatalog.natural_move_ids(Array(species.get("types", ["KONTAKT"])), int(species.get("stage", 1)))

static func get_move(move_id: StringName) -> Dictionary:
	return SomadexMoveCatalog.get_move(move_id)

static func resolve_moves(move_ids: Array, species_id: StringName) -> Array:
	var result: Array = []
	for raw_id in move_ids:
		var move := get_move(StringName(raw_id))
		if !move.is_empty():
			result.append(move)
		if result.size() >= 4:
			break
	if result.is_empty():
		return get_species(species_id).get("moves", [])
	return result
