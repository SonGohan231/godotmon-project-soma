extends SceneTree

const EXPECTED := {
	"Left": "move_left",
	"Right": "move_right",
	"Up": "move_up",
	"Down": "move_down",
	"A": "ui_accept",
	"Z": "ui_cancel",
	"Start": "open_menu"
}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("SOMADEX_QA_SHOW_TOUCH", "1")
	var packed := load("res://assets/ui/mobile_controls.tscn") as PackedScene
	if packed == null:
		_fail("mobile_controls.tscn did not load")
		return
	var controls := packed.instantiate()
	root.add_child(controls)
	await process_frame
	if !controls.visible:
		_fail("mobile controls are not visible in forced touch QA mode")
		return

	var touch_index := 1
	for node_name in EXPECTED.keys():
		var button := controls.get_node_or_null(String(node_name)) as TouchScreenButton
		if button == null:
			_fail("missing touch button: %s" % node_name)
			return
		var expected_action: String = EXPECTED[node_name]
		if button.action != expected_action:
			_fail("%s maps to %s instead of %s" % [node_name, button.action, expected_action])
			return
		if button.shape == null:
			_fail("%s has no touch shape" % node_name)
			return
		if !_shape_is_large_enough(button.shape):
			_fail("%s touch target is too small" % node_name)
			return

		var press := InputEventScreenTouch.new()
		press.index = touch_index
		press.position = button.global_position
		press.pressed = true
		Input.parse_input_event(press)
		await process_frame
		if !Input.is_action_pressed(expected_action):
			_fail("screen touch did not press action %s" % expected_action)
			return

		var release := InputEventScreenTouch.new()
		release.index = touch_index
		release.position = button.global_position
		release.pressed = false
		Input.parse_input_event(release)
		await process_frame
		if Input.is_action_pressed(expected_action):
			_fail("screen touch did not release action %s" % expected_action)
			return
		touch_index += 1

	OS.unset_environment("SOMADEX_QA_SHOW_TOUCH")
	print("SOMADEX_MOBILE_TOUCH_PASS")
	quit(0)

func _shape_is_large_enough(shape: Shape2D) -> bool:
	if shape is CircleShape2D:
		return (shape as CircleShape2D).radius >= 16.0
	if shape is RectangleShape2D:
		var size := (shape as RectangleShape2D).size
		return size.x >= 24.0 && size.y >= 16.0
	return false

func _fail(message: String) -> void:
	push_error("SOMADEX_MOBILE_TOUCH_FAIL: " + message)
	quit(1)
