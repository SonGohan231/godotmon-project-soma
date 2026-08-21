extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if BattleStatus.status_for_type("OGIEN") != BattleStatus.PRZEGRZANIE:
		_fail("OGIEN must map to PRZEGRZANIE")
		return
	if BattleStatus.status_for_type("PIEZO") != BattleStatus.NAPIECIE:
		_fail("PIEZO must map to NAPIECIE")
		return
	if BattleStatus.incoming_type_multiplier(BattleStatus.MOKRY, &"PIEZO") <= 1.0:
		_fail("MOKRY must amplify PIEZO damage")
		return
	if BattleStatus.incoming_type_multiplier(BattleStatus.MOKRY, &"OGIEN") >= 1.0:
		_fail("MOKRY must soften OGIEN damage")
		return

	var attacker: Dictionary = {"types":["PIEZO"],"attack":12}
	var defender: Dictionary = {"types":["ODDECH"],"defense":12}
	var moves: Array = [
		{"id":"neutral","type":"KONTAKT","power":11,"accuracy":1.0,"status_chance":0.0},
		{"id":"piezo","type":"PIEZO","power":10,"accuracy":0.95,"status":BattleStatus.NAPIECIE,"status_chance":0.2}
	]
	if SomadexBattleAI.choose_move(moves, attacker, defender, 1.0, "") != 1:
		_fail("AI did not choose the advantageous PIEZO move")
		return

	var luzik: Dictionary = CreatureDex.get_species(&"luzik")
	var level: int = int(luzik.get("evolution_level", 0)) - 1
	var hp: int = SomadexBattleMath.max_hp(luzik, level)
	var member: Dictionary = {"uid":"evo-test","species_id":"luzik","nickname":"","level":level,"xp":0,"current_hp":hp,"status":"","moves":SomadexMoveCatalog.natural_move_ids(Array(luzik.types), 1)}
	var first: Dictionary = CreatureProgression.apply_xp(member, CreatureProgression.xp_to_next(level))
	var first_member: Dictionary = first.get("member", {})
	if String(first_member.get("species_id", "")) != "warstwin":
		_fail("Luzik did not evolve into Warstwin")
		return
	if int(first.get("levels_gained", 0)) != 1 || Array(first.get("evolutions", [])).size() != 1:
		_fail("first evolution result did not report the level/evolution")
		return

	var second_target: Dictionary = CreatureDex.get_species(&"warstwin")
	var final_level: int = int(second_target.get("evolution_level", 0))
	var xp_needed: int = 0
	for current_level in range(int(first_member.level), final_level):
		xp_needed += CreatureProgression.xp_to_next(current_level)
	var second: Dictionary = CreatureProgression.apply_xp(first_member, xp_needed)
	var final_member: Dictionary = second.get("member", {})
	if String(final_member.get("species_id", "")) != "synkronaut":
		_fail("Warstwin did not evolve into Synkronaut")
		return

	var state_script = load("res://src/autoloads/game_state.gd")
	var state = state_script.new()
	state.reset_new_game()
	var starter: Dictionary = state.party[0]
	starter["species_id"] = "luzik"
	starter["level"] = level
	starter["xp"] = CreatureProgression.xp_to_next(level) - 1
	starter["current_hp"] = SomadexBattleMath.max_hp(luzik, level)
	state.party[0] = starter
	var award: Dictionary = state.award_somaskan_xp(0, 1)
	if String(state.party[0].get("species_id", "")) != "warstwin" || Array(award.get("evolutions", [])).is_empty():
		_fail("GameState did not persist evolution")
		return
	if !state.is_caught(CreatureDex.dex_index_for_species(&"warstwin")):
		_fail("evolved form was not registered as caught in SOMADEX")
		return

	var v2: Dictionary = state.to_dict()
	v2["version"] = 2
	var v2_party: Array = []
	for raw in Array(v2.get("party", [])):
		if typeof(raw) == TYPE_DICTIONARY:
			var old_member: Dictionary = Dictionary(raw).duplicate(true)
			old_member.erase("friendship")
			old_member.erase("battles_won")
			v2_party.append(old_member)
	v2["party"] = v2_party
	var migrated = state_script.new()
	if !migrated.apply_dict(v2):
		_fail("save v2 did not migrate to v3")
		return
	if !migrated.party[0].has("friendship") || !migrated.party[0].has("battles_won"):
		_fail("v3 progression defaults missing after migration")
		return

	print("SOMADEX_PROGRESSION_STATUS_AI_PASS")
	quit(0)

func _fail(message: String) -> void:
	push_error("SOMADEX_PROGRESSION_STATUS_AI_FAIL: " + message)
	quit(1)
