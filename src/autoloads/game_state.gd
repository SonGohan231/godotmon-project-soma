extends Node
class_name SomadexGameState

const SAVE_VERSION := 2
const DEFAULT_SAVE_PATH := "user://somadex_save.json"

var trainer: Dictionary = {}
var party: Array[Dictionary] = []
var storage: Array[Dictionary] = []
var bag: Dictionary = {}
var quest_flags: Dictionary = {}
var world: Dictionary = {}
var somadex_seen: Dictionary = {}
var somadex_caught: Dictionary = {}
var techniques: Dictionary = {}

func _ready() -> void:
	if trainer.is_empty():
		reset_new_game()

func reset_new_game() -> void:
	trainer = {"name":"Trener","level":1,"xp":0,"skill_points":0,"chosen_path":"","unlocked_paths":[]}
	var starter_moves := SomaskanCatalog.move_ids(&"starter")
	party = [_make_somaskan(&"starter", 5, 48, starter_moves)]
	storage = []
	bag = {"capsule":3,"bandage":2,"vela_token":0}
	quest_flags = {"vela_intro":false,"starter_received":true,"first_wild_battle":false}
	world = {"map_id":"vela","tile_x":5,"tile_y":5,"facing_x":0,"facing_y":1}
	somadex_seen = {}
	somadex_caught = {}
	techniques = {"TM0001":true}
	mark_seen(&"starter")
	mark_caught(&"starter")

func _make_somaskan(species_id: StringName, level: int, hp: int, moves: Array) -> Dictionary:
	var serialized_moves: Array[String] = []
	for move_id in moves:
		serialized_moves.append(String(move_id))
	return {"uid":"%s-%s-%d" % [String(species_id),Time.get_unix_time_from_system(),randi()],"species_id":String(species_id),"nickname":"","level":level,"xp":0,"current_hp":hp,"status":"","moves":serialized_moves}

func add_item(item_id: StringName, amount: int = 1) -> int:
	var key := String(item_id)
	bag[key] = maxi(0, int(bag.get(key, 0)) + amount)
	return int(bag[key])

func consume_item(item_id: StringName, amount: int = 1) -> bool:
	var key := String(item_id)
	var current := int(bag.get(key, 0))
	if amount <= 0 || current < amount:
		return false
	bag[key] = current - amount
	return true

func add_trainer_xp(amount: int) -> Dictionary:
	if amount <= 0:
		return trainer
	trainer["xp"] = int(trainer.get("xp", 0)) + amount
	while int(trainer.get("xp", 0)) >= _xp_needed_for_level(int(trainer.get("level", 1))):
		trainer["xp"] = int(trainer.xp) - _xp_needed_for_level(int(trainer.level))
		trainer["level"] = int(trainer.level) + 1
		trainer["skill_points"] = int(trainer.get("skill_points", 0)) + 1
	return trainer

func _xp_needed_for_level(level: int) -> int:
	return 80 + maxi(0, level - 1) * 35

func unlock_trainer_path(path_id: StringName) -> bool:
	var key := String(path_id)
	var unlocked: Array = trainer.get("unlocked_paths", [])
	if unlocked.has(key):
		return false
	unlocked.append(key)
	trainer["unlocked_paths"] = unlocked
	return true

func choose_trainer_path(path_id: StringName) -> bool:
	var key := String(path_id)
	if !Array(trainer.get("unlocked_paths", [])).has(key):
		return false
	trainer["chosen_path"] = key
	return true

func set_world_spawn(map_id: StringName, tile: Vector2i, facing: Vector2i = Vector2i.DOWN) -> void:
	world = {"map_id":String(map_id),"tile_x":tile.x,"tile_y":tile.y,"facing_x":facing.x,"facing_y":facing.y}

func add_captured_somaskan(species_id: StringName, level: int, hp: int, moves: Array) -> String:
	var canonical := CreatureDex.get_species(species_id)
	var canonical_id := StringName(canonical.get("species_id", String(species_id)))
	var entry := _make_somaskan(canonical_id, level, hp, moves)
	if party.size() < 6:
		party.append(entry)
	else:
		storage.append(entry)
	mark_seen(canonical_id)
	mark_caught(canonical_id)
	return String(entry.uid)

func mark_seen(species_id: StringName) -> void:
	var index := CreatureDex.dex_index_for_species(species_id)
	somadex_seen[str(index)] = true

func mark_caught(species_id: StringName) -> void:
	var index := CreatureDex.dex_index_for_species(species_id)
	somadex_seen[str(index)] = true
	somadex_caught[str(index)] = true

func is_seen(dex_index: int) -> bool:
	return bool(somadex_seen.get(str(dex_index), false))

func is_caught(dex_index: int) -> bool:
	return bool(somadex_caught.get(str(dex_index), false))

func seen_count() -> int:
	return somadex_seen.size()

func caught_count() -> int:
	return somadex_caught.size()

func add_tm(tm_id: StringName) -> bool:
	var key := String(tm_id).to_upper()
	if TechniqueCatalog.get_tm(StringName(key)).is_empty():
		return false
	techniques[key] = true
	return true

func has_tm(tm_id: StringName) -> bool:
	return bool(techniques.get(String(tm_id).to_upper(), false))

func owned_tm_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in techniques.keys():
		if bool(techniques[key]):
			ids.append(String(key))
	ids.sort()
	return ids

func teach_tm(party_index: int, tm_id: StringName, slot: int) -> bool:
	if party_index < 0 || party_index >= party.size() || slot < 0 || slot > 3 || !has_tm(tm_id):
		return false
	var member: Dictionary = party[party_index]
	var species := CreatureDex.get_species(StringName(member.get("species_id", "starter")))
	if !TechniqueCatalog.compatible(Array(species.get("types", [])), tm_id):
		return false
	var moves: Array = Array(member.get("moves", [])).duplicate()
	while moves.size() < 4:
		moves.append("")
	moves[slot] = String(tm_id).to_upper()
	member["moves"] = moves
	party[party_index] = member
	return true

func mark_flag(flag_id: StringName, value: bool = true) -> void:
	quest_flags[String(flag_id)] = value

func to_dict() -> Dictionary:
	return {"version":SAVE_VERSION,"trainer":trainer.duplicate(true),"party":party.duplicate(true),"storage":storage.duplicate(true),"bag":bag.duplicate(true),"quest_flags":quest_flags.duplicate(true),"world":world.duplicate(true),"somadex_seen":somadex_seen.duplicate(true),"somadex_caught":somadex_caught.duplicate(true),"techniques":techniques.duplicate(true)}

func apply_dict(data: Dictionary) -> bool:
	var version := int(data.get("version", -1))
	if version != 1 && version != SAVE_VERSION:
		return false
	trainer = Dictionary(data.get("trainer", {})).duplicate(true)
	party.clear()
	for raw_member in Array(data.get("party", [])):
		if typeof(raw_member) == TYPE_DICTIONARY:
			party.append(Dictionary(raw_member).duplicate(true))
	storage.clear()
	for raw_member in Array(data.get("storage", [])):
		if typeof(raw_member) == TYPE_DICTIONARY:
			storage.append(Dictionary(raw_member).duplicate(true))
	bag = Dictionary(data.get("bag", {})).duplicate(true)
	quest_flags = Dictionary(data.get("quest_flags", {})).duplicate(true)
	world = Dictionary(data.get("world", {})).duplicate(true)
	somadex_seen = Dictionary(data.get("somadex_seen", {})).duplicate(true)
	somadex_caught = Dictionary(data.get("somadex_caught", {})).duplicate(true)
	techniques = Dictionary(data.get("techniques", {})).duplicate(true)
	if version == 1:
		techniques["TM0001"] = true
		for member in party:
			mark_seen(StringName(member.get("species_id", "starter")))
			mark_caught(StringName(member.get("species_id", "starter")))
		for member in storage:
			mark_seen(StringName(member.get("species_id", "starter")))
			mark_caught(StringName(member.get("species_id", "starter")))
	return !trainer.is_empty() && !world.is_empty()

func save_game(path: String = DEFAULT_SAVE_PATH) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(to_dict(), "\t"))
	file.close()
	return OK

func load_game(path: String = DEFAULT_SAVE_PATH) -> bool:
	if !FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	return apply_dict(parsed)

func has_save(path: String = DEFAULT_SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)
