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
		0: _show_page("SOMASKANY", _party_text())
		1: _show_page("PLECAK", _bag_text())
		2: _show_page("TRENER", _trainer_text())
		3: _save_from_menu()
		4: _show_page("OPCJE", "Sterowanie\nPAD — ruch\nA — wybór / interakcja\nZ — cofnięcie\nSTART — menu")
		5: close_menu()

func _party_text() -> String:
	var lines: Array[String] = ["DRUŻYNA %d/6" % GameState.party.size()]
	for i in GameState.party.size():
		var member: Dictionary = GameState.party[i]
		var species := SomaskanCatalog.get_species(StringName(member.get("species_id", "nucik")))
		lines.append("%d. %s  LV %d  HP %d" % [i + 1, String(species.name).to_upper(), int(member.get("level", 1)), int(member.get("current_hp", 0))])
	if GameState.storage.size() > 0:
		lines.append("\nMAGAZYN: %d" % GameState.storage.size())
	return "\n".join(lines)

func _bag_text() -> String:
	return "PRZEDMIOTY\n• Kapsuła x%d\n• Opatrunek x%d\n• Żeton Veli x%d" % [int(GameState.bag.get("capsule", 0)), int(GameState.bag.get("bandage", 0)), int(GameState.bag.get("vela_token", 0))]

func _trainer_text() -> String:
	var chosen := String(GameState.trainer.get("chosen_path", ""))
	var path_name := "Nie wybrano"
	if !chosen.is_empty():
		var path_data := TrainerPaths.get_path(StringName(chosen))
		if !path_data.is_empty():
			path_name = String(path_data.name)
	return "TRENER\nPoziom %d\nXP %d\nPunkty rozwoju %d\nŚcieżka: %s" % [int(GameState.trainer.get("level", 1)), int(GameState.trainer.get("xp", 0)), int(GameState.trainer.get("skill_points", 0)), path_name]

func _save_from_menu() -> void:
	var result := GameState.save_game()
	if result == OK:
		_show_page("ZAPISZ", "Gra została zapisana.\nPozycja, drużyna, plecak i postęp trenera są zachowane.")
	else:
		_show_page("ZAPISZ", "Nie udało się zapisać gry. Kod błędu: %d" % int(result))

func _show_page(title: String, body: String) -> void:
	page_open = true
	info_title.text = title
	info_body.text = body + "\n\nZ — wróć"

func _show_home_info() -> void:
	info_title.text = "SOMADEX"
	info_body.text = "VELA\nTrener LV %d\nDrużyna %d/6\n\nPAD — wybierz\nA — otwórz\nZ / START — zamknij" % [int(GameState.trainer.get("level", 1)), GameState.party.size()]

func _refresh_menu() -> void:
	var names := ["SOMASKANY", "PLECAK", "TRENER", "ZAPISZ", "OPCJE", "WRÓĆ"]
	for i in entries.size():
		entries[i].text = ("> " if i == selected else "  ") + names[i]
