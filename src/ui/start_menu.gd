extends Control
class_name StartMenu

@onready var entries: Array[Label] = [$Panel/Menu0, $Panel/Menu1, $Panel/Menu2, $Panel/Menu3, $Panel/Menu4, $Panel/Menu5]
@onready var info_title: Label = $Info/Title
@onready var info_body: Label = $Info/Body

var selected: int = 0
var page_open: bool = false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("start_menu")
	_refresh_menu()

func _process(_delta: float) -> void:
	if !visible:
		if Input.is_action_just_pressed("open_menu") && !Observer.dialogue_open && !Observer.battle_open:
			open_menu()
		return
	if Input.is_action_just_pressed("open_menu"):
		close_menu()
		return
	if Input.is_action_just_pressed("ui_cancel"):
		if page_open:
			page_open = false
			_show_home_info()
		else:
			close_menu()
		return
	if page_open:
		return
	var previous: int = selected
	if Input.is_action_just_pressed("move_up"):
		selected = (selected + entries.size() - 1) % entries.size()
	elif Input.is_action_just_pressed("move_down"):
		selected = (selected + 1) % entries.size()
	if previous != selected:
		_refresh_menu()
	if Input.is_action_just_pressed("ui_accept"):
		_activate_selected()

func open_menu() -> void:
	if visible || Observer.battle_open || Observer.dialogue_open:
		return
	selected = 0
	page_open = false
	visible = true
	Observer.set_menu_open(true)
	get_tree().paused = true
	_refresh_menu()
	_show_home_info()

func close_menu() -> void:
	if !visible:
		return
	visible = false
	page_open = false
	Observer.set_menu_open(false)
	get_tree().paused = false

func _activate_selected() -> void:
	match selected:
		0: _show_page("SOMASKANY", "Drużyna\n1. SOMARI   LV 5   HP 48/48\n\nKolejne sloty będą czytane z trwałego GameState.")
		1: _show_page("PLECAK", "PRZEDMIOTY\n• Kapsuła x3\n• Opatrunek x2\n\nEkwipunek będzie czytany ze wspólnego stanu gry.")
		2: _show_page("TRENER", "TRENER\nPoziom 1\nVela — początek wyprawy\n\nPięć dróg rozwoju pozostanie w tym samym klasycznym interfejsie.")
		3: _show_page("ZAPISZ", "Zapis zostanie podpięty do trwałego GameState bez zmiany stylu menu.")
		4: _show_page("OPCJE", "Sterowanie\nPAD — ruch\nA — wybór / interakcja\nZ — cofnięcie\nSTART — menu")
		5: close_menu()

func _show_page(title: String, body: String) -> void:
	page_open = true
	info_title.text = title
	info_body.text = body + "\n\nZ — wróć"

func _show_home_info() -> void:
	info_title.text = "SOMADEX"
	info_body.text = "VELA\nPierwszy region wyprawy.\n\nPAD — wybierz\nA — otwórz\nZ / START — zamknij"

func _refresh_menu() -> void:
	var names := ["SOMASKANY", "PLECAK", "TRENER", "ZAPISZ", "OPCJE", "WRÓĆ"]
	for i in entries.size():
		entries[i].text = ("> " if i == selected else "  ") + names[i]
