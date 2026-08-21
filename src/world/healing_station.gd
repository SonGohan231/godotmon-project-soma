extends StaticBody2D
class_name SomadexHealingStation

@export var station_name: String = "Punkt Regeneracji"
@export var map_id: StringName = &"vela"

func interact(player: Node = null) -> void:
	if Observer.world_input_blocked():
		return
	var restored := 0
	for i in GameState.party.size():
		var member: Dictionary = GameState.party[i]
		var species := CreatureDex.get_species(StringName(member.get("species_id", "starter")))
		var max_hp := SomadexBattleMath.max_hp(species, int(member.get("level", 1)))
		if int(member.get("current_hp", 0)) < max_hp || !String(member.get("status", "")).is_empty():
			restored += 1
		member["current_hp"] = max_hp
		member["status"] = ""
		GameState.party[i] = member
	if player != null && player is Node2D:
		var tile := Vector2i(((player as Node2D).global_position / float(Constants.TILE_SIZE)).round())
		GameState.set_world_spawn(map_id, tile, Vector2i.DOWN)
	GameState.mark_flag(StringName("checkpoint_%s" % String(map_id)))
	GameState.save_game()
	_show_dialogue(["Drużyna została w pełni zregenerowana.", "%d Somaskanów sprawdzono. Punkt zapisano jako bezpieczny checkpoint." % GameState.party.size()])

func _show_dialogue(lines: Array[String]) -> void:
	var dialogue := get_tree().get_first_node_in_group("dialogue_ui")
	if dialogue != null:
		dialogue.show_dialogue(station_name, lines)
