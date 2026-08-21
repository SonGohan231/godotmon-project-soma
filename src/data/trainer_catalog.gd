extends RefCounted
class_name SomadexTrainerCatalog

const TRAINERS := {
	"vela_scout": {
		"name":"Mira",
		"title":"Zwiadowczyni Veli",
		"intro":"Sprawdźmy, czy potrafisz czytać rytm walki.",
		"outro":"Dobra walka. Vela może cię przepuścić dalej.",
		"reward":90,
		"trainer_xp":35,
		"party":[
			{"species_id":"nucik","level":5},
			{"species_id":"wahlik","level":6}
		]
	},
	"vela_adept": {
		"name":"Toren",
		"title":"Adept Rezonansu",
		"intro":"Nie wygrasz samą siłą. Pokaż zmianę tempa.",
		"outro":"Rozumiesz już więcej niż większość początkujących.",
		"reward":140,
		"trainer_xp":55,
		"party":[
			{"species_id":"wahlik","level":7},
			{"species_id":"vela_rare","level":7},
			{"species_id":"nucik","level":8}
		]
	}
}

static func get_trainer(trainer_id: StringName) -> Dictionary:
	return Dictionary(TRAINERS.get(String(trainer_id), {})).duplicate(true)

static func defeated_flag(trainer_id: StringName) -> StringName:
	return StringName("trainer_defeated_%s" % String(trainer_id))

static func validate_all() -> Dictionary:
	var errors: Array[String] = []
	for id in TRAINERS.keys():
		var trainer: Dictionary = TRAINERS[id]
		var party: Array = trainer.get("party", [])
		if party.is_empty():
			errors.append("%s has empty party" % id)
		for member_variant in party:
			var member: Dictionary = member_variant
			var species_id := StringName(member.get("species_id", ""))
			if CreatureDex.dex_index_for_species(species_id) <= 0:
				errors.append("%s has unknown species %s" % [id, species_id])
			if int(member.get("level", 0)) <= 0:
				errors.append("%s has invalid level" % id)
	return {"ok":errors.is_empty(),"errors":errors,"count":TRAINERS.size()}
