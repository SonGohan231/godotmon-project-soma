extends Control
class_name DialogueBox

var _speaker: String = ""
var _lines: Array[String] = []
var _index: int = 0
var _open: bool = false

@onready var speaker_label: Label = $Panel/Margin/VBox/Speaker
@onready var body_label: Label = $Panel/Margin/VBox/Body

func _ready() -> void:
	add_to_group("dialogue_ui")
	visible = false

func _process(_delta: float) -> void:
	if !_open:
		return
	if Input.is_action_just_pressed("ui_accept"):
		advance()

func show_dialogue(speaker: String, lines: Array[String]) -> void:
	if lines.is_empty():
		return
	_speaker = speaker
	_lines = lines
	_index = 0
	_open = true
	visible = true
	Observer.set_dialogue_open(true)
	_render_line()

func advance() -> void:
	if !_open:
		return
	_index += 1
	if _index >= _lines.size():
		close()
		return
	_render_line()

func close() -> void:
	_open = false
	visible = false
	Observer.set_dialogue_open(false)

func is_open() -> bool:
	return _open

func _render_line() -> void:
	speaker_label.text = _speaker
	body_label.text = _lines[_index]
