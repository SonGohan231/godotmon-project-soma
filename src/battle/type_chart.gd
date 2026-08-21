extends RefCounted
class_name SomadexTypeChart

const TYPES := ["KONTAKT","NERW","REZONANS","PIEZO","ODDECH","GRAWITACJA","PLYN","OGIEN","WODA","DREWNO","ZIEMIA","METAL","MISTYCZNE"]
const STAB := 1.20

const EFFECTS := {
	"OGIEN":{"DREWNO":2.0,"METAL":1.5,"WODA":0.5,"ZIEMIA":0.75},
	"WODA":{"OGIEN":2.0,"GRAWITACJA":1.5,"DREWNO":0.5,"PIEZO":0.75},
	"DREWNO":{"WODA":2.0,"ZIEMIA":1.5,"OGIEN":0.5,"METAL":0.75},
	"METAL":{"DREWNO":1.5,"GRAWITACJA":1.5,"OGIEN":0.5,"PIEZO":0.75},
	"ZIEMIA":{"PIEZO":2.0,"OGIEN":1.25,"WODA":0.5,"DREWNO":0.75},
	"PIEZO":{"ODDECH":2.0,"WODA":1.5,"ZIEMIA":0.5,"GRAWITACJA":0.5},
	"ODDECH":{"GRAWITACJA":1.5,"REZONANS":1.25,"METAL":0.75,"PIEZO":0.5},
	"GRAWITACJA":{"ODDECH":2.0,"METAL":1.25,"WODA":0.5,"DREWNO":0.75},
	"NERW":{"KONTAKT":1.5,"REZONANS":1.25,"MISTYCZNE":0.75,"METAL":0.75},
	"REZONANS":{"NERW":1.5,"MISTYCZNE":1.25,"GRAWITACJA":0.75},
	"KONTAKT":{"REZONANS":1.25,"METAL":0.75,"GRAWITACJA":0.75},
	"PLYN":{"GRAWITACJA":1.5,"KONTAKT":1.25,"PIEZO":0.75,"ZIEMIA":0.75},
	"MISTYCZNE":{"NERW":1.25,"ODDECH":1.25,"METAL":0.75,"ZIEMIA":0.75}
}

static func effectiveness(attack_type: StringName, defender_types: Array) -> float:
	var attack := String(attack_type).to_upper()
	var multiplier := 1.0
	var row: Dictionary = EFFECTS.get(attack, {})
	for defender in defender_types:
		multiplier *= float(row.get(String(defender).to_upper(), 1.0))
	return clampf(multiplier, 0.40, 2.25)

static func stab(attack_type: StringName, attacker_types: Array) -> float:
	var wanted := String(attack_type).to_upper()
	for t in attacker_types:
		if String(t).to_upper() == wanted:
			return STAB
	return 1.0

static func total_multiplier(attack_type: StringName, attacker_types: Array, defender_types: Array) -> float:
	return stab(attack_type, attacker_types) * effectiveness(attack_type, defender_types)

static func feedback(effectiveness_value: float) -> String:
	if effectiveness_value >= 1.75:
		return " SUPER!"
	if effectiveness_value >= 1.20:
		return " SKUTECZNE!"
	if effectiveness_value <= 0.60:
		return " PRAWIE NIE DZIAŁA..."
	if effectiveness_value < 0.95:
		return " SŁABY EFEKT..."
	return ""
