extends SceneTree

func _init() -> void:
	var state_script = load("res://src/autoloads/game_state.gd")
	if state_script == null:
		_fail("GameState script did not load")
		return

	var state = state_script.new()
	state.reset_new_game()
	if state.party.size() != 1:
		_fail("new game must start with exactly one Somaskan")
		return
	if state.add_item(&"capsule", 2) != 5:
		_fail("inventory arithmetic failed")
		return
	if !state.consume_item(&"capsule", 1):
		_fail("inventory consume failed")
		return
	state.add_trainer_xp(90)
	if int(state.trainer.level) < 2 || int(state.trainer.skill_points) < 1:
		_fail("trainer progression failed")
		return
	state.unlock_trainer_path(&"badacz")
	if !state.choose_trainer_path(&"badacz"):
		_fail("trainer path selection failed")
		return
	state.add_captured_somaskan(&"nucik", 3, 30, [&"impuls", &"mikrodrganie", &"ucisk", &"regulacja"])
	if state.party.size() != 2:
		_fail("captured Somaskan was not added to party")
		return
	state.set_world_spawn(&"vela", Vector2i(11, 7), Vector2i.LEFT)

	var smoke_path := "user://somadex_state_smoke.json"
	if state.save_game(smoke_path) != OK:
		_fail("save_game returned an error")
		return

	var loaded = state_script.new()
	if !loaded.load_game(smoke_path):
		_fail("load_game failed")
		return
	if int(loaded.world.tile_x) != 11 || int(loaded.world.tile_y) != 7:
		_fail("world position did not survive save/load")
		return
	if int(loaded.bag.capsule) != 4:
		_fail("bag did not survive save/load")
		return
	if loaded.party.size() != 2:
		_fail("party did not survive save/load")
		return
	if String(loaded.trainer.chosen_path) != "badacz":
		_fail("trainer path did not survive save/load")
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(smoke_path))
	print("SOMADEX_GAME_STATE_SMOKE_PASS")
	quit(0)

func _fail(message: String) -> void:
	push_error("SOMADEX_GAME_STATE_SMOKE_FAIL: " + message)
	quit(1)
