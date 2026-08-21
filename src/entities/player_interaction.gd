extends Node

@onready var player: CharacterBody2D = get_parent()
@onready var mover: Node = player.get_node("EntityMoverComponent")
@onready var ray: RayCast2D = $InteractionRay

func _process(_delta: float) -> void:
	var facing: Vector2 = mover._facing_direction
	ray.target_position = facing * Constants.TILE_SIZE
	if Observer.world_input_blocked():
		return
	if Input.is_action_just_pressed("ui_accept"):
		_try_interact()

func _try_interact() -> void:
	if Observer.world_input_blocked():
		return
	ray.force_raycast_update()
	if !ray.is_colliding():
		return
	var target := ray.get_collider()
	if target != null && target.has_method("interact"):
		target.interact(player)
