extends Node

## Lightweight global event bus used to keep world, UI and battle systems decoupled.

var dialogue_open: bool = false
var battle_open: bool = false
var menu_open: bool = false

signal transition_started
signal transition_finished
signal encounter_requested(species_id: StringName, level: int, world_position: Vector2)
signal trainer_battle_requested(trainer_id: StringName, world_position: Vector2)
signal dialogue_state_changed(opened: bool)
signal battle_state_changed(opened: bool)
signal menu_state_changed(opened: bool)

func set_dialogue_open(opened: bool) -> void:
	if dialogue_open == opened:
		return
	dialogue_open = opened
	dialogue_state_changed.emit(opened)

func set_battle_open(opened: bool) -> void:
	if battle_open == opened:
		return
	battle_open = opened
	battle_state_changed.emit(opened)

func set_menu_open(opened: bool) -> void:
	if menu_open == opened:
		return
	menu_open = opened
	menu_state_changed.emit(opened)

func world_input_blocked() -> bool:
	return dialogue_open || battle_open || menu_open
