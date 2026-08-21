extends Resource
class_name SomaskanSpecies

@export var id: StringName
@export var display_name: String
@export var form_number: int = 0
@export var family_number: int = 0
@export var types: Array[StringName] = []
@export var base_hp: int = 20
@export var base_attack: int = 10
@export var base_defense: int = 10
@export var base_speed: int = 10
@export_range(1, 255, 1) var capture_rate: int = 120
@export var evolution_id: StringName
@export var learnset: Array[SomadexMoveData] = []
@export var visual: MonsterResources
@export var encyclopedia_text: String = ""
@export var rarity: StringName = &"common"

func max_hp_at_level(level: int) -> int:
	return maxi(1, base_hp + maxi(1, level) * 2)

func stat_at_level(base_value: int, level: int) -> int:
	return maxi(1, base_value + int(round(maxi(1, level) * 0.5)))
