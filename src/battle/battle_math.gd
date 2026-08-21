extends RefCounted
class_name SomadexBattleMath

static func max_hp(species: Dictionary, level: int) -> int:
	return maxi(1, int(species.get("max_hp", 20)) + maxi(0, level - 1) * 2)

static func damage(move: Dictionary, attacker_level: int, defender_level: int, attacker: Dictionary, defender: Dictionary, random_factor: float = 1.0) -> Dictionary:
	var attack_type := StringName(move.get("type", "KONTAKT"))
	var attacker_types: Array = attacker.get("types", ["KONTAKT"])
	var defender_types: Array = defender.get("types", ["KONTAKT"])
	var effectiveness := SomadexTypeChart.effectiveness(attack_type, defender_types)
	var total := SomadexTypeChart.total_multiplier(attack_type, attacker_types, defender_types)
	var attack_stat := maxf(1.0, float(attacker.get("attack", 10)))
	var defense_stat := maxf(1.0, float(defender.get("defense", 10)))
	var stat_ratio := clampf(attack_stat / defense_stat, 0.68, 1.42)
	var base := float(move.get("power", 1)) * (0.70 + maxi(1, attacker_level) * 0.038) * stat_ratio
	var dealt := maxi(1, int(round(base * total * clampf(random_factor, 0.90, 1.10))))
	var defender_hp := max_hp(defender, defender_level)
	dealt = mini(dealt, maxi(2, int(round(defender_hp * 0.48))))
	return {"damage":dealt,"effectiveness":effectiveness,"stab":SomadexTypeChart.stab(attack_type, attacker_types),"total":total}

static func expected_hits_to_ko(move: Dictionary, attacker_level: int, defender_level: int, attacker: Dictionary, defender: Dictionary) -> int:
	if int(move.get("power", 0)) <= 0:
		return 999
	var dealt := int(damage(move, attacker_level, defender_level, attacker, defender, 1.0).damage)
	return int(ceil(float(max_hp(defender, defender_level)) / maxf(1.0, float(dealt))))
