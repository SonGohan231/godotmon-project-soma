extends RefCounted
class_name TechniqueCatalog

const PAIRS := {
	"KONTAKT":["TM0001|Precyzyjne Sprzężenie|10|0.96","TM0002|Kontraślizg|12|0.88"],
	"NERW":["TM0003|Łuk Odruchowy|10|0.95","TM0004|Synaptyczny Skok|13|0.84"],
	"REZONANS":["TM0005|Harmoniczne Echo|11|0.94","TM0006|Faza Krytyczna|13|0.85"],
	"PIEZO":["TM0007|Piezoiskra|11|0.93","TM0008|Napięcie Kryształu|14|0.82"],
	"ODDECH":["TM0009|Oddech Falowy|10|0.96","TM0010|Przeponowy Wir|12|0.88"],
	"GRAWITACJA":["TM0011|Oś Ciężaru|11|0.94","TM0012|Grawicentrum|14|0.82"],
	"PLYN":["TM0013|Gradient Tkankowy|10|0.96","TM0014|Hydropuls|12|0.89"],
	"OGIEN":["TM0015|Termiczny Impuls|11|0.94","TM0016|Żar Przemiany|14|0.83"],
	"WODA":["TM0017|Błękitny Przepływ|10|0.96","TM0018|Wir Głębin|13|0.85"],
	"DREWNO":["TM0019|Elastyczny Pęd|10|0.95","TM0020|Smocze Pnącze|13|0.85"],
	"ZIEMIA":["TM0021|Kotwica Podłoża|11|0.94","TM0022|Tektoniczny Docisk|14|0.82"],
	"METAL":["TM0023|Metaliczna Granica|11|0.93","TM0024|Jadeitowe Cięcie|13|0.85"],
	"MISTYCZNE":["TM0025|Krąg Dantian|10|0.96","TM0026|Mantra Pięciu Przemian|13|0.86"]
}

static func all() -> Array:
	var out: Array = []
	for type_name in SomadexTypeChart.TYPES:
		for packed in Array(PAIRS.get(type_name, [])):
			out.append(_decode(type_name, String(packed)))
	return out

static func count() -> int:
	return all().size()

static func get_tm(tm_id: StringName) -> Dictionary:
	var wanted := String(tm_id).to_upper()
	for tm in all():
		if String(tm.tm_id) == wanted:
			return tm
	return {}

static func move_for_id(move_id: StringName) -> Dictionary:
	var tm := get_tm(move_id)
	return Dictionary(tm.get("move", {})).duplicate(true) if !tm.is_empty() else {}

static func compatible(species_types: Array, tm_id: StringName) -> bool:
	var tm := get_tm(tm_id)
	if tm.is_empty():
		return false
	var wanted := String(tm.type)
	for t in species_types:
		if String(t).to_upper() == wanted:
			return true
	return false

static func _decode(type_name: String, packed: String) -> Dictionary:
	var p := packed.split("|")
	var tm_id := p[0]
	var power := int(p[2])
	var accuracy := float(p[3])
	return {
		"tm_id":tm_id,
		"name":p[1],
		"type":type_name,
		"description":"Technika %s. Uczy nowego ruchu typu %s." % [tm_id, type_name],
		"move":{
			"id":tm_id,
			"name":p[1],
			"type":type_name,
			"power":power,
			"accuracy":accuracy,
			"resonance_gain":12,
			"priority":0,
			"source":"TM"
		}
	}
