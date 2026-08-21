extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	GameState.reset_new_game()
	if GameState.party.size() != 1:
		_fail("starter party missing")
		return
	if int(GameState.bag.get("capsule", 0)) != 3:
		_fail("starter capsules missing")
		return
	var move_ids: Array[StringName] = SomaskanCatalog.move_ids(&"nucik")
	if move_ids.size() != 4:
		_fail("Nucik battle data must expose four moves")
		return
	if !GameState.consume_item(&"capsule", 1):
		_fail("capture item could not be consumed")
		return
	GameState.add_captured_somaskan(&"nucik", 4, 18, move_ids)
	if GameState.party.size() != 2:
		_fail("captured Somaskan did not join party")
		return
	GameState.add_trainer_xp(30)
	GameState.mark_flag(&"first_wild_battle")
	GameState.mark_flag(&"first_wild_capture")
	if !bool(GameState.quest_flags.get("first_wild_battle", false)) || !bool(GameState.quest_flags.get("first_wild_capture", false)):
		_fail("battle/capture progress flags missing")
		return
	if int(GameState.bag.get("capsule", 0)) != 2:
		_fail("capture item count did not persist in shared bag")
		return
	print("SOMADEX_GAMEPLAY_INTEGRATION_PASS")
	quit(0)

func _fail(message: String) -> void:
	push_error("SOMADEX_GAMEPLAY_INTEGRATION_FAIL: " + message)
	quit(1)
