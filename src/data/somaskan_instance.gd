extends RefCounted
class_name SomaskanInstance

var uid: String = ""
var species: SomaskanSpecies
var nickname: String = ""
var level: int = 1
var xp: int = 0
var current_hp: int = 1
var status_id: StringName
var learned_moves: Array[SomadexMoveData] = []

static func create(species_data: SomaskanSpecies, at_level: int) -> SomaskanInstance:
	var instance := SomaskanInstance.new()
	instance.uid = "%s-%d-%d" % [String(species_data.id), Time.get_unix_time_from_system(), randi()]
	instance.species = species_data
	instance.level = maxi(1, at_level)
	instance.current_hp = species_data.max_hp_at_level(instance.level)
	for move in species_data.learnset:
		if instance.learned_moves.size() >= 4:
			break
		instance.learned_moves.append(move)
	return instance

func max_hp() -> int:
	return species.max_hp_at_level(level) if species != null else 1

func is_fainted() -> bool:
	return current_hp <= 0

func to_dict() -> Dictionary:
	var move_ids: Array[String] = []
	for move in learned_moves:
		move_ids.append(String(move.id))
	return {"uid":uid,"species_id":String(species.id) if species != null else "","nickname":nickname,"level":level,"xp":xp,"current_hp":current_hp,"status":String(status_id),"moves":move_ids}
