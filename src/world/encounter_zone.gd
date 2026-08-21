extends Area2D
class_name EncounterZone

@export var encounter_table: EncounterTable

var _player: Player
var _mover: Node
var _steps_inside: int = 0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if !(body is Player):
		return
	_player = body
	_mover = body.get_node_or_null("EntityMoverComponent")
	_steps_inside = 0
	if _mover != null && !_mover.move_completed.is_connected(_on_player_step):
		_mover.move_completed.connect(_on_player_step)

func _on_body_exited(body: Node) -> void:
	if body != _player:
		return
	if _mover != null && _mover.move_completed.is_connected(_on_player_step):
		_mover.move_completed.disconnect(_on_player_step)
	_player = null
	_mover = null
	_steps_inside = 0

func _on_player_step() -> void:
	if encounter_table == null || _player == null || Observer.dialogue_open:
		return
	_steps_inside += 1
	if _steps_inside < encounter_table.minimum_steps:
		return
	if _rng.randf() > encounter_table.chance_per_step:
		return

	var rolled := encounter_table.roll(_rng)
	if rolled.is_empty():
		return
	_steps_inside = 0
	Observer.encounter_requested.emit(rolled.species_id, rolled.level, _player.global_position)
