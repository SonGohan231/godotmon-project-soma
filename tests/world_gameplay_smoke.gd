extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	GameState.reset_new_game()
	var validation := SomadexTrainerCatalog.validate_all()
	if !bool(validation.get("ok", false)) || int(validation.get("count", 0)) < 2:
		_fail("trainer catalog invalid: %s" % validation)
		return

	# Full two-Somaskan trainer battle flow with persistent reward/flag.
	var packed := load("res://assets/ui/battle_screen_advanced.tscn") as PackedScene
	if packed == null:
		_fail("battle screen did not load")
		return
	var battle = packed.instantiate()
	root.add_child(battle)
	await process_frame
	battle.start_trainer_battle(&"vela_scout", Vector2(160, 96))
	if !battle.trainer_mode || String(battle.enemy_species_id) != "nucik" || battle.mode != BattleScreen.Mode.MESSAGE:
		_fail("trainer battle did not start with first roster member")
		return
	battle._finish_message()
	if battle.mode != BattleScreen.Mode.COMMAND:
		_fail("trainer intro did not advance to commands")
		return
	battle.enemy_current_hp = 0
	battle._win_battle()
	battle._finish_message()
	if String(battle.enemy_species_id) != "wahlik" || battle.trainer_enemy_index != 1:
		_fail("trainer did not send second Somaskan")
		return
	battle._finish_message()
	battle.enemy_current_hp = 0
	battle._win_battle()
	if !bool(GameState.quest_flags.get("trainer_defeated_vela_scout", false)):
		_fail("trainer victory flag missing")
		return
	if int(GameState.bag.get("credits", 0)) != 90:
		_fail("trainer reward was not persisted")
		return
	battle._finish_message()
	await create_timer(0.25).timeout
	if Observer.battle_open:
		_fail("trainer battle did not return control to overworld")
		return

	# Healing station restores HP/status and records a safe checkpoint.
	var member: Dictionary = GameState.party[0]
	member["current_hp"] = 1
	member["status"] = BattleStatus.PRZEGRZANIE
	GameState.party[0] = member
	var station := SomadexHealingStation.new()
	root.add_child(station)
	station.interact(null)
	var healed: Dictionary = GameState.party[0]
	var species := CreatureDex.get_species(StringName(healed.get("species_id", "starter")))
	var expected_hp := SomadexBattleMath.max_hp(species, int(healed.get("level", 1)))
	if int(healed.get("current_hp", 0)) != expected_hp || !String(healed.get("status", "")).is_empty():
		_fail("healing station did not fully restore active Somaskan")
		return
	if !bool(GameState.quest_flags.get("checkpoint_vela", false)):
		_fail("healing station did not set checkpoint")
		return

	# Persistent world pickup may be collected once and TM pickup becomes usable.
	var capsules_before := int(GameState.bag.get("capsule", 0))
	var pickup := SomadexWorldPickup.new()
	pickup.pickup_id = &"qa_capsules"
	pickup.reward_id = &"capsule"
	pickup.amount = 2
	root.add_child(pickup)
	pickup.interact()
	pickup.interact()
	if int(GameState.bag.get("capsule", 0)) != capsules_before + 2:
		_fail("world pickup could be duplicated or failed")
		return
	var tm_pickup := SomadexWorldPickup.new()
	tm_pickup.pickup_id = &"qa_tm0002"
	tm_pickup.reward_id = &"TM0002"
	root.add_child(tm_pickup)
	tm_pickup.interact()
	if !GameState.has_tm(&"TM0002"):
		_fail("world TM pickup did not unlock TM0002")
		return

	print("SOMADEX_WORLD_GAMEPLAY_PASS trainers=2 heal=1 pickups=2")
	quit(0)

func _fail(message: String) -> void:
	push_error("SOMADEX_WORLD_GAMEPLAY_FAIL: " + message)
	quit(1)
