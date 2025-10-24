extends Node
class_name GameManager

@export var donjon: DonjonResource
var room_container: Node
var current_room_Ressource: RoomResource
var last_room_Ressource: RoomResource
@export var current_room_node: Node
@export_file("*.tscn") var campement_scene_path: String = "res://lvl/campement.tscn"
var campement_node: Node = null

func _ready():
	var screen_index := 1
	if screen_index < DisplayServer.get_screen_count():
		DisplayServer.window_set_current_screen(screen_index)

	if not room_container:
		room_container = Node2D.new()
		add_child(room_container)

	if donjon and donjon.start_room_id != "":
		var start_room = get_room_by_id(donjon.start_room_id)
		if start_room:
			call_deferred("enter_room", start_room)
		else:
			push_error("❌ Start room introuvable pour ID : " + donjon.start_room_id)



func enter_room(room: RoomResource, changedoor: bool = false):
	if not changedoor:
		last_room_Ressource = current_room_Ressource
	current_room_Ressource = room

	print("🏰 Current room is ", current_room_Ressource.room_id)

	if current_room_node:
		current_room_node.queue_free()
		current_room_node = null

	var scene_to_load: PackedScene = null
	if room.door_scene:
		scene_to_load = room.door_scene
		print("🔓 Load door scene : " + scene_to_load.resource_name)

	if scene_to_load:
		var new_scene = scene_to_load.instantiate()
		room_container.add_child(new_scene)
		current_room_node = new_scene


func go_back():
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
		current_room_node = null

	var scene_to_load: PackedScene = null
	if last_room_Ressource and last_room_Ressource.exploration_scene:
		scene_to_load = last_room_Ressource.exploration_scene

	if scene_to_load:
		var new_scene = scene_to_load.instantiate()
		room_container.add_child(new_scene)
		current_room_node = new_scene

# 🔍 Retourne une RoomResource depuis son ID
func get_room_by_id(room_id: String) -> RoomResource:
	for r in donjon.rooms:
		if r.room_id == room_id:
			return r
	return null


func go_to_connected_room(index: int):
	if not current_room_Ressource:
		push_error("❌ Current room undefined.")
		return

	if index < 0 or index >= current_room_Ressource.connected_room_ids.size():
		push_error("❌ Invalid room index")
		return

	var next_room_id = current_room_Ressource.connected_room_ids[index]
	var next_room = get_room_by_id(next_room_id)
	if not next_room:
		push_error("❌ Connected room introuvable pour ID : " + next_room_id)
		return

	enter_room(next_room)


func _enter_scene_in_current_room(scene: PackedScene, ennemy_are_embushed: bool = false, heroes_are_embushed: bool = false):
	if scene:
		print("old scene is ", current_room_node.name)
		if current_room_node:
			current_room_node.free()
			current_room_node = null

		var new_scene = scene.instantiate()

		if current_room_Ressource.combat_scene and scene == current_room_Ressource.combat_scene:
			if new_scene.has_node("CombatManager"):
				var combat_manager = new_scene.get_node("CombatManager")
				combat_manager.encounter = current_room_Ressource.encounter
				combat_manager.ennemy_are_ambushed = ennemy_are_embushed
				combat_manager.heroes_are_ambushed = heroes_are_embushed
				print("⚔️ Encounter assigned to CombatManager")
			else:
				push_error("⚠️ CombatManager introuvable dans la scène de combat")

		room_container.add_child(new_scene)
		current_room_node = new_scene
		print("🌟 Start new room: ", new_scene.name)


func go_to_campement():
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
		current_room_node = null

	var campement_scene: PackedScene = load(campement_scene_path)
	campement_node = campement_scene.instantiate()
	room_container.add_child(campement_node)


func return_to_exploration():
	if campement_node and is_instance_valid(campement_node):
		campement_node.queue_free()
		campement_node = null

	var scene_to_load: PackedScene = null
	if current_room_Ressource and current_room_Ressource.exploration_scene:
		scene_to_load = current_room_Ressource.exploration_scene

	if scene_to_load:
		var new_scene = scene_to_load.instantiate()
		room_container.add_child(new_scene)
		current_room_node = new_scene
