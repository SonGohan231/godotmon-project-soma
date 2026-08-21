extends StartMenu
class_name SomadexStartMenu

@onready var menu6: Label = $Panel/Menu6
@onready var menu7: Label = $Panel/Menu7
@onready var mini_preview: Label = $Info/Mini

var page_kind := ""
var dex_cursor := 1
var roster_cursor := 0
var tm_cursor := 0
var tm_slot := 0
var _mini_time := 0.0
var _mini_phase := 0
var _closing_fade := false

func _ready() -> void:
	super._ready()
	entries = [$Panel/Menu0,$Panel/Menu1,$Panel/Menu2,$Panel/Menu3,$Panel/Menu4,$Panel/Menu5,menu6,menu7]
	_refresh_menu()
	mini_preview.text = ""

func _process(delta: float) -> void:
	_mini_time += delta
	if _mini_time >= 0.28:
		_mini_time = 0.0
		_mini_phase = 1 - _mini_phase
		_refresh_mini_only()
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
			page_kind = ""
			mini_preview.text = ""
			_show_home_info()
		else:
			close_menu()
		return
	if page_open:
		_process_page_input()
		return
	var previous := selected
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
	super.open_menu()
	modulate.a = 0.0
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(self, "modulate:a", 1.0, 0.12)

func close_menu() -> void:
	if !visible || _closing_fade:
		return
	_closing_fade = true
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 0.0, 0.10)
	await tween.finished
	super.close_menu()
	modulate.a = 1.0
	_closing_fade = false

func _activate_selected() -> void:
	match selected:
		0: _open_roster()
		1: _open_dex()
		2: _open_page("PLECAK", _bag_text(), "bag")
		3: _open_tm()
		4: _open_page("TRENER", _trainer_text(), "trainer")
		5: _save_from_menu()
		6: _open_page("OPCJE", "Sterowanie\nPAD — ruch / wybór\nA — wybór / interakcja\nZ — cofnięcie\nSTART — menu / Rezonans w walce", "options")
		7: close_menu()

func _refresh_menu() -> void:
	var names := ["SOMASKANY","SOMADEX","PLECAK","TECHNIKI","TRENER","ZAPISZ","OPCJE","WRÓĆ"]
	for i in mini(entries.size(), names.size()):
		entries[i].text = ("> " if i == selected else "  ") + names[i]

func _open_page(title: String, body: String, kind: String) -> void:
	page_open = true
	page_kind = kind
	info_title.text = title
	info_body.text = body + "\n\nZ — wróć"
	info_body.modulate.a = 0.0
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(info_body, "modulate:a", 1.0, 0.10)

func _open_dex() -> void:
	dex_cursor = clampi(dex_cursor, 1, CreatureDex.count())
	page_open = true
	page_kind = "dex"
	_render_dex()

func _render_dex() -> void:
	var entry := CreatureDex.entry_by_index(dex_cursor)
	var seen := GameState.is_seen(dex_cursor)
	var caught := GameState.is_caught(dex_cursor)
	info_title.text = "SOMADEX %03d/%03d" % [dex_cursor, CreatureDex.count()]
	if !seen:
		info_body.text = "???\nNie spotkano jeszcze tego Somaskana.\n\nWidziane %d/150  Złapane %d/150\n◀/▶ wpis  ▲/▼ ±10\nZ — wróć" % [GameState.seen_count(), GameState.caught_count()]
		mini_preview.text = "?"
		return
	var caught_mark := " ★" if caught else ""
	info_body.text = "%s%s\n%s\n%s\n%s\n\nWidziane %d/150  Złapane %d/150\n◀/▶ wpis  ▲/▼ ±10" % [String(entry.name).to_upper(), caught_mark, " / ".join(Array(entry.types)), String(entry.description), "Siedlisko: " + String(entry.habitat), GameState.seen_count(), GameState.caught_count()]
	_refresh_mini_only()

func _open_roster() -> void:
	roster_cursor = clampi(roster_cursor, 0, maxi(0, GameState.party.size() + GameState.storage.size() - 1))
	page_open = true
	page_kind = "roster"
	_render_roster()

func _roster_all() -> Array:
	var all: Array = []
	for member in GameState.party:
		var copy := member.duplicate(true)
		copy["location"] = "DRUŻYNA"
		all.append(copy)
	for member in GameState.storage:
		var copy := member.duplicate(true)
		copy["location"] = "MAGAZYN"
		all.append(copy)
	return all

func _render_roster() -> void:
	var all := _roster_all()
	info_title.text = "SOMASKANY %d/%d" % [roster_cursor + 1, maxi(1, all.size())]
	if all.is_empty():
		info_body.text = "Brak Somaskanów.\nZ — wróć"
		mini_preview.text = ""
		return
	var member: Dictionary = all[roster_cursor]
	var species := CreatureDex.get_species(StringName(member.get("species_id", "starter")))
	var moves := SomaskanCatalog.resolve_moves(Array(member.get("moves", [])), StringName(member.get("species_id", "starter")))
	var move_names: Array[String] = []
	for move in moves:
		move_names.append(String(move.name))
	info_body.text = "%s  LV %d\n%s • HP %d\n%s\nRuchy: %s\n\n◀/▶ następny" % [String(species.name).to_upper(), int(member.get("level",1)), String(member.location), int(member.get("current_hp",0)), " / ".join(Array(species.types)), ", ".join(move_names)]
	_refresh_mini_only()

func _open_tm() -> void:
	tm_cursor = 0
	tm_slot = 0
	page_open = true
	page_kind = "tm"
	_render_tm()

func _render_tm(note: String = "") -> void:
	var owned := GameState.owned_tm_ids()
	info_title.text = "TECHNIKI TM"
	mini_preview.text = ""
	if owned.is_empty():
		info_body.text = "Nie znaleziono jeszcze żadnej Techniki.\nZ — wróć"
		return
	tm_cursor = posmod(tm_cursor, owned.size())
	var tm := TechniqueCatalog.get_tm(StringName(owned[tm_cursor]))
	var active := CreatureDex.get_species(StringName(GameState.party[0].get("species_id", "starter")))
	var compatible := TechniqueCatalog.compatible(Array(active.types), StringName(tm.tm_id))
	info_body.text = "%s — %s\nTyp %s • MOC %d • CEL %d%%\n%s: %s\nSlot %d/4\n\n◀/▶ TM  ▲/▼ slot  A — naucz%s" % [String(tm.tm_id), String(tm.name), String(tm.type), int(tm.move.power), int(float(tm.move.accuracy) * 100.0), String(active.name), "ZGODNY" if compatible else "NIEZGODNY", tm_slot + 1, "\n" + note if !note.is_empty() else ""]

func _process_page_input() -> void:
	match page_kind:
		"dex":
			if Input.is_action_just_pressed("move_left"): dex_cursor = maxi(1, dex_cursor - 1); _render_dex()
			elif Input.is_action_just_pressed("move_right"): dex_cursor = mini(CreatureDex.count(), dex_cursor + 1); _render_dex()
			elif Input.is_action_just_pressed("move_up"): dex_cursor = maxi(1, dex_cursor - 10); _render_dex()
			elif Input.is_action_just_pressed("move_down"): dex_cursor = mini(CreatureDex.count(), dex_cursor + 10); _render_dex()
		"roster":
			var total := _roster_all().size()
			if total > 0 && Input.is_action_just_pressed("move_left"): roster_cursor = posmod(roster_cursor - 1, total); _render_roster()
			elif total > 0 && Input.is_action_just_pressed("move_right"): roster_cursor = posmod(roster_cursor + 1, total); _render_roster()
		"tm":
			var total_tm := GameState.owned_tm_ids().size()
			if total_tm > 0 && Input.is_action_just_pressed("move_left"): tm_cursor = posmod(tm_cursor - 1, total_tm); _render_tm()
			elif total_tm > 0 && Input.is_action_just_pressed("move_right"): tm_cursor = posmod(tm_cursor + 1, total_tm); _render_tm()
			elif Input.is_action_just_pressed("move_up"): tm_slot = posmod(tm_slot - 1, 4); _render_tm()
			elif Input.is_action_just_pressed("move_down"): tm_slot = posmod(tm_slot + 1, 4); _render_tm()
			elif Input.is_action_just_pressed("ui_accept"): _teach_selected_tm()

func _teach_selected_tm() -> void:
	var owned := GameState.owned_tm_ids()
	if owned.is_empty():
		return
	var id := StringName(owned[tm_cursor])
	if GameState.teach_tm(0, id, tm_slot):
		_render_tm("Nauczono ruchu. TM jest wielokrotnego użytku.")
	else:
		_render_tm("Ten Somaskan nie jest zgodny z tą Techniką.")

func _refresh_mini_only() -> void:
	if !visible || !page_open:
		return
	var species_id := StringName("")
	if page_kind == "dex" && GameState.is_seen(dex_cursor):
		species_id = StringName(CreatureDex.entry_by_index(dex_cursor).species_id)
	elif page_kind == "roster":
		var all := _roster_all()
		if roster_cursor >= 0 && roster_cursor < all.size():
			species_id = StringName(all[roster_cursor].get("species_id", "starter"))
	if String(species_id).is_empty():
		return
	var frames := CreatureDex.mini_frames(species_id)
	mini_preview.text = frames[_mini_phase]
