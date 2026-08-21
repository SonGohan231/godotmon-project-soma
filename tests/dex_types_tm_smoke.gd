extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state_script = load("res://src/autoloads/game_state.gd")
	if state_script == null:
		_fail("GameState could not be loaded")
		return
	var entries := CreatureDex.all_entries()
	if entries.size() != 150:
		_fail("Somadex must contain exactly 150 forms")
		return
	var names := {}
	var ids := {}
	var fallback_count := 0
	var hit_sum := 0.0
	var hit_samples := 0
	for i in entries.size():
		var entry: Dictionary = entries[i]
		if int(entry.get("dex_index", 0)) != i + 1:
			_fail("Somadex numbering is not contiguous at %d" % (i + 1))
			return
		var species_id := String(entry.get("species_id", ""))
		var display_name := String(entry.get("name", ""))
		if species_id.is_empty() || ids.has(species_id) || display_name.is_empty() || names.has(display_name):
			_fail("Somadex IDs/names must be non-empty and unique")
			return
		ids[species_id] = true
		names[display_name] = true
		var types: Array = entry.get("types", [])
		if types.is_empty() || types.size() > 2:
			_fail("every form must have one or two combat types")
			return
		for type_name in types:
			if !SomadexTypeChart.TYPES.has(String(type_name)):
				_fail("unsupported combat type: %s" % type_name)
				return
		var moves := SomaskanCatalog.get_species(StringName(species_id)).get("moves", []) as Array
		if moves.size() != 4:
			_fail("every form must expose four battle moves")
			return
		if bool(Dictionary(entry.get("art", {})).get("fallback_complete", false)):
			fallback_count += 1
		var defender: Dictionary = entries[(i + 17) % entries.size()]
		var move: Dictionary = moves[0]
		var hits := SomadexBattleMath.expected_hits_to_ko(move, 20, 20, entry, defender)
		if hits < 2 || hits > 18:
			_fail("battle pace escaped safe band for %s: %d hits" % [display_name, hits])
			return
		hit_sum += hits
		hit_samples += 1
	if fallback_count != 150:
		_fail("all 150 forms need front/back/mini runtime fallback coverage")
		return
	var average_hits := hit_sum / maxf(1.0, float(hit_samples))
	if average_hits < 3.0 || average_hits > 9.0:
		_fail("average equal-level battle pace out of balance: %.2f hits" % average_hits)
		return

	if SomadexTypeChart.effectiveness(&"OGIEN", ["DREWNO"]) <= 1.0:
		_fail("OGIEN must be strong into DREWNO")
		return
	if SomadexTypeChart.effectiveness(&"WODA", ["OGIEN"]) <= 1.0:
		_fail("WODA must be strong into OGIEN")
		return
	if SomadexTypeChart.effectiveness(&"PIEZO", ["ODDECH"]) <= 1.0:
		_fail("PIEZO must punish ODDECH")
		return
	if SomadexTypeChart.effectiveness(&"PIEZO", ["ZIEMIA"]) >= 1.0:
		_fail("PIEZO must have low effect into ZIEMIA")
		return

	var tms := TechniqueCatalog.all()
	if tms.size() != 26:
		_fail("TM catalog must contain 26 new techniques")
		return
	for i in tms.size():
		var tm: Dictionary = tms[i]
		if String(tm.tm_id) != "TM%04d" % (i + 1):
			_fail("TM IDs must be contiguous TM0001..TM0026")
			return
		var move: Dictionary = tm.move
		if int(move.power) < 10 || int(move.power) > 14 || float(move.accuracy) < 0.80 || float(move.accuracy) > 1.0:
			_fail("TM move outside balance envelope: %s" % tm.tm_id)
			return

	var state = state_script.new()
	state.reset_new_game()
	if state.seen_count() != 1 || state.caught_count() != 1 || !state.has_tm(&"TM0001"):
		_fail("new-game Somadex/TM bootstrap is incomplete")
		return
	if !state.teach_tm(0, &"TM0001", 0):
		_fail("compatible TM could not be taught")
		return
	if String(state.party[0].moves[0]) != "TM0001":
		_fail("taught TM did not persist in member move slot")
		return
	var resolved := SomaskanCatalog.resolve_moves(Array(state.party[0].moves), &"starter")
	if String(resolved[0].id) != "TM0001":
		_fail("battle catalog did not resolve taught TM")
		return

	var v1 := {
		"version":1,"trainer":{"name":"T","level":2,"xp":5,"skill_points":1,"chosen_path":"","unlocked_paths":[]},
		"party":[{"uid":"old","species_id":"nucik","nickname":"","level":4,"xp":0,"current_hp":20,"status":"","moves":["impuls","mikrodrganie","ucisk","regulacja"]}],
		"storage":[],"bag":{"capsule":1,"bandage":1},"quest_flags":{},"world":{"map_id":"vela","tile_x":5,"tile_y":5,"facing_x":0,"facing_y":1}
	}
	var migrated = state_script.new()
	if !migrated.apply_dict(v1) || migrated.seen_count() < 1 || migrated.caught_count() < 1 || !migrated.has_tm(&"TM0001"):
		_fail("save v1 did not migrate safely to v2")
		return
	print("SOMADEX_DEX_TYPES_TM_PASS forms=150 tms=26 avg_hits=%.2f fallbacks=150" % average_hits)
	quit(0)

func _fail(message: String) -> void:
	push_error("SOMADEX_DEX_TYPES_TM_FAIL: " + message)
	quit(1)
