extends BattleScreen
class_name SomadexBattleScreen

var _closing_with_fade := false
var enemy_status: String = ""
var _enemy_pixel: Sprite2D
var _player_pixel: Sprite2D

func start_battle(species_id: StringName, level: int, world_position: Vector2 = Vector2.ZERO) -> void:
	GameState.mark_seen(species_id)
	enemy_status = ""
	modulate.a = 0.0
	super.start_battle(species_id, level, world_position)
	if mode != Mode.CLOSED:
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.14)

func _setup_hud() -> void:
	super._setup_hud()
	_refresh_status_hud()
	_refresh_pixel_sprites()

func _load_active_from_state() -> void:
	super._load_active_from_state()
	if GameState.party.is_empty():
		return
	var active: Dictionary = GameState.party[0]
	player_data["moves"] = SomaskanCatalog.resolve_moves(Array(active.get("moves", [])), player_species_id)

func _refresh_player_hud() -> void:
	super._refresh_player_hud()
	player_sprite.text = CreatureDex.back_glyph(player_species_id)
	_refresh_status_hud()
	_refresh_pixel_sprites()

func _species_glyph(species_id: StringName) -> String:
	return CreatureDex.front_glyph(species_id)

func _refresh_pixel_sprites() -> void:
	if !is_node_ready() || player_data.is_empty() || enemy_data.is_empty():
		return
	var arena := get_node_or_null("Arena")
	if arena == null:
		return
	if !is_instance_valid(_enemy_pixel):
		_enemy_pixel = Sprite2D.new()
		_enemy_pixel.name = "EnemyPixelArt"
		_enemy_pixel.position = Vector2(251, 47)
		_enemy_pixel.scale = Vector2(1.55, 1.55)
		_enemy_pixel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_enemy_pixel.z_index = 3
		arena.add_child(_enemy_pixel)
	if !is_instance_valid(_player_pixel):
		_player_pixel = Sprite2D.new()
		_player_pixel.name = "PlayerPixelArt"
		_player_pixel.position = Vector2(82, 90)
		_player_pixel.scale = Vector2(1.65, 1.65)
		_player_pixel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_player_pixel.z_index = 3
		arena.add_child(_player_pixel)
	_enemy_pixel.texture = CreaturePixelArt.battle_texture(enemy_species_id, false)
	_player_pixel.texture = CreaturePixelArt.battle_texture(player_species_id, true)
	enemy_sprite.visible = false
	player_sprite.visible = false

func _animate_attack(sprite: Sprite2D, direction: Vector2) -> void:
	if !is_instance_valid(sprite):
		return
	var origin := sprite.position
	var tween := create_tween()
	tween.tween_property(sprite, "position", origin + direction, 0.06)
	tween.tween_property(sprite, "position", origin, 0.08)

func _flash_hit(sprite: Sprite2D) -> void:
	if !is_instance_valid(sprite):
		return
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.30, 0.05)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.08)

func _player_status() -> String:
	if GameState.party.is_empty():
		return ""
	return String(GameState.party[0].get("status", ""))

func _set_player_status(status: String) -> void:
	if GameState.party.is_empty():
		return
	var member: Dictionary = GameState.party[0]
	member["status"] = status
	GameState.party[0] = member
	_refresh_status_hud()

func _refresh_status_hud() -> void:
	if !is_node_ready() || player_data.is_empty() || enemy_data.is_empty():
		return
	var player_tag := BattleStatus.short_label(_player_status())
	var enemy_tag := BattleStatus.short_label(enemy_status)
	player_name.text = String(player_data.get("name", "")).to_upper() + (" [%s]" % player_tag if !player_tag.is_empty() else "")
	enemy_name.text = String(enemy_data.get("name", "")).to_upper() + (" [%s]" % enemy_tag if !enemy_tag.is_empty() else "")

func _resolve_player_move(index: int) -> void:
	var moves: Array = player_data.get("moves", [])
	if index < 0 || index >= moves.size():
		return
	if !_tick_player_status():
		return
	var current_status := _player_status()
	if !BattleStatus.can_act(current_status, _rng):
		_show_message("%s nie może wykonać ruchu przez %s!" % [player_data.name, current_status], _enemy_turn)
		return
	var move: Dictionary = moves[index]
	var accuracy := clampf(float(move.get("accuracy", 1.0)) * BattleStatus.accuracy_multiplier(current_status), 0.35, 1.0)
	if _rng.randf() > accuracy:
		_show_message("%s używa %s... Pudło!" % [player_data.name, move.name], _enemy_turn)
		return
	var boost_used := _resonance_armed
	if int(move.get("power", 0)) < 0:
		var heal_power: int = abs(int(move.power))
		if boost_used:
			heal_power = maxi(1, int(round(heal_power * 1.25)))
		var healed: int = mini(heal_power, int(player_hp.max_value) - player_current_hp)
		player_current_hp += healed
		_sync_player_hp()
		_register_move_resonance(move, boost_used)
		_show_message("%s używa %s. +%d HP%s" % [player_data.name, move.name, healed, "  REZ!" if boost_used else ""], _enemy_turn)
		return
	_animate_attack(_player_pixel, Vector2(10, -3))
	var typed := SomadexBattleMath.damage(move, player_level_value, enemy_level_value, player_data, enemy_data, _rng.randf_range(0.92, 1.08))
	var damage := _status_adjusted_damage(int(typed.damage), move, current_status, enemy_status)
	if boost_used:
		damage = mini(int(round(float(enemy_hp.max_value) * 0.55)), maxi(1, int(round(damage * 1.35))))
	enemy_current_hp = maxi(0, enemy_current_hp - damage)
	enemy_hp.value = enemy_current_hp
	_flash_hit(_enemy_pixel)
	_register_move_resonance(move, boost_used)
	var suffix := SomadexTypeChart.feedback(float(typed.effectiveness)) + (" REZ!" if boost_used else "")
	if enemy_current_hp > 0:
		var previous_status := enemy_status
		enemy_status = BattleStatus.try_inflict(enemy_status, move, _rng)
		if enemy_status != previous_status:
			suffix += " %s!" % enemy_status
			_refresh_status_hud()
	if enemy_current_hp <= 0:
		_show_message("%s używa %s. -%d HP.%s %s pada!" % [player_data.name, move.name, damage, suffix, enemy_data.name], _win_battle)
	else:
		_show_message("%s używa %s. -%d HP.%s" % [player_data.name, move.name, damage, suffix], _enemy_turn)

func _enemy_turn() -> void:
	if enemy_current_hp <= 0:
		_win_battle()
		return
	if !_tick_enemy_status():
		return
	if !BattleStatus.can_act(enemy_status, _rng):
		_show_message("%s zatrzymuje %s!" % [enemy_status, enemy_data.name], func(): _set_mode(Mode.COMMAND))
		return
	var moves: Array = enemy_data.get("moves", [])
	if moves.is_empty():
		_set_mode(Mode.COMMAND)
		return
	var hp_ratio := float(enemy_current_hp) / maxf(1.0, float(enemy_hp.max_value))
	var ai_index := SomadexBattleAI.choose_move(moves, enemy_data, player_data, hp_ratio, _player_status())
	if ai_index < 0:
		_set_mode(Mode.COMMAND)
		return
	var move: Dictionary = moves[ai_index]
	var accuracy := clampf(float(move.get("accuracy", 1.0)) * BattleStatus.accuracy_multiplier(enemy_status), 0.35, 1.0)
	if _rng.randf() > accuracy:
		_show_message("%s używa %s... Pudło!" % [enemy_data.name, move.name], func(): _set_mode(Mode.COMMAND))
		return
	if int(move.get("power", 0)) < 0:
		var healed: int = mini(abs(int(move.power)), int(enemy_hp.max_value) - enemy_current_hp)
		enemy_current_hp += healed
		enemy_hp.value = enemy_current_hp
		_show_message("%s odnawia %d HP." % [enemy_data.name, healed], func(): _set_mode(Mode.COMMAND))
		return
	_animate_attack(_enemy_pixel, Vector2(-10, 3))
	var typed := SomadexBattleMath.damage(move, enemy_level_value, player_level_value, enemy_data, player_data, _rng.randf_range(0.92, 1.08))
	var damage := _status_adjusted_damage(int(typed.damage), move, enemy_status, _player_status())
	player_current_hp = maxi(0, player_current_hp - damage)
	_sync_player_hp()
	_flash_hit(_player_pixel)
	_resonance.register_damage_taken(damage)
	_refresh_resonance()
	var suffix := SomadexTypeChart.feedback(float(typed.effectiveness))
	if player_current_hp > 0:
		var previous_status := _player_status()
		var next_status := BattleStatus.try_inflict(previous_status, move, _rng)
		if next_status != previous_status:
			_set_player_status(next_status)
			suffix += " %s!" % next_status
	if player_current_hp <= 0:
		if _first_healthy_party_index(false) >= 0:
			_show_message("%s używa %s. -%d HP.%s %s nie może walczyć!" % [enemy_data.name, move.name, damage, suffix, player_data.name], _open_forced_party)
		else:
			_show_message("%s używa %s. Drużyna nie może dalej walczyć." % [enemy_data.name, move.name], _lose_battle)
	else:
		_show_message("%s używa %s. -%d HP.%s" % [enemy_data.name, move.name, damage, suffix], func(): _set_mode(Mode.COMMAND))

func _status_adjusted_damage(base_damage: int, move: Dictionary, attacker_status: String, defender_status: String) -> int:
	var multiplier := BattleStatus.attack_multiplier(attacker_status)
	multiplier /= maxf(0.1, BattleStatus.defense_multiplier(defender_status))
	multiplier *= BattleStatus.incoming_type_multiplier(defender_status, StringName(move.get("type", "KONTAKT")))
	return maxi(1, int(round(float(base_damage) * multiplier)))

func _tick_player_status() -> bool:
	var residual := BattleStatus.residual_damage(_player_status(), int(player_hp.max_value))
	if residual <= 0:
		return true
	player_current_hp = maxi(0, player_current_hp - residual)
	_sync_player_hp()
	if player_current_hp > 0:
		return true
	if _first_healthy_party_index(false) >= 0:
		_show_message("%s przegrywa z %s." % [player_data.name, _player_status()], _open_forced_party)
	else:
		_show_message("Drużyna nie może dalej walczyć.", _lose_battle)
	return false

func _tick_enemy_status() -> bool:
	var residual := BattleStatus.residual_damage(enemy_status, int(enemy_hp.max_value))
	if residual <= 0:
		return true
	enemy_current_hp = maxi(0, enemy_current_hp - residual)
	enemy_hp.value = enemy_current_hp
	if enemy_current_hp > 0:
		return true
	_show_message("%s pada przez %s!" % [enemy_data.name, enemy_status], _win_battle)
	return false

func _use_bandage() -> void:
	var has_status := !_player_status().is_empty()
	var missing_hp := int(player_hp.max_value) - player_current_hp
	if missing_hp <= 0 && !has_status:
		_show_message("%s ma pełne HP i brak statusu." % player_data.name, func(): _set_mode(Mode.BAG))
		return
	if int(GameState.bag.get("bandage", 0)) <= 0:
		_show_message("Brak Opatrunków w plecaku.", func(): _set_mode(Mode.BAG))
		return
	if !GameState.consume_item(&"bandage", 1):
		return
	var heal_amount := maxi(8, int(round(float(player_hp.max_value) * 0.35)))
	var healed := mini(missing_hp, heal_amount)
	player_current_hp += healed
	_sync_player_hp()
	var cured := _player_status()
	if !cured.is_empty():
		_set_player_status("")
	_refresh_bag()
	var cure_text := " • usunięto %s" % cured if !cured.is_empty() else ""
	_show_message("Opatrunek odnawia %d HP%s." % [healed, cure_text], _enemy_turn)

func _win_battle() -> void:
	var trainer_xp := 10 + enemy_level_value * 4
	var xp_result := GameState.award_active_somaskan_xp(enemy_species_id, enemy_level_value)
	GameState.add_trainer_xp(trainer_xp)
	GameState.mark_flag(&"first_wild_battle")
	var somaskan_xp := int(xp_result.get("xp_gained", 0))
	var message := "Wygrana! %s +%d XP • Trener +%d XP." % [player_data.name, somaskan_xp, trainer_xp]
	if int(xp_result.get("levels_gained", 0)) > 0:
		message += " LV %d!" % int(xp_result.get("new_level", player_level_value))
	var evolutions: Array = xp_result.get("evolutions", [])
	if !evolutions.is_empty():
		var last_evolution: Dictionary = evolutions[evolutions.size() - 1]
		message += " EWOLUCJA: %s → %s!" % [String(last_evolution.get("from", "")), String(last_evolution.get("to", ""))]
	# Reload evolved/leveled member so the base close sync cannot overwrite its new HP.
	_load_active_from_state()
	player_current_hp = int(GameState.party[0].get("current_hp", player_current_hp)) if !GameState.party.is_empty() else player_current_hp
	_refresh_pixel_sprites()
	_show_message(message, _close_battle)

func _close_battle() -> void:
	if _closing_with_fade || mode == Mode.CLOSED:
		return
	_closing_with_fade = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	await tween.finished
	super._close_battle()
	modulate.a = 1.0
	_closing_with_fade = false
