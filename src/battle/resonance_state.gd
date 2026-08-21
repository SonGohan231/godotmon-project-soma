extends RefCounted
class_name ResonanceState

const MAX_VALUE := 100
const ACTIVATION_COST := 100

var value: int = 0
var last_type: StringName
var chain: int = 0

func reset() -> void:
	value = 0
	last_type = &""
	chain = 0

func register_move(move_type: StringName, base_gain: int) -> int:
	var gain := maxi(0, base_gain)
	if move_type != &"" && last_type != &"" && move_type != last_type:
		chain = mini(chain + 1, 3)
		gain += chain * 2
	else:
		chain = 0
	last_type = move_type
	value = clampi(value + gain, 0, MAX_VALUE)
	return value

func register_damage_taken(damage: int) -> int:
	value = clampi(value + clampi(damage / 2, 0, 12), 0, MAX_VALUE)
	return value

func can_activate() -> bool:
	return value >= ACTIVATION_COST

func activate() -> bool:
	if !can_activate():
		return false
	value -= ACTIVATION_COST
	chain = 0
	return true

func ratio() -> float:
	return float(value) / float(MAX_VALUE)
