extends SomadexStartMenu
class_name SomadexStartMenuPixel

var _mini_sprite: Sprite2D

func _ready() -> void:
	super._ready()
	_mini_sprite = Sprite2D.new()
	_mini_sprite.name = "MiniPixelArt"
	_mini_sprite.position = Vector2(151, 15)
	_mini_sprite.scale = Vector2(1.35, 1.35)
	_mini_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mini_sprite.z_index = 3
	$Info.add_child(_mini_sprite)
	mini_preview.visible = false
	_mini_sprite.visible = false

func _apply_layout(page_mode: bool) -> void:
	super._apply_layout(page_mode)
	if is_instance_valid(_mini_sprite):
		if page_mode:
			_mini_sprite.position = Vector2(270, 16)
			_mini_sprite.scale = Vector2(1.55, 1.55)
		else:
			_mini_sprite.position = Vector2(151, 15)
			_mini_sprite.scale = Vector2(1.35, 1.35)
		if !page_mode:
			_mini_sprite.visible = false

func _render_dex() -> void:
	super._render_dex()
	if !GameState.is_seen(dex_cursor) && is_instance_valid(_mini_sprite):
		_mini_sprite.visible = false

func _render_roster() -> void:
	super._render_roster()
	if _roster_all().is_empty() && is_instance_valid(_mini_sprite):
		_mini_sprite.visible = false

func _render_tm(note: String = "") -> void:
	super._render_tm(note)
	if is_instance_valid(_mini_sprite):
		_mini_sprite.visible = false

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
