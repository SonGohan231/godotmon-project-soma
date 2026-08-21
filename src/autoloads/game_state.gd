extends Node
class_name SomadexGameState

const SAVE_VERSION := 1
const DEFAULT_SAVE_PATH := "user://somadex_save.json"

var trainer: Dictionary = {}
var party: Array[Dictionary] = []
var storage: Array[Dictionary] = []
var bag: Dictionary = {}
var quest_flags: Dictionary = {}
var world: Dictionary = {}

func _ready() -> void:
	if trainer.is_empty():
		reset_new_game()

func reset_new_game() -> void:
	trainer = {"name":"Trener","level":1,"xp":0,"skill_points":0,"chosen_path":"","unlocked_paths":[]}
	party = [_make_somaskan(&"starter", 5, 48, [&"puls", &"slizg", &"rezonans", &"reset"])]
	storage = []
	bag = {"capsule":3,"bandage":2,"vela_token":0}
	quest_flags = {"vela_intro":false,"starter_received":true,"first_wild_battle":false}
	world = {"map_id":"vela","tile_x":5,"tile_y":5,"facing_x":0,"facing_y":1}

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
	trainer.xp = int(trainer.xp) + amount
	while int(trainer.xp) >= _xp_needed_for_level(int(trainer.level)):
		trainer.xp = int(trainer.xp) - _xp_needed_for_level(int(trainer.level))
		trainer.level = int(trainer.level) + 1
		trainer.skill_points = int(trainer.skill_points) + 1
	return trainer

func _xp_needed_for_level(level: int) -> int:
	return 80 + maxi(0, level - 1) * 35

func unlock_trainer_path(path_id: StringName) -> bool:
	var key := String(path_id)
	var unlocked: Array = trainer.get("unlocked_paths", [])
	if unlocked.has(key):
		return false
	unlocked.append(key)
	trainer.unlocked_paths = unlocked
	return true

func choose_trainer_path(path_id: StringName) -> bool:
	var key := String(path_id)
	if !Array(trainer.get("unlocked_paths", [])).has(key):
		return false
	trainer.chosen_path = key
	return true

func set_world_spawn(map_id: StringName, tile: Vector2i, facing: Vector2i = Vector2i.DOWN) -> void:
	world = {"map_id":String(map_id),"tile_x":tile.x,"tile_y":tile.y,"facing_x":facing.x,"facing_y":facing.y}

func add_captured_somaskan(species_id: StringName, level: int, hp: int, moves: Array) -> String:
	var entry := _make_somaskan(species_id, level, hp, moves)
	if party.size() < 6:
		party.append(entry)
	else:
		storage.append(entry)
	return String(entry.uid)

func mark_flag(flag_id: StringName, value: bool = true) -> void:
	quest_flags[String(flag_id)] = value

func to_dict() -> Dictionary:
	return {"version":SAVE_VERSION,"trainer":trainer.duplicate(true),"party":party.duplicate(true),"storage":storage.duplicate(true),"bag":bag.duplicate(true),"quest_flags":quest_flags.duplicate(true),"world":world.duplicate(true)}

func apply_dict(data: Dictionary) -> bool:
	if int(data.get("version", -1)) != SAVE_VERSION:
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
