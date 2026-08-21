extends StaticBody2D
class_name SomadexTrainerNPC

@export var trainer_id: StringName = &"vela_scout"

func interact(player: Node = null) -> void:
	if Observer.world_input_blocked():
		return
	var data := SomadexTrainerCatalog.get_trainer(trainer_id)
	if data.is_empty():
		return
	var flag := SomadexTrainerCatalog.defeated_flag(trainer_id)
	if bool(GameState.quest_flags.get(String(flag), false)):
		_show_dialogue(String(data.get("name", "Trener")), [String(data.get("outro", "Dobra walka."))])
		return
	var world_position := global_position
	if player != null && player is Node2D:
		world_position = (player as Node2D).global_position
	Observer.trainer_battle_requested.emit(trainer_id, world_position)

func _show_dialogue(name: String, lines: Array[String]) -> void:
	var dialogue := get_tree().get_first_node_in_group("dialogue_ui")
	if dialogue != null:
		dialogue.show_dialogue(name, lines)
