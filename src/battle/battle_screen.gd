extends Control
class_name BattleScreen

enum Mode { CLOSED, COMMAND, MOVES, MESSAGE }

@onready var enemy_name: Label = $Arena/EnemyPanel/Name
@onready var enemy_hp: ProgressBar = $Arena/EnemyPanel/HP
@onready var enemy_level: Label = $Arena/EnemyPanel/Level
@onready var player_name: Label = $Arena/PlayerPanel/Name
@onready var player_hp: ProgressBar = $Arena/PlayerPanel/HP
@onready var player_level: Label = $Arena/PlayerPanel/Level
@onready var enemy_sprite: Label = $Arena/EnemySprite
@onready var player_sprite: Label = $Arena/PlayerSprite
@onready var command_labels: Array[Label] = [$CommandBox/C0, $CommandBox/C1, $CommandBox/C2, $CommandBox/C3]
@onready var move_labels: Array[Label] = [$MoveBox/M0, $MoveBox/M1, $MoveBox/M2, $MoveBox/M3]
@onready var move_info: Label = $MoveBox/Info
@onready var message_label: Label = $MessageBox/Text

var mode: Mode = Mode.CLOSED
var command_index := 0
var move_index := 0
var enemy_data: Dictionary = {}
var player_data: Dictionary = {}
var enemy_current_hp := 1
var player_current_hp := 1
var enemy_species_id: StringName
var enemy_level_value := 1
var _rng := RandomNumberGenerator.new()
var _message_callback: Callable

func _ready() -> void:
	_rng.randomize()
	visible = false
	add_to_group("battle_ui")
	if !Observer.encounter_requested.is_connected(_on_encounter_requested):
		Observer.encounter_requested.connect(_on_encounter_requested)
	_refresh_visibility()

func _on_encounter_requested(species_id: StringName, level: int, _world_position: Vector2) -> void:
	start_battle(species_id, level)

func start_battle(species_id: StringName, level: int, _world_position: Vector2 = Vector2.ZERO) -> void:
	if mode != Mode.CLOSED:
		return
	enemy_species_id = species_id
	enemy_level_value = level
	enemy_data = SomaskanCatalog.get_species(species_id)
	player_data = SomaskanCatalog.get_species(&"starter")
	enemy_current_hp = int(enemy_data.max_hp) + level * 2
	player_current_hp = int(player_data.max_hp) + 8
	command_index = 0
	move_index = 0
	visible = true
	Observer.set_battle_open(true)
	_setup_hud()
	_show_message("Dziki %s pojawia się!" % enemy_data.name, func(): _set_mode(Mode.COMMAND))

func _process(_delta: float) -> void:
	if mode == Mode.CLOSED || mode == Mode.MESSAGE:
		return
	if mode == Mode.COMMAND:
		_process_command_input()
	elif mode == Mode.MOVES:
		_process_move_input()

func _process_command_input() -> void:
	var previous := command_index
	if Input.is_action_just_pressed("move_left"):
		command_index = 0 if command_index == 1 else 2 if command_index == 3 else command_index
	elif Input.is_action_just_pressed("move_right"):
		command_index = 1 if command_index == 0 else 3 if command_index == 2 else command_index
	elif Input.is_action_just_pressed("move_up"):
		command_index = max(0, command_index - 2)
	elif Input.is_action_just_pressed("move_down"):
		command_index = min(3, command_index + 2)
	if previous != command_index:
		_refresh_commands()
	if Input.is_action_just_pressed("ui_accept"):
		match command_index:
			0:
				_set_mode(Mode.MOVES)
			1:
				_show_message("Drużyna będzie dostępna z trwałego GameState.", func(): _set_mode(Mode.COMMAND))
			2:
				_show_message("Plecak zostanie podpięty do wspólnego ekwipunku.", func(): _set_mode(Mode.COMMAND))
			3:
				_attempt_escape()

func _process_move_input() -> void:
	var previous := move_index
	if Input.is_action_just_pressed("move_up"):
		move_index = max(0, move_index - 1)
	elif Input.is_action_just_pressed("move_down"):
		move_index = min(3, move_index + 1)
	elif Input.is_action_just_pressed("move_left"):
		move_index = max(0, move_index - 2)
	elif Input.is_action_just_pressed("move_right"):
		move_index = min(3, move_index + 2)
	if previous != move_index:
		_refresh_moves()
	if Input.is_action_just_pressed("ui_cancel"):
		_set_mode(Mode.COMMAND)
	elif Input.is_action_just_pressed("ui_accept"):
		_resolve_player_move(move_index)

func _unhandled_input(event: InputEvent) -> void:
	if mode == Mode.MESSAGE && (event.is_action_pressed("ui_accept") || event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		_finish_message()

func _setup_hud() -> void:
	enemy_name.text = String(enemy_data.name).to_upper()
	enemy_level.text = "LV %d" % enemy_level_value
	enemy_hp.max_value = enemy_current_hp
	enemy_hp.value = enemy_current_hp
	enemy_sprite.text = _species_glyph(enemy_species_id)
	player_name.text = String(player_data.name).to_upper()
	player_level.text = "LV 5"
	player_hp.max_value = player_current_hp
	player_hp.value = player_current_hp
	player_sprite.text = "◢S◣"
	_refresh_commands()
	_refresh_moves()

func _species_glyph(species_id: StringName) -> String:
	match String(species_id):
		"wahlik": return "◈W◈"
		"vela_rare": return "✦V✦"
		_: return "◇N◇"

func _set_mode(next_mode: Mode) -> void:
	mode = next_mode
	_refresh_visibility()
	if mode == Mode.COMMAND:
		_refresh_commands()
	elif mode == Mode.MOVES:
		_refresh_moves()

func _refresh_visibility() -> void:
	if !is_node_ready():
		return
	$CommandBox.visible = mode == Mode.COMMAND
	$MoveBox.visible = mode == Mode.MOVES
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
		move_info.text = "%s  MOC %s  CEL %d%%" % [String(move.type), "LECZY" if int(move.power) < 0 else str(move.power), int(float(move.accuracy) * 100.0)]

func _resolve_player_move(index: int) -> void:
	var moves: Array = player_data.get("moves", [])
	if index >= moves.size():
		return
	var move: Dictionary = moves[index]
	_set_mode(Mode.MESSAGE)
	if _rng.randf() > float(move.accuracy):
		_show_message("%s używa %s... Pudło!" % [player_data.name, move.name], _enemy_turn)
		return
	if int(move.power) < 0:
		var healed := min(abs(int(move.power)), int(player_hp.max_value) - player_current_hp)
		player_current_hp += healed
		player_hp.value = player_current_hp
		_show_message("%s używa %s. +%d HP" % [player_data.name, move.name, healed], _enemy_turn)
		return
	var damage := _damage_for(move, 5)
	enemy_current_hp = max(0, enemy_current_hp - damage)
	enemy_hp.value = enemy_current_hp
	if enemy_current_hp <= 0:
		_show_message("%s używa %s. Dziki %s pada!" % [player_data.name, move.name, enemy_data.name], _win_battle)
	else:
		_show_message("%s używa %s. -%d HP" % [player_data.name, move.name, damage], _enemy_turn)

func _enemy_turn() -> void:
	if enemy_current_hp <= 0:
		_win_battle()
		return
	var moves: Array = enemy_data.get("moves", [])
	var move: Dictionary = moves[_rng.randi_range(0, moves.size() - 1)]
	if _rng.randf() > float(move.accuracy):
		_show_message("%s używa %s... Pudło!" % [enemy_data.name, move.name], func(): _set_mode(Mode.COMMAND))
		return
	if int(move.power) < 0:
		var healed := min(abs(int(move.power)), int(enemy_hp.max_value) - enemy_current_hp)
		enemy_current_hp += healed
		enemy_hp.value = enemy_current_hp
		_show_message("%s odnawia %d HP." % [enemy_data.name, healed], func(): _set_mode(Mode.COMMAND))
		return
	var damage := _damage_for(move, enemy_level_value)
	player_current_hp = max(0, player_current_hp - damage)
	player_hp.value = player_current_hp
	if player_current_hp <= 0:
		_show_message("%s używa %s. Somari nie może walczyć." % [enemy_data.name, move.name], _lose_battle)
	else:
		_show_message("%s używa %s. -%d HP" % [enemy_data.name, move.name, damage], func(): _set_mode(Mode.COMMAND))

func _damage_for(move: Dictionary, level: int) -> int:
	return max(1, int(round(float(move.power) * (0.72 + level * 0.045) * _rng.randf_range(0.9, 1.1))))

func _attempt_escape() -> void:
	var chance := 0.65 + max(0, int(player_data.speed) - int(enemy_data.speed)) * 0.03
	if _rng.randf() <= min(chance, 0.95):
		_show_message("Udało się uciec.", _close_battle)
	else:
		_show_message("Nie udało się uciec!", _enemy_turn)

func _win_battle() -> void:
	_show_message("Wygrana. Zdobywasz doświadczenie trenera i Somaskana.", _close_battle)

func _lose_battle() -> void:
	_show_message("Porażka. W wersji świata nastąpi powrót do punktu leczenia.", _close_battle)

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
	mode = Mode.CLOSED
	visible = false
	Observer.set_battle_open(false)
	_refresh_visibility()
