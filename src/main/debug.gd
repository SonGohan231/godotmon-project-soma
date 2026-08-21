extends Node

# SOMADEX V2 vertical-slice bootstrap.
# Production direction: real TileMapLayer world, scene-based player/NPC/UI,
# touch controls and reusable interaction/dialogue/battle systems.

func _ready() -> void:
	await get_tree().process_frame

	ScenesManager.add_scene("res://assets/maps/vela/vela.tscn", ScenesManager.SceneType.WORLD)
	ScenesManager.add_scene("res://assets/templates/somadex_player.tscn", ScenesManager.SceneType.ENTITY, Vector2i(5, 5))
	ScenesManager.add_scene("res://assets/ui/dialogue_box.tscn", ScenesManager.SceneType.UI)
	ScenesManager.add_scene("res://assets/ui/battle_screen.tscn", ScenesManager.SceneType.UI)
	ScenesManager.add_scene("res://assets/ui/mobile_controls.tscn", ScenesManager.SceneType.UI)

	# Visual QA mode used by CI. Captures the actual Godot runtime viewport.
	if OS.has_environment("SOMADEX_CAPTURE_PATH"):
		await get_tree().process_frame
		var qa_mode := OS.get_environment("SOMADEX_QA_MODE")
		if qa_mode == "dialogue":
			var lira := get_tree().root.get_node_or_null("Main/WorldParent/Vela/Lira")
			if lira != null:
				lira.interact()
		elif qa_mode == "battle":
			var battle := get_tree().get_first_node_in_group("battle_ui")
			if battle != null:
				battle.start_battle(&"nucik", 3, Vector2.ZERO)
				battle._finish_message()
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
