extends RefCounted
class_name CreatureProgression

const LEVEL_CAP := 80

static func xp_to_next(level: int) -> int:
	var safe_level := clampi(level, 1, LEVEL_CAP)
	return 55 + safe_level * 12

static func defeat_xp(enemy_species: Dictionary, enemy_level: int) -> int:
	var stage := clampi(int(enemy_species.get("stage", 1)), 1, 3)
	var rarity := String(enemy_species.get("rarity", "common"))
	var rarity_bonus := 0
	match rarity:
		"uncommon": rarity_bonus = 8
		"rare": rarity_bonus = 18
		_: rarity_bonus = 0
	return 16 + maxi(1, enemy_level) * 4 + stage * 8 + rarity_bonus

static func apply_xp(member: Dictionary, amount: int) -> Dictionary:
	var updated := member.duplicate(true)
	var result := {
		"member": updated,
		"xp_gained": maxi(0, amount),
		"levels_gained": 0,
		"old_level": int(updated.get("level", 1)),
		"new_level": int(updated.get("level", 1)),
		"evolutions": []
	}
	if amount <= 0:
		return result

	var level := clampi(int(updated.get("level", 1)), 1, LEVEL_CAP)
	var xp := maxi(0, int(updated.get("xp", 0))) + amount
	var species := CreatureDex.get_species(StringName(updated.get("species_id", "starter")))
	var old_max_hp := SomadexBattleMath.max_hp(species, level)
	var old_hp := clampi(int(updated.get("current_hp", old_max_hp)), 0, old_max_hp)
	var hp_ratio := float(old_hp) / maxf(1.0, float(old_max_hp))

	while level < LEVEL_CAP:
		var threshold := xp_to_next(level)
		if xp < threshold:
			break
		xp -= threshold
		level += 1
		result["levels_gained"] = int(result.levels_gained) + 1
		var evolution := _evolution_if_ready(species, level)
		if !evolution.is_empty():
			var old_name := String(species.get("name", ""))
			species = evolution
			updated["species_id"] = String(species.get("species_id", updated.get("species_id", "starter")))
			var evolutions: Array = result.get("evolutions", [])
			evolutions.append({"from":old_name,"to":String(species.get("name", "")),"level":level})
			result["evolutions"] = evolutions

	if level >= LEVEL_CAP:
		level = LEVEL_CAP
		xp = 0

	updated["level"] = level
	updated["xp"] = xp
	var new_max_hp := SomadexBattleMath.max_hp(species, level)
	updated["current_hp"] = clampi(int(round(float(new_max_hp) * hp_ratio)), 1 if old_hp > 0 else 0, new_max_hp)
	result["member"] = updated
	result["new_level"] = level
	return result

static func _evolution_if_ready(species: Dictionary, level: int) -> Dictionary:
	var target := String(species.get("evolves_to", ""))
	var required_level := int(species.get("evolution_level", 0))
	if target.is_empty() || required_level <= 0 || level < required_level:
		return {}
	var next := CreatureDex.get_species(StringName(target))
	if String(next.get("species_id", "")) == String(species.get("species_id", "")):
		return {}
	return next
