extends Node

## Lightweight global event bus used to keep world, UI and battle systems decoupled.

var dialogue_open: bool = false

## Sent when a transition starts.
signal transition_started
## Sent once a transition is over.
signal transition_finished

## Sent by an encounter zone after it has rolled a valid wild creature.
signal encounter_requested(species_id: StringName, level: int, world_position: Vector2)

## Sent when a dialogue opens or closes so movement/battle systems can react.
signal dialogue_state_changed(opened: bool)

func set_dialogue_open(opened: bool) -> void:
	if dialogue_open == opened:
		return
	dialogue_open = opened
	dialogue_state_changed.emit(opened)
