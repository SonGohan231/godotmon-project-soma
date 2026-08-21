extends StaticBody2D
class_name SomadexWorldPickup

@export var pickup_id: StringName = &"vela_capsules_01"
@export var reward_id: StringName = &"capsule"
@export var amount: int = 1
@export var pickup_name: String = "Znalezisko"

func _ready() -> void:
	_refresh_collected_state()

func interact(_player: Node = null) -> void:
	if Observer.world_input_blocked() || _is_collected():
		return
	var reward_text := ""
	var key := String(reward_id).to_upper()
	if key.begins_with("TM"):
		if !GameState.add_tm(StringName(key)):
			return
		reward_text = "Zdobywasz %s." % key
	else:
		var total := GameState.add_item(reward_id, maxi(1, amount))
		reward_text = "Zdobywasz %s x%d. Razem: %d." % [String(reward_id).to_upper(), maxi(1, amount), total]
	GameState.mark_flag(_flag_id())
	visible = false
	collision_layer = 0
	collision_mask = 0
	_show_dialogue(reward_text)

func _flag_id() -> StringName:
	return StringName("pickup_%s" % String(pickup_id))

func _is_collected() -> bool:
	return bool(GameState.quest_flags.get(String(_flag_id()), false))

func _refresh_collected_state() -> void:
	var collected := _is_collected()
	visible = !collected
	if collected:
		collision_layer = 0
		collision_mask = 0

func _show_dialogue(text: String) -> void:
	var dialogue := get_tree().get_first_node_in_group("dialogue_ui")
	if dialogue != null:
		dialogue.show_dialogue(pickup_name, [text])
