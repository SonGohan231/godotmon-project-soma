extends Node

# SOMADEX V2 vertical-slice bootstrap.
# World, touch UI, battle, SOMADEX, techniques and persistence all share one runtime.

func _ready() -> void:
	await get_tree().process_frame

	ScenesManager.add_scene("res://assets/maps/vela/vela.tscn", ScenesManager.SceneType.WORLD)
	ScenesManager.add_scene("res://assets/templates/somadex_player.tscn", ScenesManager.SceneType.ENTITY, Vector2i(5, 5))
	ScenesManager.add_scene("res://assets/ui/dialogue_box.tscn", ScenesManager.SceneType.UI)
	ScenesManager.add_scene("res://assets/ui/battle_screen_advanced.tscn", ScenesManager.SceneType.UI)
	ScenesManager.add_scene("res://assets/ui/start_menu_pixel.tscn", ScenesManager.SceneType.UI)
	ScenesManager.add_scene("res://assets/ui/mobile_controls.tscn", ScenesManager.SceneType.UI)

	if OS.has_environment("SOMADEX_CAPTURE_PATH"):
		await get_tree().process_frame
		var qa_mode := OS.get_environment("SOMADEX_QA_MODE")
		if qa_mode == "dialogue":
			var lira := get_tree().root.get_node_or_null("Main/WorldParent/Vela/Lira")
			if lira != null:
				lira.interact()
		elif qa_mode.begins_with("menu"):
			var menu := get_tree().get_first_node_in_group("start_menu") as SomadexStartMenu
			if menu != null:
				menu.open_menu()
				match qa_mode:
					"menu_party": menu._open_roster()
					"menu_dex": menu._open_dex()
					"menu_tm": menu._open_tm()
		elif qa_mode.begins_with("battle"):
			var battle := get_tree().get_first_node_in_group("battle_ui") as BattleScreen
			if battle != null:
				if qa_mode == "battle_party":
					GameState.add_captured_somaskan(&"nucik", 4, 18, SomaskanCatalog.move_ids(&"nucik"))
				battle.start_battle(&"wahlik", 4, Vector2(160, 96))
				battle._finish_message()
				match qa_mode:
					"battle_party": battle._open_party(false)
					"battle_bag": battle._open_bag()
					"battle_rez":
						battle._resonance.value = ResonanceState.MAX_VALUE
						battle._set_mode(BattleScreen.Mode.MOVES)
						battle._refresh_resonance()
		await get_tree().create_timer(0.35).timeout
		_capture_runtime(OS.get_environment("SOMADEX_CAPTURE_PATH"))
		return

	await get_tree().create_timer(2).timeout
	GDMUtils.grayscale_transition("uid://cdicmm4o3jggt")
	await Observer.transition_finished
	GDMUtils.grayscale_transition("uid://cdicmm4o3jggt", 0.5, true)

func _capture_runtime(capture_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(capture_path.get_base_dir())
	var image := get_viewport().get_texture().get_image()
	var result := image.save_png(capture_path)
	if result != OK:
		push_error("SOMADEX capture failed: %s" % result)
		get_tree().quit(1)
		return
	print("SOMADEX_VERTICAL_SLICE_CAPTURED: %s" % capture_path)
	get_tree().quit()
