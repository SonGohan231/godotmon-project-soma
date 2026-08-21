extends StaticBody2D
class_name SomadexNPC

@export var display_name: String = "Mieszkaniec"
@export_multiline var dialogue_text: String = "Witaj w Veli."

func interact(_player: Node = null) -> void:
	var dialogue := get_tree().get_first_node_in_group("dialogue_ui")
	if dialogue == null:
		return
	var parsed: Array[String] = []
	for part in dialogue_text.split("|"):
		parsed.append(part.strip_edges())
	dialogue.show_dialogue(display_name, parsed)
