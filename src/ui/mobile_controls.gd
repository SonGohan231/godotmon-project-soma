extends Control

@onready var start_visual: Panel = $StartVisual
@onready var start_button: TouchScreenButton = $Start

const START_WORLD_POS := Vector2(139.0, 158.0)
const START_WORLD_TOUCH := Vector2(160.5, 166.5)
const START_BATTLE_POS := Vector2(152.0, 4.0)
const START_BATTLE_TOUCH := Vector2(173.5, 12.5)

func _ready() -> void:
	# Hidden on desktop gameplay, visible on Android/touch devices.
	# CI can force them on so the exact mobile composition is visually reviewed.
	visible = OS.has_feature("mobile") || DisplayServer.is_touchscreen_available() || OS.has_environment("SOMADEX_QA_SHOW_TOUCH")
	if !Observer.battle_state_changed.is_connected(_on_battle_state_changed):
		Observer.battle_state_changed.connect(_on_battle_state_changed)
	_apply_context(Observer.battle_open)

func _on_battle_state_changed(opened: bool) -> void:
	_apply_context(opened)

func _apply_context(in_battle: bool) -> void:
	if !is_node_ready():
		return
	start_visual.position = START_BATTLE_POS if in_battle else START_WORLD_POS
	start_button.position = START_BATTLE_TOUCH if in_battle else START_WORLD_TOUCH
