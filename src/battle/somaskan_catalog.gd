extends RefCounted
class_name SomaskanCatalog

static func get_species(species_id: StringName) -> Dictionary:
	var id := String(species_id)
	var catalog := {
		"nucik": {
			"name":"Nucik","max_hp":28,"speed":11,"capture_rate":0.58,"rarity":"common",
			"moves":[
				{"id":"impuls","name":"Impuls","power":7,"accuracy":0.95,"type":"NERW","resonance_gain":8},
				{"id":"mikrodrganie","name":"Mikrodrganie","power":5,"accuracy":1.0,"type":"REZONANS","resonance_gain":16},
				{"id":"ucisk","name":"Ucisk","power":8,"accuracy":0.85,"type":"TKANKA","resonance_gain":6},
				{"id":"regulacja","name":"Regulacja","power":-5,"accuracy":1.0,"type":"ODNOWA","resonance_gain":7}
			]
		},
		"wahlik": {
			"name":"Wahlik","max_hp":34,"speed":8,"capture_rate":0.46,"rarity":"uncommon",
			"moves":[
				{"id":"fala","name":"Fala","power":8,"accuracy":0.95,"type":"REZONANS","resonance_gain":17},
				{"id":"napiecie","name":"Napięcie","power":9,"accuracy":0.82,"type":"POWIĘŹ","resonance_gain":8},
				{"id":"oscylacja","name":"Oscylacja","power":6,"accuracy":1.0,"type":"FALA","resonance_gain":15},
				{"id":"uziemienie","name":"Uziemienie","power":-6,"accuracy":1.0,"type":"ODNOWA","resonance_gain":7}
			]
		},
		"vela_rare": {
			"name":"Velaris","max_hp":42,"speed":13,"capture_rate":0.24,"rarity":"rare",
			"moves":[
				{"id":"blysk_veli","name":"Błysk Veli","power":10,"accuracy":0.9,"type":"ŚWIATŁO","resonance_gain":9},
				{"id":"echo","name":"Echo","power":8,"accuracy":0.95,"type":"REZONANS","resonance_gain":18},
				{"id":"przebicie","name":"Przebicie","power":11,"accuracy":0.78,"type":"IMPULS","resonance_gain":8},
				{"id":"oddech","name":"Oddech","power":-7,"accuracy":1.0,"type":"ODNOWA","resonance_gain":7}
			]
		},
		"starter": {
			"name":"Somari","max_hp":40,"speed":12,"capture_rate":0.0,"rarity":"starter",
			"moves":[
				{"id":"puls","name":"Puls","power":8,"accuracy":0.95,"type":"NERW","resonance_gain":12},
				{"id":"slizg","name":"Ślizg","power":7,"accuracy":1.0,"type":"POWIĘŹ","resonance_gain":9},
				{"id":"rezonans","name":"Rezonans","power":9,"accuracy":0.9,"type":"FALA","resonance_gain":18},
				{"id":"reset","name":"Reset","power":-6,"accuracy":1.0,"type":"ODNOWA","resonance_gain":7}
			]
		}
	}
	return Dictionary(catalog.get(id, catalog["nucik"])).duplicate(true)

static func move_ids(species_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	var species := get_species(species_id)
	for move_variant in Array(species.get("moves", [])):
		var move: Dictionary = move_variant
		result.append(StringName(move.get("id", "")))
	return result
