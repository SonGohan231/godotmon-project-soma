extends RefCounted
class_name SomaskanCatalog

static func get_species(species_id: StringName) -> Dictionary:
	var id := String(species_id)
	var catalog := {
		"nucik": {
			"name": "Nucik",
			"max_hp": 28,
			"speed": 11,
			"moves": [
				{"name": "Impuls", "power": 7, "accuracy": 0.95, "type": "NERW"},
				{"name": "Mikrodrganie", "power": 5, "accuracy": 1.0, "type": "REZONANS"},
				{"name": "Ucisk", "power": 8, "accuracy": 0.85, "type": "TKANKA"},
				{"name": "Regulacja", "power": -5, "accuracy": 1.0, "type": "ODNOWA"}
			]
		},
		"wahlik": {
			"name": "Wahlik",
			"max_hp": 34,
			"speed": 8,
			"moves": [
				{"name": "Fala", "power": 8, "accuracy": 0.95, "type": "REZONANS"},
				{"name": "Napięcie", "power": 9, "accuracy": 0.82, "type": "POWIĘŹ"},
				{"name": "Oscylacja", "power": 6, "accuracy": 1.0, "type": "FALA"},
				{"name": "Uziemienie", "power": -6, "accuracy": 1.0, "type": "ODNOWA"}
			]
		},
		"vela_rare": {
			"name": "Velaris",
			"max_hp": 42,
			"speed": 13,
			"moves": [
				{"name": "Błysk Veli", "power": 10, "accuracy": 0.9, "type": "ŚWIATŁO"},
				{"name": "Echo", "power": 8, "accuracy": 0.95, "type": "REZONANS"},
				{"name": "Przebicie", "power": 11, "accuracy": 0.78, "type": "IMPULS"},
				{"name": "Oddech", "power": -7, "accuracy": 1.0, "type": "ODNOWA"}
			]
		},
		"starter": {
			"name": "Somari",
			"max_hp": 40,
			"speed": 12,
			"moves": [
				{"name": "Puls", "power": 8, "accuracy": 0.95, "type": "NERW"},
				{"name": "Ślizg", "power": 7, "accuracy": 1.0, "type": "POWIĘŹ"},
				{"name": "Rezonans", "power": 9, "accuracy": 0.9, "type": "FALA"},
				{"name": "Reset", "power": -6, "accuracy": 1.0, "type": "ODNOWA"}
			]
		}
	}
	return catalog.get(id, catalog["nucik"]).duplicate(true)
