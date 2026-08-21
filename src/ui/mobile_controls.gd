extends Control

func _ready() -> void:
	# Hidden on desktop gameplay, visible on Android/touch devices.
	# CI can force them on so the exact mobile composition is visually reviewed.
	visible = OS.has_feature("mobile") || DisplayServer.is_touchscreen_available() || OS.has_environment("SOMADEX_QA_SHOW_TOUCH")
