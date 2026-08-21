extends SomadexStartMenu
class_name SomadexStartMenuPixel

var _mini_sprite: Sprite2D

func _ready() -> void:
	super._ready()
	_mini_sprite = Sprite2D.new()
	_mini_sprite.name = "MiniPixelArt"
	_mini_sprite.position = Vector2(152, 15)
	_mini_sprite.scale = Vector2(1.35, 1.35)
	_mini_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mini_sprite.z_index = 3
	$Info.add_child(_mini_sprite)
	mini_preview.visible = false
	_mini_sprite.visible = false

func _render_dex() -> void:
	var entry := CreatureDex.entry_by_index(dex_cursor)
	var seen := GameState.is_seen(dex_cursor)
	var caught := GameState.is_caught(dex_cursor)
	info_title.text = "SOMADEX %03d/%03d" % [dex_cursor, CreatureDex.count()]
	if !seen:
		info_body.text = "???\nNie spotkano jeszcze tego Somaskana.\n\nWidziane %d/150  Złapane %d/150\n◀/▶ wpis  ▲/▼ ±10\nZ — wróć" % [GameState.seen_count(), GameState.caught_count()]
		_mini_sprite.visible = false
		return
	var caught_mark := " ★" if caught else ""
	var evolution_text := "FORMA FINALNA"
	if !String(entry.get("evolves_to", "")).is_empty():
		var next := CreatureDex.get_species(StringName(entry.evolves_to))
		evolution_text = "→ %s  Lv.%d" % [String(next.name), int(entry.evolution_level)]
	info_body.text = "%s%s\n%s\n%s\n%s\n%s\n\nWidziane %d/150  Złapane %d/150\n◀/▶ wpis  ▲/▼ ±10" % [String(entry.name).to_upper(), caught_mark, " / ".join(Array(entry.types)), evolution_text, String(entry.description), "Siedlisko: " + String(entry.habitat), GameState.seen_count(), GameState.caught_count()]
	_refresh_mini_only()

func _render_roster() -> void:
	var all := _roster_all()
	info_title.text = "SOMASKANY %d/%d" % [roster_cursor + 1, maxi(1, all.size())]
	if all.is_empty():
		info_body.text = "Brak Somaskanów.\nZ — wróć"
		_mini_sprite.visible = false
		return
	var member: Dictionary = all[roster_cursor]
	var species := CreatureDex.get_species(StringName(member.get("species_id", "starter")))
	var level := int(member.get("level", 1))
	var xp := int(member.get("xp", 0))
	var xp_next := CreatureProgression.xp_to_next(level)
	var status := String(member.get("status", ""))
	var status_text := status if !status.is_empty() else "OK"
	var evolution_text := "FINAL"
	if !String(species.get("evolves_to", "")).is_empty():
		var next := CreatureDex.get_species(StringName(species.evolves_to))
		evolution_text = "%s Lv.%d" % [String(next.name), int(species.evolution_level)]
	var moves := SomaskanCatalog.resolve_moves(Array(member.get("moves", [])), StringName(member.get("species_id", "starter")))
	var move_names: Array[String] = []
	for move in moves:
		move_names.append(String(move.name))
	info_body.text = "%s  LV %d\n%s • HP %d • %s\n%s\nXP %d/%d • Więź %d\nEwolucja: %s\nRuchy: %s\n\n◀/▶ następny" % [String(species.name).to_upper(), level, String(member.location), int(member.get("current_hp",0)), status_text, " / ".join(Array(species.types)), xp, xp_next, int(member.get("friendship",0)), evolution_text, ", ".join(move_names)]
	_refresh_mini_only()

func _refresh_mini_only() -> void:
	if !visible || !page_open || !is_instance_valid(_mini_sprite):
		return
	var species_id := StringName("")
	if page_kind == "dex" && GameState.is_seen(dex_cursor):
		species_id = StringName(CreatureDex.entry_by_index(dex_cursor).species_id)
	elif page_kind == "roster":
		var all := _roster_all()
		if roster_cursor >= 0 && roster_cursor < all.size():
			species_id = StringName(all[roster_cursor].get("species_id", "starter"))
	if String(species_id).is_empty():
		_mini_sprite.visible = false
		return
	_mini_sprite.texture = CreaturePixelArt.mini_texture(species_id, _mini_phase)
	_mini_sprite.visible = true
