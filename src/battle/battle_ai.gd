extends RefCounted
class_name SomadexBattleAI

static func choose_move(moves: Array, attacker: Dictionary, defender: Dictionary, attacker_hp_ratio: float, target_status: String) -> int:
	if moves.is_empty():
		return -1
	var best_index := 0
	var best_score := -99999.0
	for i in moves.size():
		var move: Dictionary = moves[i]
		var score := _score_move(move, attacker, defender, attacker_hp_ratio, target_status)
		# Stable tie-breaker keeps AI deterministic enough for tests and reproducible balancing.
		score -= float(i) * 0.001
		if score > best_score:
			best_score = score
			best_index = i
	return best_index

static func _score_move(move: Dictionary, attacker: Dictionary, defender: Dictionary, attacker_hp_ratio: float, target_status: String) -> float:
	var power := int(move.get("power", 0))
	var accuracy := clampf(float(move.get("accuracy", 1.0)), 0.1, 1.0)
	if power < 0:
		if attacker_hp_ratio <= 0.28:
			return 90.0 + absf(float(power))
		if attacker_hp_ratio <= 0.50:
			return 35.0 + absf(float(power))
		return -25.0
	if power <= 0:
		return -10.0
	var type_name := StringName(move.get("type", "KONTAKT"))
	var defender_types: Array = defender.get("types", ["KONTAKT"])
	var attacker_types: Array = attacker.get("types", ["KONTAKT"])
	var eff := SomadexTypeChart.effectiveness(type_name, defender_types)
	var stab := SomadexTypeChart.stab(type_name, attacker_types)
	var score := float(power) * accuracy * eff * stab
	if target_status.is_empty() && BattleStatus.status_chance(move) > 0.0:
		score += BattleStatus.status_chance(move) * 12.0
	if accuracy >= 0.94:
		score += 1.2
	return score
