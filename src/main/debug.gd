extends Node


# SOMADEX V2 vertical-slice bootstrap.
# The goal of this branch is to prove the correct overworld architecture first:
# real TileMapLayer world + CharacterBody2D player + Camera2D + collisions.


func _ready() -> void:
	await get_tree().process_frame
	ScenesManager.add_scene("res://assets/maps/test map.tscn", ScenesManager.SceneType.WORLD)
	ScenesManager.add_scene("res://assets/templates/player.tscn", ScenesManager.SceneType.ENTITY, Vector2i(5, 5))

	# Visual QA mode used by CI. This captures the actual Godot runtime viewport,
	# not a mockup or a separately rendered concept image.
	if OS.has_environment("SOMADEX_CAPTURE_PATH"):
		await get_tree().process_frame
		await get_tree().create_timer(0.35).timeout
		var capture_path := OS.get_environment("SOMADEX_CAPTURE_PATH")
		DirAccess.make_dir_recursive_absolute(capture_path.get_base_dir())
		var image := get_viewport().get_texture().get_image()
		var result := image.save_png(capture_path)
		if result != OK:
			push_error("SOMADEX capture failed: %s" % result)
			get_tree().quit(1)
			return
		print("SOMADEX_VERTICAL_SLICE_CAPTURED: %s" % capture_path)
		get_tree().quit()
		return

	await get_tree().create_timer(2).timeout
	GDMUtils.grayscale_transition("uid://cdicmm4o3jggt")
	await Observer.transition_finished
	GDMUtils.grayscale_transition("uid://cdicmm4o3jggt", 0.5, true)
