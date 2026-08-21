extends Node

## Autoload responsible for adding and removing world/entity/UI scenes under Main.

enum SceneType {WORLD, ENTITY, UI}

var main: Main

func _ready() -> void:
	_resolve_main()

func _resolve_main() -> Main:
	if is_instance_valid(main):
		return main
	main = get_tree().root.get_node_or_null("Main") as Main
	return main

func add_scene(scene_path: String, scene_type: SceneType, coordinates: Vector2i = Vector2i.ZERO) -> void:
	var root_main := _resolve_main()
	if root_main == null:
		push_error("ScenesManager: Main scene is not available while adding %s" % scene_path)
		return
	var final_position: Vector2i = coordinates * Constants.TILE_SIZE
	match scene_type:
		SceneType.WORLD:
			var scene: Node2D = load(scene_path).instantiate()
			scene.global_position = final_position
			root_main.world_parent.add_child(scene)
		SceneType.ENTITY:
			var scene: Node2D = load(scene_path).instantiate()
			scene.global_position = final_position
			root_main.world_parent.add_child(scene)
		SceneType.UI:
			var scene: Control = load(scene_path).instantiate()
			scene.global_position = coordinates
			root_main.ui_parent.add_child(scene)

func remove_scene(scene_name: String, scene_type: SceneType) -> void:
	var root_main := _resolve_main()
	if root_main == null:
		return
	match scene_type:
		SceneType.WORLD, SceneType.ENTITY:
			var node_to_remove: Node2D = root_main.world_parent.get_node_or_null(scene_name)
			if node_to_remove != null:
				node_to_remove.queue_free()
		SceneType.UI:
			var node_to_remove: Control = root_main.ui_parent.get_node_or_null(scene_name)
			if node_to_remove != null:
				node_to_remove.queue_free()
