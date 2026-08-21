extends SomadexBattleScreen
class_name SomadexBattleScreenVisual

func _setup_hud() -> void:
	super._setup_hud()
	_apply_mobile_layout()

func _apply_mobile_layout() -> void:
	var command_box: Panel = $CommandBox
	command_box.offset_left = 95.0
	command_box.offset_top = 126.0
	command_box.offset_right = 226.0
	command_box.offset_bottom = 176.0
	_layout_choice($CommandBox/C0, Rect2(6, 5, 57, 17), 8)
	_layout_choice($CommandBox/C1, Rect2(68, 5, 57, 17), 8)
	_layout_choice($CommandBox/C2, Rect2(6, 27, 57, 17), 8)
	_layout_choice($CommandBox/C3, Rect2(68, 27, 57, 17), 8)

	var move_box: Panel = $MoveBox
	move_box.offset_left = 95.0
	move_box.offset_top = 112.0
	move_box.offset_right = 226.0
	move_box.offset_bottom = 176.0
	_layout_choice($MoveBox/M0, Rect2(6, 5, 57, 15), 7)
	_layout_choice($MoveBox/M1, Rect2(68, 5, 57, 15), 7)
	_layout_choice($MoveBox/M2, Rect2(6, 22, 57, 15), 7)
	_layout_choice($MoveBox/M3, Rect2(68, 22, 57, 15), 7)
	var move_info: Label = $MoveBox/Info
	move_info.offset_left = 6.0
	move_info.offset_top = 41.0
	move_info.offset_right = 125.0
	move_info.offset_bottom = 59.0
	move_info.add_theme_font_size_override("font_size", 6)

	var party_box: Panel = $PartyBox
	party_box.offset_left = 95.0
	party_box.offset_top = 106.0
	party_box.offset_right = 226.0
	party_box.offset_bottom = 176.0
	var party_positions := [Rect2(6,4,57,13),Rect2(68,4,57,13),Rect2(6,19,57,13),Rect2(68,19,57,13),Rect2(6,34,57,13),Rect2(68,34,57,13)]
	for i in party_labels.size():
		_layout_choice(party_labels[i], party_positions[i], 6)
	party_info.offset_left = 6.0
	party_info.offset_top = 51.0
	party_info.offset_right = 125.0
	party_info.offset_bottom = 66.0
	party_info.add_theme_font_size_override("font_size", 6)

	var bag_box: Panel = $BagBox
	bag_box.offset_left = 95.0
	bag_box.offset_top = 114.0
	bag_box.offset_right = 226.0
	bag_box.offset_bottom = 176.0
	_layout_choice($BagBox/B0, Rect2(6,4,119,13), 7)
	_layout_choice($BagBox/B1, Rect2(6,18,119,13), 7)
	_layout_choice($BagBox/B2, Rect2(6,32,119,13), 7)
	bag_info.offset_left = 6.0
	bag_info.offset_top = 46.0
	bag_info.offset_right = 125.0
	bag_info.offset_bottom = 59.0
	bag_info.add_theme_font_size_override("font_size", 6)

	enemy_name.add_theme_font_size_override("font_size", 9)
	player_name.add_theme_font_size_override("font_size", 9)
	enemy_level.add_theme_font_size_override("font_size", 8)
	player_level.add_theme_font_size_override("font_size", 8)

func _layout_choice(label: Label, rect: Rect2, font_size: int) -> void:
	label.offset_left = rect.position.x
	label.offset_top = rect.position.y
	label.offset_right = rect.position.x + rect.size.x
	label.offset_bottom = rect.position.y + rect.size.y
	label.add_theme_font_size_override("font_size", font_size)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _refresh_commands() -> void:
	var names := ["ATAK", "DRUŻYNA", "PLECAK", "UCIECZKA"]
	for i in command_labels.size():
		command_labels[i].text = ("▶ " if i == command_index else "  ") + names[i]

func _refresh_moves() -> void:
	var moves: Array = player_data.get("moves", [])
	for i in move_labels.size():
		if i < moves.size():
			var raw_name := String(moves[i].name)
			var short_name := raw_name if raw_name.length() <= 10 else raw_name.substr(0, 9) + "…"
			move_labels[i].text = ("▶" if i == move_index else " ") + short_name
		else:
			move_labels[i].text = "--"
	if move_index < moves.size():
		var move: Dictionary = moves[move_index]
		var resonance_hint := "REZ!" if _resonance_armed else ("START=REZ" if _resonance.can_activate() else "R%d%%" % _resonance.value)
		var selected_name := String(move.name)
		if selected_name.length() > 15:
			selected_name = selected_name.substr(0, 14) + "…"
		move_info.text = "%s • %s • M%s • %d%% • %s" % [selected_name, String(move.type), "L" if int(move.power) < 0 else str(move.power), int(float(move.accuracy) * 100.0), resonance_hint]
