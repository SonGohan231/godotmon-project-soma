extends SomadexBattleScreenVisual
class_name SomadexWorldBattleScreen

var trainer_mode: bool = false
var trainer_id: StringName = &""
var trainer_data: Dictionary = {}
var trainer_party: Array = []
var trainer_enemy_index: int = 0

func _ready() -> void:
	super._ready()
	if !Observer.trainer_battle_requested.is_connected(_on_trainer_battle_requested):
		Observer.trainer_battle_requested.connect(_on_trainer_battle_requested)

func _on_trainer_battle_requested(requested_id: StringName, world_position: Vector2) -> void:
	start_trainer_battle(requested_id, world_position)

func start_trainer_battle(requested_id: StringName, world_position: Vector2 = Vector2.ZERO) -> void:
	if mode != Mode.CLOSED:
		return
	var data := SomadexTrainerCatalog.get_trainer(requested_id)
	var roster: Array = data.get("party", [])
	if data.is_empty() || roster.is_empty():
		return
	trainer_mode = true
	trainer_id = requested_id
	trainer_data = data
	trainer_party = roster.duplicate(true)
	trainer_enemy_index = 0
	var first: Dictionary = trainer_party[0]
	super.start_battle(StringName(first.get("species_id", "nucik")), int(first.get("level", 1)), world_position)
	if mode == Mode.CLOSED:
		_reset_trainer_context()
		return
	_show_message("%s %s wyzywa cię!\n%s" % [String(trainer_data.get("title", "Trener")), String(trainer_data.get("name", "")), String(trainer_data.get("intro", "Do walki!"))], func(): _set_mode(Mode.COMMAND))

func _attempt_capture() -> void:
	if trainer_mode:
		_show_message("Nie można łapać Somaskanów należących do trenera.", func(): _set_mode(Mode.BAG))
		return
	super._attempt_capture()

func _attempt_escape() -> void:
	if trainer_mode:
		_show_message("Z walki trenerskiej nie można uciec.", func(): _set_mode(Mode.COMMAND))
		return
	super._attempt_escape()

func _win_battle() -> void:
	if !trainer_mode:
		super._win_battle()
		return
	var xp_result := GameState.award_active_somaskan_xp(enemy_species_id, enemy_level_value)
	var gained := int(xp_result.get("xp_gained", 0))
	trainer_enemy_index += 1
	if trainer_enemy_index < trainer_party.size():
		_show_message("%s pada! %s +%d XP." % [String(enemy_data.get("name", "Somaskan")), String(player_data.get("name", "Somaskan")), gained], _send_next_trainer_enemy)
		return
	var reward := int(trainer_data.get("reward", 0))
	var trainer_xp := int(trainer_data.get("trainer_xp", 0))
	if reward > 0:
		GameState.add_item(&"credits", reward)
	if trainer_xp > 0:
		GameState.add_trainer_xp(trainer_xp)
	GameState.mark_flag(SomadexTrainerCatalog.defeated_flag(trainer_id))
	var outro := String(trainer_data.get("outro", "Dobra walka."))
	var trainer_name := String(trainer_data.get("name", "Trener"))
	trainer_mode = false
	_show_message("Pokonujesz %s! %s +%d XP. Zdobywasz %d kredytów.\n%s" % [trainer_name, String(player_data.get("name", "Somaskan")), gained, reward, outro], _close_battle)

func _send_next_trainer_enemy() -> void:
	if trainer_enemy_index < 0 || trainer_enemy_index >= trainer_party.size():
		return
	var next_member: Dictionary = trainer_party[trainer_enemy_index]
	enemy_species_id = StringName(next_member.get("species_id", "nucik"))
	enemy_level_value = maxi(1, int(next_member.get("level", 1)))
	enemy_data = SomaskanCatalog.get_species(enemy_species_id)
	enemy_current_hp = _max_hp(enemy_data, enemy_level_value)
	enemy_status = ""
	GameState.mark_seen(enemy_species_id)
	_setup_hud()
	_show_message("%s wysyła %s!" % [String(trainer_data.get("name", "Trener")), String(enemy_data.get("name", "Somaskan"))], func(): _set_mode(Mode.COMMAND))

func _close_battle() -> void:
	super._close_battle()
	if mode == Mode.CLOSED || !trainer_mode:
		_reset_trainer_context()

func _reset_trainer_context() -> void:
	trainer_mode = false
	trainer_id = &""
	trainer_data = {}
	trainer_party = []
	trainer_enemy_index = 0
