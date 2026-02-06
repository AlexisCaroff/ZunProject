extends Node
class_name GameManager

@export var donjon: DonjonResource
var room_container: Node
var current_room_Ressource: RoomResource
@export var last_room_Ressource: RoomResource
@export var current_room_node: Node
@export_file("*.tscn") var campement_scene_path: String = "res://lvl/campement.tscn"
var campement_node: Node = null
@onready var end =$endGame
@export var inventory: Array[Equipment] = []
@export var characters: Array[CharacterData] = []
@onready var sceneTransition = $SceneTransition
@export var start_menu_scene: PackedScene = preload("res://UI/menuBase.tscn")

var start_menu: StartMenu = null
var game_started: bool = false

func _ready():
	var screen_index := 1
	
	if screen_index < DisplayServer.get_screen_count():
		DisplayServer.window_set_current_screen(screen_index)
	
	if not room_container:
		room_container = Node2D.new()
		add_child(room_container)
	spawn_start_menu()
	
	initialize_affinities(characters)
	await sceneTransition.fade_in()

func spawn_start_menu():
	if start_menu_scene == null:
		push_error("❌ Start menu scene not set")
		return

	start_menu = start_menu_scene.instantiate()
	add_child(start_menu)

	start_menu.game_manager = self
	
	
func start_game():
	if game_started:
		return

	game_started = true

	if start_menu and is_instance_valid(start_menu):
		start_menu.queue_free()
		start_menu = null

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
	await sceneTransition.fade_out()
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
	await sceneTransition.fade_in()

func go_back():
	await sceneTransition.fade_out()
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
	await sceneTransition.fade_in()
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
	current_room_Ressource.explored = true
	if get_room_by_id("Cellar").ennemikilled == true:
		end.visible=true
	await sceneTransition.fade_out()
	if scene:
		print("old scene is ", current_room_node.name)
		if current_room_node:
			print ("free old room")
			current_room_node.free()
			
			current_room_node = null

		
		var new_scene
		if current_room_Ressource.combat_scene and scene == current_room_Ressource.combat_scene and current_room_Ressource.ennemikilled == false:
			new_scene = scene.instantiate()
			var combat_manager = new_scene.find_child("CombatManager", true, false)

			if combat_manager:
				combat_manager.encounter = current_room_Ressource.encounter
				combat_manager.ennemy_are_ambushed = ennemy_are_embushed
				combat_manager.heroes_are_ambushed = heroes_are_embushed
				print("⚔️ Encounter assigned to CombatManager")
			else:
				push_error("⚠️ CombatManager introuvable dans la scène de combat")
		else : 
			new_scene = current_room_Ressource.exploration_scene.instantiate()
			
		room_container.add_child(new_scene)
		current_room_node = new_scene
		print("🌟 Start new room: ", new_scene.name)
		await sceneTransition.fade_in()
			

func go_to_campement():
	await sceneTransition.fade_out()
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
		current_room_node = null

	var campement_scene: PackedScene = load(campement_scene_path)
	campement_node = campement_scene.instantiate()
	room_container.add_child(campement_node)
	await sceneTransition.fade_in()

func return_to_exploration():
	await sceneTransition.fade_out()
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
		var exploManager =new_scene.get_node("ExplorationManager") as ExplorationManager
		
	await sceneTransition.fade_in()
func add_to_inventory(item: Equipment):
	inventory.append(item)
	print ("add "+ item.name+" to inventory")
	for i in inventory:
		print ( i.name + " is in Inventory GM ")

func initialize_affinities(thecharacters: Array[CharacterData]):
	for chara in thecharacters:
		chara.affinity = {}
		for other in thecharacters:
			if other != chara:
				chara.affinity[other.Charaname] = 20
	
func show_history_scene(history_res: HistoryScene) -> Node:
	var overlay_scene := preload("res://scripts/History/history.tscn")
	var overlay := overlay_scene.instantiate()

	overlay.history_scene = history_res
	get_tree().current_scene.add_child(overlay)

	return overlay
func show_Animatic_scene(Anim: Animatic, cam: Camera) -> Node:
	var Animatic_scene := preload("res://animatic/animatic_scene.tscn")
	var overlay := Animatic_scene.instantiate()
	
	overlay.animatic = Anim
	overlay.cam=cam
	get_tree().current_scene.add_child(overlay)

	return overlay
