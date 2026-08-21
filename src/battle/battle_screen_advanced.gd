extends BattleScreen
class_name SomadexBattleScreen

var _closing_with_fade := false

func start_battle(species_id: StringName, level: int, world_position: Vector2 = Vector2.ZERO) -> void:
	GameState.mark_seen(species_id)
	modulate.a = 0.0
	super.start_battle(species_id, level, world_position)
	if mode != Mode.CLOSED:
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.14)

func _load_active_from_state() -> void:
	super._load_active_from_state()
	if GameState.party.is_empty():
		return
	var active: Dictionary = GameState.party[0]
	player_data["moves"] = SomaskanCatalog.resolve_moves(Array(active.get("moves", [])), player_species_id)

func _refresh_player_hud() -> void:
	super._refresh_player_hud()
	player_sprite.text = CreatureDex.back_glyph(player_species_id)

func _species_glyph(species_id: StringName) -> String:
	return CreatureDex.front_glyph(species_id)

func _resolve_player_move(index: int) -> void:
	var moves: Array = player_data.get("moves", [])
	if index < 0 || index >= moves.size():
		return
	var move: Dictionary = moves[index]
	if _rng.randf() > float(move.get("accuracy", 1.0)):
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
	var typed := _typed_damage(move, player_level_value, player_data, enemy_data)
	var damage := int(typed.damage)
	if boost_used:
		damage = mini(int(round(float(enemy_hp.max_value) * 0.55)), maxi(1, int(round(damage * 1.35))))
	enemy_current_hp = maxi(0, enemy_current_hp - damage)
	enemy_hp.value = enemy_current_hp
	_register_move_resonance(move, boost_used)
	var suffix := SomadexTypeChart.feedback(float(typed.effectiveness)) + (" REZ!" if boost_used else "")
	if enemy_current_hp <= 0:
		_show_message("%s używa %s. -%d HP.%s %s pada!" % [player_data.name, move.name, damage, suffix, enemy_data.name], _win_battle)
	else:
		_show_message("%s używa %s. -%d HP.%s" % [player_data.name, move.name, damage, suffix], _enemy_turn)

func _enemy_turn() -> void:
	if enemy_current_hp <= 0:
		_win_battle()
		return
	var moves: Array = enemy_data.get("moves", [])
	if moves.is_empty():
		_set_mode(Mode.COMMAND)
		return
	var move: Dictionary = moves[_rng.randi_range(0, moves.size() - 1)]
	if _rng.randf() > float(move.get("accuracy", 1.0)):
		_show_message("%s używa %s... Pudło!" % [enemy_data.name, move.name], func(): _set_mode(Mode.COMMAND))
		return
	if int(move.get("power", 0)) < 0:
		var healed: int = mini(abs(int(move.power)), int(enemy_hp.max_value) - enemy_current_hp)
		enemy_current_hp += healed
		enemy_hp.value = enemy_current_hp
		_show_message("%s odnawia %d HP." % [enemy_data.name, healed], func(): _set_mode(Mode.COMMAND))
		return
	var typed := _typed_damage(move, enemy_level_value, enemy_data, player_data)
	var damage := int(typed.damage)
	player_current_hp = maxi(0, player_current_hp - damage)
	_sync_player_hp()
	_resonance.register_damage_taken(damage)
	_refresh_resonance()
	var suffix := SomadexTypeChart.feedback(float(typed.effectiveness))
	if player_current_hp <= 0:
		if _first_healthy_party_index(false) >= 0:
			_show_message("%s używa %s. -%d HP.%s %s nie może walczyć!" % [enemy_data.name, move.name, damage, suffix, player_data.name], _open_forced_party)
		else:
			_show_message("%s używa %s. Drużyna nie może dalej walczyć." % [enemy_data.name, move.name], _lose_battle)
	else:
		_show_message("%s używa %s. -%d HP.%s" % [enemy_data.name, move.name, damage, suffix], func(): _set_mode(Mode.COMMAND))

func _typed_damage(move: Dictionary, level: int, attacker: Dictionary, defender: Dictionary) -> Dictionary:
	var attack_type := StringName(move.get("type", "KONTAKT"))
	var attacker_types: Array = attacker.get("types", ["KONTAKT"])
	var defender_types: Array = defender.get("types", ["KONTAKT"])
	var effectiveness := SomadexTypeChart.effectiveness(attack_type, defender_types)
	var total := SomadexTypeChart.total_multiplier(attack_type, attacker_types, defender_types)
	var attack_stat := maxf(1.0, float(attacker.get("attack", 10)))
	var defense_stat := maxf(1.0, float(defender.get("defense", 10)))
	var stat_ratio := clampf(attack_stat / defense_stat, 0.68, 1.42)
	var base := float(move.get("power", 1)) * (0.70 + maxi(1, level) * 0.038) * stat_ratio
	var damage := maxi(1, int(round(base * total * _rng.randf_range(0.92, 1.08))))
	var defender_hp := _max_hp(defender, maxi(1, level))
	damage = mini(damage, maxi(2, int(round(defender_hp * 0.48))))
	return {"damage":damage,"effectiveness":effectiveness,"stab":SomadexTypeChart.stab(attack_type, attacker_types),"total":total}

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
