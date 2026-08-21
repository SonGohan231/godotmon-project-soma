extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var entries := CreatureDex.all_entries()
	if entries.size() != 150:
		_fail("expected 150 SOMADEX forms")
		return
	var front_ok := 0
	var back_ok := 0
	var mini_ok := 0
	for entry_variant in entries:
		var entry: Dictionary = entry_variant
		var species_id := StringName(entry.get("species_id", ""))
		var front := CreaturePixelArt.battle_texture(species_id, false)
		var back := CreaturePixelArt.battle_texture(species_id, true)
		var mini0 := CreaturePixelArt.mini_texture(species_id, 0)
		var mini1 := CreaturePixelArt.mini_texture(species_id, 1)
		if front == null || front.get_width() != 32 || front.get_height() != 32:
			_fail("front pixel sprite missing for %s" % entry.get("name", species_id))
			return
		front_ok += 1
		if back == null || back.get_width() != 32 || back.get_height() != 32:
			_fail("back pixel sprite missing for %s" % entry.get("name", species_id))
			return
		back_ok += 1
		if mini0 == null || mini1 == null || mini0.get_width() != 16 || mini1.get_width() != 16:
			_fail("two-frame mini sprite missing for %s" % entry.get("name", species_id))
			return
		var front_bytes := front.get_image().get_data()
		var back_bytes := back.get_image().get_data()
		if front_bytes == back_bytes:
			_fail("front/back views are identical for %s" % entry.get("name", species_id))
			return
		var mini0_bytes := mini0.get_image().get_data()
		var mini1_bytes := mini1.get_image().get_data()
		if mini0_bytes == mini1_bytes:
			_fail("mini animation frames are identical for %s" % entry.get("name", species_id))
			return
		mini_ok += 1
	print("SOMADEX_PIXEL_ART_PASS front=%d back=%d mini_pairs=%d" % [front_ok, back_ok, mini_ok])
	quit(0)

func _fail(message: String) -> void:
	push_error("SOMADEX_PIXEL_ART_FAIL: " + message)
	quit(1)
