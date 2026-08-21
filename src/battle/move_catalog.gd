extends RefCounted
class_name SomadexMoveCatalog

const MOVE_NAMES := {
	"KONTAKT":["Sprzężenie","Ślizg Kontrolny","Docisk Kierunkowy","Reset Napięcia"],
	"NERW":["Impuls","Refleks","Przewodzenie","Wyciszenie"],
	"REZONANS":["Mikrodrganie","Echo","Dostrojenie","Regulacja"],
	"PIEZO":["Iskra Piezo","Ładunek Warstwowy","Przebicie Pola","Rozładowanie"],
	"ODDECH":["Fala Oddechu","Rytm Przepony","Podmuch","Spokojny Wydech"],
	"GRAWITACJA":["Dociążenie","Moment Siły","Grawipuls","Odciążenie"],
	"PLYN":["Gradient","Przepływ","Fala Ciśnienia","Drenaż"],
	"OGIEN":["Ciepły Puls","Żar Tkanki","Rozbłysk","Termoregulacja"],
	"WODA":["Strumień","Przypływ","Wir Wody","Chłodny Reset"],
	"DREWNO":["Pęd","Elastyczne Pnącze","Zielony Łuk","Regeneracja"],
	"ZIEMIA":["Uziemienie","Skalny Docisk","Fundament","Stabilizacja"],
	"METAL":["Metaliczny Ton","Cięcie Granicy","Twardy Impuls","Polerowanie"],
	"MISTYCZNE":["Skupienie Qi","Krąg Uwagowy","Mantra Rezonansu","Medytacja"]
}

const LEGACY_ALIAS := {
	"puls":"nerw_1","slizg":"kontakt_2","rezonans":"rezonans_3","reset":"kontakt_4",
	"impuls":"nerw_1","mikrodrganie":"rezonans_1","ucisk":"kontakt_3","regulacja":"rezonans_4",
	"fala":"rezonans_1","napiecie":"kontakt_2","oscylacja":"rezonans_3","uziemienie":"ziemia_4",
	"blysk_veli":"piezo_1","echo":"rezonans_2","przebicie":"piezo_3","oddech":"oddech_4"
}

static func get_move(move_id: StringName) -> Dictionary:
	var id := String(move_id)
	id = String(LEGACY_ALIAS.get(id, id))
	for type_name in SomadexTypeChart.TYPES:
		for index in 4:
			var candidate := _natural_move(type_name, index)
			if String(candidate.id) == id:
				return candidate
	var tm := TechniqueCatalog.move_for_id(StringName(id))
	return tm.duplicate(true) if !tm.is_empty() else _natural_move("KONTAKT", 0)

static func natural_moves(types: Array, stage: int = 1) -> Array:
	var primary := String(types[0]) if !types.is_empty() else "KONTAKT"
	var secondary := String(types[1]) if types.size() > 1 else primary
	return [
		_natural_move(primary, 0, stage),
		_natural_move(secondary, 1, stage),
		_natural_move(primary, 2, stage),
		_natural_move(secondary, 3, stage)
	]

static func natural_move_ids(types: Array, stage: int = 1) -> Array[StringName]:
	var out: Array[StringName] = []
	for move in natural_moves(types, stage):
		out.append(StringName(move.id))
	return out

static func _natural_move(type_name: String, slot: int, stage: int = 1) -> Dictionary:
	var type_key := type_name.to_upper()
	if !MOVE_NAMES.has(type_key):
		type_key = "KONTAKT"
	var names: Array = MOVE_NAMES[type_key]
	var power_table := [7, 9, 11, -7]
	var accuracy_table := [1.0, 0.92, 0.84, 1.0]
	var stage_power := maxi(0, stage - 1)
	var power := int(power_table[slot])
	if power > 0:
		power += stage_power
	elif power < 0:
		power -= stage_power
	return {
		"id":"%s_%d" % [type_key.to_lower(), slot + 1],
		"name":String(names[slot]),
		"type":type_key,
		"power":power,
		"accuracy":float(accuracy_table[slot]),
		"resonance_gain":[7,9,11,8][slot],
		"priority":0
	}
