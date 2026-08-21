extends Control
class_name BattleScreen

enum Mode { CLOSED, COMMAND, MOVES, PARTY, BAG, MESSAGE }

@onready var enemy_name: Label = $Arena/EnemyPanel/Name
@onready var enemy_hp: ProgressBar = $Arena/EnemyPanel/HP
@onready var enemy_level: Label = $Arena/EnemyPanel/Level
@onready var player_name: Label = $Arena/PlayerPanel/Name
@onready var player_hp: ProgressBar = $Arena/PlayerPanel/HP
@onready var player_level: Label = $Arena/PlayerPanel/Level
@onready var resonance_label: Label = $Arena/PlayerPanel/ResonanceLabel
@onready var resonance_bar: ProgressBar = $Arena/PlayerPanel/Resonance
@onready var enemy_sprite: Label = $Arena/EnemySprite
@onready var player_sprite: Label = $Arena/PlayerSprite
@onready var command_labels: Array[Label] = [$CommandBox/C0, $CommandBox/C1, $CommandBox/C2, $CommandBox/C3]
@onready var move_labels: Array[Label] = [$MoveBox/M0, $MoveBox/M1, $MoveBox/M2, $MoveBox/M3]
@onready var move_info: Label = $MoveBox/Info
@onready var party_labels: Array[Label] = [$PartyBox/P0, $PartyBox/P1, $PartyBox/P2, $PartyBox/P3, $PartyBox/P4, $PartyBox/P5]
@onready var party_info: Label = $PartyBox/Info
@onready var bag_labels: Array[Label] = [$BagBox/B0, $BagBox/B1, $BagBox/B2]
@onready var bag_info: Label = $BagBox/Info
@onready var message_label: Label = $MessageBox/Text

var mode: Mode = Mode.CLOSED
var command_index: int = 0
var move_index: int = 0
var party_index: int = 0
var bag_index: int = 0
var enemy_data: Dictionary = {}
var player_data: Dictionary = {}
var enemy_current_hp: int = 1
var player_current_hp: int = 1
var enemy_species_id: StringName
var player_species_id: StringName = &"starter"
var enemy_level_value: int = 1
var player_level_value: int = 1
var _party_forced_switch: bool = false
var _resonance: ResonanceState = ResonanceState.new()
var _resonance_armed: bool = false
var _rng := RandomNumberGenerator.new()
var _message_callback: Callable

func _ready() -> void:
	_rng.randomize()
	visible = false
	add_to_group("battle_ui")
	if !Observer.encounter_requested.is_connected(_on_encounter_requested):
		Observer.encounter_requested.connect(_on_encounter_requested)
	_refresh_visibility()

func _on_encounter_requested(species_id: StringName, level: int, world_position: Vector2) -> void:
	start_battle(species_id, level, world_position)

func start_battle(species_id: StringName, level: int, _world_position: Vector2 = Vector2.ZERO) -> void:
	if mode != Mode.CLOSED || GameState.party.is_empty():
		return
	if !_ensure_living_active():
		return
	enemy_species_id = species_id
	enemy_level_value = maxi(1, level)
	enemy_data = SomaskanCatalog.get_species(species_id)
	enemy_current_hp = _max_hp(enemy_data, enemy_level_value)
	_load_active_from_state()
	command_index = 0
	move_index = 0
	party_index = 0
	bag_index = 0
	_party_forced_switch = false
	_resonance.reset()
	_resonance_armed = false
	visible = true
	Observer.set_battle_open(true)
	_setup_hud()
	_show_message("Dziki %s pojawia się!" % enemy_data.name, func(): _set_mode(Mode.COMMAND))

func _process(_delta: float) -> void:
	if mode == Mode.CLOSED:
		return
	# TouchScreenButton actions are polled here too. This keeps A/Z reliable on Android
	# instead of depending on keyboard-style unhandled input events.
	if mode == Mode.MESSAGE:
		if Input.is_action_just_pressed("ui_accept") || Input.is_action_just_pressed("ui_cancel"):
			_finish_message()
		return
	match mode:
		Mode.COMMAND: _process_command_input()
		Mode.MOVES: _process_move_input()
		Mode.PARTY: _process_party_input()
		Mode.BAG: _process_bag_input()

func _process_command_input() -> void:
	var previous: int = command_index
	if Input.is_action_just_pressed("move_left"):
		command_index = 0 if command_index == 1 else 2 if command_index == 3 else command_index
	elif Input.is_action_just_pressed("move_right"):
		command_index = 1 if command_index == 0 else 3 if command_index == 2 else command_index
	elif Input.is_action_just_pressed("move_up"):
		command_index = maxi(0, command_index - 2)
	elif Input.is_action_just_pressed("move_down"):
		command_index = mini(3, command_index + 2)
	if previous != command_index:
		_refresh_commands()
	if Input.is_action_just_pressed("ui_accept"):
		match command_index:
			0: _set_mode(Mode.MOVES)
			1: _open_party(false)
			2: _open_bag()
			3: _attempt_escape()

func _process_move_input() -> void:
	if Input.is_action_just_pressed("open_menu"):
		_attempt_activate_resonance()
		return
	var previous: int = move_index
	if Input.is_action_just_pressed("move_up"):
		move_index = maxi(0, move_index - 1)
	elif Input.is_action_just_pressed("move_down"):
		move_index = mini(3, move_index + 1)
	elif Input.is_action_just_pressed("move_left"):
		move_index = maxi(0, move_index - 2)
	elif Input.is_action_just_pressed("move_right"):
		move_index = mini(3, move_index + 2)
	if previous != move_index:
		_refresh_moves()
	if Input.is_action_just_pressed("ui_cancel"):
		_set_mode(Mode.COMMAND)
	elif Input.is_action_just_pressed("ui_accept"):
		_resolve_player_move(move_index)

func _process_party_input() -> void:
	var count: int = GameState.party.size()
	if count <= 0:
		return
	var previous: int = party_index
	if Input.is_action_just_pressed("move_left") && party_index % 2 == 1:
		party_index -= 1
	elif Input.is_action_just_pressed("move_right") && party_index % 2 == 0 && party_index + 1 < count:
		party_index += 1
	elif Input.is_action_just_pressed("move_up"):
		party_index = maxi(0, party_index - 2)
	elif Input.is_action_just_pressed("move_down"):
		party_index = mini(count - 1, party_index + 2)
	if previous != party_index:
		_refresh_party()
	if Input.is_action_just_pressed("ui_cancel") && !_party_forced_switch:
		_set_mode(Mode.COMMAND)
	elif Input.is_action_just_pressed("ui_accept"):
		_select_party_member(party_index)

func _process_bag_input() -> void:
	var previous: int = bag_index
	if Input.is_action_just_pressed("move_up"):
		bag_index = (bag_index + bag_labels.size() - 1) % bag_labels.size()
	elif Input.is_action_just_pressed("move_down"):
		bag_index = (bag_index + 1) % bag_labels.size()
	if previous != bag_index:
		_refresh_bag()
	if Input.is_action_just_pressed("ui_cancel"):
		_set_mode(Mode.COMMAND)
	elif Input.is_action_just_pressed("ui_accept"):
		match bag_index:
			0: _attempt_capture()
			1: _use_bandage()
			2: _set_mode(Mode.COMMAND)

func _setup_hud() -> void:
	enemy_name.text = String(enemy_data.name).to_upper()
	enemy_level.text = "LV %d" % enemy_level_value
	enemy_hp.max_value = enemy_current_hp
	enemy_hp.value = enemy_current_hp
	enemy_sprite.text = _species_glyph(enemy_species_id)
	_refresh_player_hud()
	_refresh_commands()
	_refresh_moves()
	_refresh_party()
	_refresh_bag()
	_refresh_resonance()

func _load_active_from_state() -> void:
	if GameState.party.is_empty():
		return
	var active: Dictionary = GameState.party[0]
	player_species_id = StringName(active.get("species_id", "starter"))
	player_level_value = maxi(1, int(active.get("level", 1)))
	player_data = SomaskanCatalog.get_species(player_species_id)
	var active_max_hp: int = _max_hp(player_data, player_level_value)
	player_current_hp = clampi(int(active.get("current_hp", active_max_hp)), 0, active_max_hp)

func _refresh_player_hud() -> void:
	player_name.text = String(player_data.name).to_upper()
	player_level.text = "LV %d" % player_level_value
	player_hp.max_value = _max_hp(player_data, player_level_value)
	player_hp.value = player_current_hp
	player_sprite.text = _species_glyph(player_species_id)
	_refresh_resonance()

func _max_hp(species_data: Dictionary, level: int) -> int:
	return maxi(1, int(species_data.get("max_hp", 20)) + maxi(0, level - 1) * 2)

func _species_glyph(species_id: StringName) -> String:
	match String(species_id):
		"wahlik": return "◈W◈"
		"vela_rare": return "✦V✦"
		"starter": return "◢S◣"
		_: return "◇N◇"

func _set_mode(next_mode: Mode) -> void:
	mode = next_mode
	_refresh_visibility()
	match mode:
		Mode.COMMAND: _refresh_commands()
		Mode.MOVES: _refresh_moves()
		Mode.PARTY: _refresh_party()
		Mode.BAG: _refresh_bag()

func _refresh_visibility() -> void:
	if !is_node_ready():
		return
	$CommandBox.visible = mode == Mode.COMMAND
	$MoveBox.visible = mode == Mode.MOVES
	$PartyBox.visible = mode == Mode.PARTY
	$BagBox.visible = mode == Mode.BAG
	$MessageBox.visible = mode == Mode.MESSAGE

func _refresh_commands() -> void:
	var names := ["WALKA", "SOMASKANY", "PLECAK", "UCIECZKA"]
	for i in command_labels.size():
		command_labels[i].text = ("> " if i == command_index else "  ") + names[i]

func _refresh_moves() -> void:
	var moves: Array = player_data.get("moves", [])
	for i in move_labels.size():
		if i < moves.size():
			move_labels[i].text = ("> " if i == move_index else "  ") + String(moves[i].name)
		else:
			move_labels[i].text = "--"
	if move_index < moves.size():
		var move: Dictionary = moves[move_index]
		var resonance_hint := "R!" if _resonance_armed else ("START:REZ" if _resonance.can_activate() else "R %d%%" % _resonance.value)
		move_info.text = "%s MOC %s CEL %d%%  %s" % [String(move.type), "LECZY" if int(move.power) < 0 else str(move.power), int(float(move.accuracy) * 100.0), resonance_hint]

func _resolve_player_move(index: int) -> void:
	var moves: Array = player_data.get("moves", [])
	if index >= moves.size():
		return
	var move: Dictionary = moves[index]
	if _rng.randf() > float(move.accuracy):
		_show_message("%s używa %s... Pudło!" % [player_data.name, move.name], _enemy_turn)
		return
	var boost_used := _resonance_armed
	if int(move.power) < 0:
		var heal_power: int = abs(int(move.power))
		if boost_used:
			heal_power = maxi(1, int(round(heal_power * 1.25)))
		var healed: int = mini(heal_power, int(player_hp.max_value) - player_current_hp)
		player_current_hp += healed
		_sync_player_hp()
		_register_move_resonance(move, boost_used)
		_show_message("%s używa %s. +%d HP%s" % [player_data.name, move.name, healed, "  REZ!" if boost_used else ""], _enemy_turn)
		return
	var damage: int = _damage_for(move, player_level_value)
	if boost_used:
		damage = maxi(1, int(round(damage * 1.35)))
	enemy_current_hp = maxi(0, enemy_current_hp - damage)
	enemy_hp.value = enemy_current_hp
	_register_move_resonance(move, boost_used)
	if enemy_current_hp <= 0:
		_show_message("%s używa %s. Dziki %s pada!%s" % [player_data.name, move.name, enemy_data.name, "  REZ!" if boost_used else ""], _win_battle)
	else:
		_show_message("%s używa %s. -%d HP%s" % [player_data.name, move.name, damage, "  REZ!" if boost_used else ""], _enemy_turn)

func _register_move_resonance(move: Dictionary, boost_used: bool) -> void:
	if boost_used:
		_resonance_armed = false
	_resonance.register_move(StringName(move.get("type", "")), int(move.get("resonance_gain", 6)))
	_refresh_resonance()

func _attempt_activate_resonance() -> void:
	if _resonance_armed:
		_show_message("Rezonans jest już aktywny.", func(): _set_mode(Mode.MOVES))
		return
	if !_resonance.activate():
		_show_message("Rezonans %d/100. Ładuj go ruchami i przyjmowanymi ciosami." % _resonance.value, func(): _set_mode(Mode.MOVES))
		return
	_resonance_armed = true
	_refresh_resonance()
	_show_message("REZONANS! Następny skuteczny ruch zostaje wzmocniony.", func(): _set_mode(Mode.MOVES))

func _refresh_resonance() -> void:
	if !is_node_ready():
		return
	resonance_bar.max_value = ResonanceState.MAX_VALUE
	resonance_bar.value = _resonance.value
	resonance_label.text = "R!" if _resonance_armed else "R"
	if mode == Mode.MOVES:
		_refresh_moves()

func _enemy_turn() -> void:
	if enemy_current_hp <= 0:
		_win_battle()
		return
	var moves: Array = enemy_data.get("moves", [])
	if moves.is_empty():
		_set_mode(Mode.COMMAND)
		return
	var move: Dictionary = moves[_rng.randi_range(0, moves.size() - 1)]
	if _rng.randf() > float(move.accuracy):
		_show_message("%s używa %s... Pudło!" % [enemy_data.name, move.name], func(): _set_mode(Mode.COMMAND))
		return
	if int(move.power) < 0:
		var healed: int = mini(abs(int(move.power)), int(enemy_hp.max_value) - enemy_current_hp)
		enemy_current_hp += healed
		enemy_hp.value = enemy_current_hp
		_show_message("%s odnawia %d HP." % [enemy_data.name, healed], func(): _set_mode(Mode.COMMAND))
		return
	var damage: int = _damage_for(move, enemy_level_value)
	player_current_hp = maxi(0, player_current_hp - damage)
	_sync_player_hp()
	_resonance.register_damage_taken(damage)
	_refresh_resonance()
	if player_current_hp <= 0:
		if _first_healthy_party_index(false) >= 0:
			_show_message("%s używa %s. %s nie może walczyć!" % [enemy_data.name, move.name, player_data.name], _open_forced_party)
		else:
			_show_message("%s używa %s. Drużyna nie może dalej walczyć." % [enemy_data.name, move.name], _lose_battle)
	else:
		_show_message("%s używa %s. -%d HP" % [enemy_data.name, move.name, damage], func(): _set_mode(Mode.COMMAND))

func _sync_player_hp() -> void:
	player_hp.value = player_current_hp
	if !GameState.party.is_empty():
		GameState.party[0]["current_hp"] = player_current_hp

func _open_party(forced: bool) -> void:
	_party_forced_switch = forced
	party_index = _first_healthy_party_index(false) if forced else 0
	if party_index < 0:
		party_index = 0
	_set_mode(Mode.PARTY)

func _open_forced_party() -> void:
	_open_party(true)

func _refresh_party() -> void:
	if !is_node_ready():
		return
	for i in party_labels.size():
		if i >= GameState.party.size():
			party_labels[i].text = "--"
			continue
		var member: Dictionary = GameState.party[i]
		var species := SomaskanCatalog.get_species(StringName(member.get("species_id", "nucik")))
		var marker := ">" if i == party_index else " "
		var faint := " X" if int(member.get("current_hp", 0)) <= 0 else ""
		party_labels[i].text = "%s%d %s L%d%s" % [marker, i + 1, String(species.name).to_upper(), int(member.get("level", 1)), faint]
	if party_index < GameState.party.size():
		var selected: Dictionary = GameState.party[party_index]
		var selected_species := SomaskanCatalog.get_species(StringName(selected.get("species_id", "nucik")))
		var max_hp := _max_hp(selected_species, int(selected.get("level", 1)))
		party_info.text = "HP %d/%d%s" % [int(selected.get("current_hp", 0)), max_hp, "  WYBIERZ ZDOLNEGO" if _party_forced_switch else "  A:ZMIANA  Z:WRÓĆ"]

func _select_party_member(index: int) -> void:
	if index < 0 || index >= GameState.party.size():
		return
	var member: Dictionary = GameState.party[index]
	if int(member.get("current_hp", 0)) <= 0:
		_show_message("Ten Somaskan nie może teraz walczyć.", func(): _set_mode(Mode.PARTY))
		return
	if index == 0:
		if _party_forced_switch:
			_show_message("Wybierz zdolnego Somaskana z rezerwy.", func(): _set_mode(Mode.PARTY))
		else:
			_show_message("%s już walczy." % player_data.name, func(): _set_mode(Mode.PARTY))
		return
	var old_active: Dictionary = GameState.party[0]
	GameState.party[0] = GameState.party[index]
	GameState.party[index] = old_active
	_load_active_from_state()
	_refresh_player_hud()
	var was_forced := _party_forced_switch
	_party_forced_switch = false
	if was_forced:
		_show_message("Do walki wchodzi %s!" % player_data.name, func(): _set_mode(Mode.COMMAND))
	else:
		_show_message("Zmiana! Do walki wchodzi %s." % player_data.name, _enemy_turn)

func _first_healthy_party_index(include_active: bool) -> int:
	var start_index := 0 if include_active else 1
	for i in range(start_index, GameState.party.size()):
		if int(GameState.party[i].get("current_hp", 0)) > 0:
			return i
	return -1

func _ensure_living_active() -> bool:
	if GameState.party.is_empty():
		return false
	if int(GameState.party[0].get("current_hp", 0)) > 0:
		return true
	var index := _first_healthy_party_index(false)
	if index < 0:
		return false
	var old_active: Dictionary = GameState.party[0]
	GameState.party[0] = GameState.party[index]
	GameState.party[index] = old_active
	return true

func _open_bag() -> void:
	bag_index = 0
	_set_mode(Mode.BAG)

func _refresh_bag() -> void:
	if !is_node_ready():
		return
	var names := ["KAPSUŁA x%d" % int(GameState.bag.get("capsule", 0)), "OPATRUNEK x%d" % int(GameState.bag.get("bandage", 0)), "WRÓĆ"]
	for i in bag_labels.size():
		bag_labels[i].text = ("> " if i == bag_index else "  ") + names[i]
	match bag_index:
		0: bag_info.text = "ŁAPANIE — skuteczniejsze przy niskim HP"
		1: bag_info.text = "LECZY 35% HP — zużywa turę"
		_: bag_info.text = "Z — także wraca do komend"

func _attempt_capture() -> void:
	var capsules: int = int(GameState.bag.get("capsule", 0))
	if capsules <= 0:
		_show_message("Brak Kapsuł w plecaku.", func(): _set_mode(Mode.BAG))
		return
	GameState.consume_item(&"capsule", 1)
	var hp_ratio: float = float(enemy_current_hp) / maxf(1.0, float(enemy_hp.max_value))
	var base_rate: float = float(enemy_data.get("capture_rate", 0.35))
	var chance: float = clampf(base_rate + (1.0 - hp_ratio) * 0.42, 0.05, 0.92)
	if _rng.randf() <= chance:
		var learned: Array[StringName] = SomaskanCatalog.move_ids(enemy_species_id)
		GameState.add_captured_somaskan(enemy_species_id, enemy_level_value, enemy_current_hp, learned)
		GameState.mark_flag(&"first_wild_capture")
		_show_message("Udało się! %s dołącza do kolekcji." % enemy_data.name, _close_battle)
	else:
		_show_message("%s wyskakuje z Kapsuły!" % enemy_data.name, _enemy_turn)

func _use_bandage() -> void:
	if int(GameState.bag.get("bandage", 0)) <= 0:
		_show_message("Brak Opatrunków w plecaku.", func(): _set_mode(Mode.BAG))
		return
	var missing_hp := int(player_hp.max_value) - player_current_hp
	if missing_hp <= 0:
		_show_message("%s ma pełne HP." % player_data.name, func(): _set_mode(Mode.BAG))
		return
	if !GameState.consume_item(&"bandage", 1):
		return
	var heal_amount := maxi(8, int(round(float(player_hp.max_value) * 0.35)))
	var healed := mini(missing_hp, heal_amount)
	player_current_hp += healed
	_sync_player_hp()
	_refresh_bag()
	_show_message("Opatrunek odnawia %d HP %s." % [healed, player_data.name], _enemy_turn)

func _damage_for(move: Dictionary, level: int) -> int:
	return maxi(1, int(round(float(move.power) * (0.72 + level * 0.045) * _rng.randf_range(0.9, 1.1))))

func _attempt_escape() -> void:
	var chance: float = 0.65 + maxi(0, int(player_data.speed) - int(enemy_data.speed)) * 0.03
	if _rng.randf() <= minf(chance, 0.95):
		_show_message("Udało się uciec.", _close_battle)
	else:
		_show_message("Nie udało się uciec!", _enemy_turn)

func _win_battle() -> void:
	var xp_gain: int = 10 + enemy_level_value * 4
	GameState.add_trainer_xp(xp_gain)
	GameState.mark_flag(&"first_wild_battle")
	_show_message("Wygrana! Trener zdobywa %d XP." % xp_gain, _close_battle)

func _lose_battle() -> void:
	GameState.mark_flag(&"last_battle_lost")
	_show_message("Porażka. Drużyna potrzebuje odpoczynku.", _close_battle)

func _show_message(text: String, callback: Callable = Callable()) -> void:
	mode = Mode.MESSAGE
	_message_callback = callback
	message_label.text = text + "\nA/Z — dalej"
	_refresh_visibility()

func _finish_message() -> void:
	var callback := _message_callback
	_message_callback = Callable()
	if callback.is_valid():
		callback.call()
	elif mode != Mode.CLOSED:
		_set_mode(Mode.COMMAND)

func _close_battle() -> void:
	_sync_player_hp()
	_party_forced_switch = false
	_resonance.reset()
	_resonance_armed = false
	mode = Mode.CLOSED
	visible = false
	Observer.set_battle_open(false)
	_refresh_visibility()
