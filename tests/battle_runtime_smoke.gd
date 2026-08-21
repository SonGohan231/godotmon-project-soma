extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	GameState.reset_new_game()
	GameState.add_captured_somaskan(&"nucik", 4, 18, SomaskanCatalog.move_ids(&"nucik"))
	var packed := load("res://assets/ui/battle_screen_advanced.tscn") as PackedScene
	if packed == null:
		_fail("advanced battle screen did not load")
		return
	var battle := packed.instantiate() as BattleScreen
	add_child(battle)
	await get_tree().process_frame
	battle.start_battle(&"wahlik", 4)
	if !Observer.battle_open || !GameState.is_seen(CreatureDex.dex_index_for_species(&"wahlik")):
		_fail("battle did not lock world or mark enemy as seen")
		return
	await _tap("ui_accept")
	if battle.mode != BattleScreen.Mode.COMMAND:
		_fail("A did not advance battle message")
		return
	await _tap("move_right")
	await _tap("ui_accept")
	if battle.mode != BattleScreen.Mode.PARTY:
		_fail("SOMASKANY did not open party selector")
		return
	await _tap("move_right")
	await _tap("ui_accept")
	if CreatureDex.dex_index_for_species(StringName(GameState.party[0].get("species_id", ""))) != CreatureDex.dex_index_for_species(&"nucik"):
		_fail("party selection did not switch active Somaskan")
		return
	battle._message_callback = Callable()
	battle._load_active_from_state()
	battle.player_current_hp = maxi(1, int(battle.player_hp.max_value) - 10)
	battle._sync_player_hp()
	var bandages_before := int(GameState.bag.get("bandage", 0))
	var hp_before := battle.player_current_hp
	battle._use_bandage()
	if int(GameState.bag.get("bandage", 0)) != bandages_before - 1 || battle.player_current_hp <= hp_before:
		_fail("persistent battle bandage failed")
		return
	battle._resonance.value = ResonanceState.MAX_VALUE
	battle._resonance_armed = false
	battle._attempt_activate_resonance()
	if !battle._resonance_armed || battle._resonance.value != 0:
		_fail("Rezonans activation failed")
		return
	if SomadexTypeChart.effectiveness(&"PIEZO", ["ODDECH"]) <= 1.0 || SomadexTypeChart.effectiveness(&"PIEZO", ["ZIEMIA"]) >= 1.0:
		_fail("type effectiveness is not applied as designed")
		return
	battle._close_battle()
	await get_tree().create_timer(0.18).timeout
	if Observer.battle_open:
		_fail("battle fade did not release overworld input")
		return
	print("SOMADEX_BATTLE_RUNTIME_PASS")
	get_tree().quit(0)

func _tap(action: StringName) -> void:
	Input.action_press(action)
	await get_tree().process_frame
	Input.action_release(action)
	await get_tree().process_frame

func _fail(message: String) -> void:
	push_error("SOMADEX_BATTLE_RUNTIME_FAIL: " + message)
	get_tree().quit(1)
