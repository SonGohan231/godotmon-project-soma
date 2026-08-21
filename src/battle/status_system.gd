extends RefCounted
class_name BattleStatus

const NONE := ""
const PRZEGRZANIE := "PRZEGRZANIE"
const NAPIECIE := "NAPIĘCIE"
const ZDRETWIENIE := "ZDRĘTWIENIE"
const MOKRY := "MOKRY"
const ZAKOTWICZENIE := "ZAKOTWICZENIE"
const ROZSTROJENIE := "ROZSTROJENIE"

const TYPE_STATUS := {
	"OGIEN": PRZEGRZANIE,
	"PIEZO": NAPIECIE,
	"NERW": ZDRETWIENIE,
	"WODA": MOKRY,
	"PLYN": MOKRY,
	"ZIEMIA": ZAKOTWICZENIE,
	"GRAWITACJA": ZAKOTWICZENIE,
	"REZONANS": ROZSTROJENIE,
	"MISTYCZNE": ROZSTROJENIE
}

static func status_for_type(type_name: String) -> String:
	return String(TYPE_STATUS.get(type_name.to_upper(), NONE))

static func move_status(move: Dictionary) -> String:
	var explicit := String(move.get("status", ""))
	if !explicit.is_empty():
		return explicit
	return status_for_type(String(move.get("type", "")))

static func status_chance(move: Dictionary) -> float:
	if int(move.get("power", 0)) <= 0:
		return 0.0
	return clampf(float(move.get("status_chance", 0.0)), 0.0, 0.65)

static func try_inflict(current_status: String, move: Dictionary, rng: RandomNumberGenerator) -> String:
	if !current_status.is_empty():
		return current_status
	var candidate := move_status(move)
	if candidate.is_empty():
		return current_status
	if rng.randf() <= status_chance(move):
		return candidate
	return current_status

static func can_act(status: String, rng: RandomNumberGenerator) -> bool:
	match status:
		NAPIECIE: return rng.randf() > 0.20
		ZDRETWIENIE: return rng.randf() > 0.14
		_: return true

static func accuracy_multiplier(status: String) -> float:
	match status:
		NAPIECIE: return 0.92
		ZDRETWIENIE: return 0.90
		ROZSTROJENIE: return 0.86
		_: return 1.0

static func attack_multiplier(status: String) -> float:
	return 0.88 if status == PRZEGRZANIE else 1.0

static func defense_multiplier(status: String) -> float:
	return 1.15 if status == ZAKOTWICZENIE else 1.0

static func speed_multiplier(status: String) -> float:
	match status:
		NAPIECIE: return 0.65
		ZAKOTWICZENIE: return 0.75
		_: return 1.0

static func incoming_type_multiplier(status: String, attack_type: StringName) -> float:
	var type_name := String(attack_type)
	if status == MOKRY:
		if type_name == "PIEZO": return 1.25
		if type_name == "OGIEN": return 0.75
	if status == ZAKOTWICZENIE && type_name == "GRAWITACJA":
		return 0.85
	return 1.0

static func residual_damage(status: String, max_hp: int) -> int:
	if status == PRZEGRZANIE:
		return maxi(1, int(ceil(float(max_hp) * 0.06)))
	return 0

static func short_label(status: String) -> String:
	match status:
		PRZEGRZANIE: return "GRZ"
		NAPIECIE: return "NAP"
		ZDRETWIENIE: return "ZDR"
		MOKRY: return "MOK"
		ZAKOTWICZENIE: return "ZAK"
		ROZSTROJENIE: return "ROZ"
		_: return ""
