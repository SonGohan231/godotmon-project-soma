extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	# `godot --script` runs this smoke outside the normal main scene, so test the
	# same production classes directly instead of relying on autoload identifiers.
	var state_script = load("res://src/autoloads/game_state.gd")
	var catalog_script = load("res://src/battle/somaskan_catalog.gd")
	var battle_script = load("res://src/battle/battle_screen.gd")
	if state_script == null || catalog_script == null || battle_script == null:
		_fail("production gameplay scripts did not load")
		return
	var state = state_script.new()
	state.reset_new_game()
	if state.party.size() != 1:
		_fail("starter party missing")
		return
	if int(state.bag.get("capsule", 0)) != 3:
		_fail("starter capsules missing")
		return
	var move_ids: Array[StringName] = catalog_script.move_ids(&"nucik")
	if move_ids.size() != 4:
		_fail("Nucik battle data must expose four moves")
		return
	if !state.consume_item(&"capsule", 1):
		_fail("capture item could not be consumed")
		return
	state.add_captured_somaskan(&"nucik", 4, 18, move_ids)
	if state.party.size() != 2:
		_fail("captured Somaskan did not join party")
		return
	state.add_trainer_xp(30)
	state.mark_flag(&"first_wild_battle")
	state.mark_flag(&"first_wild_capture")
	if !bool(state.quest_flags.get("first_wild_battle", false)) || !bool(state.quest_flags.get("first_wild_capture", false)):
		_fail("battle/capture progress flags missing")
		return
	if int(state.bag.get("capsule", 0)) != 2:
		_fail("capture item count did not persist in shared bag")
		return
	print("SOMADEX_GAMEPLAY_INTEGRATION_PASS")
	quit(0)

func _fail(message: String) -> void:
	push_error("SOMADEX_GAMEPLAY_INTEGRATION_FAIL: " + message)
	quit(1)
