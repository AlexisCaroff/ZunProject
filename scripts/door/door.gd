extends Node
class_name Door
@onready var Doortext : TextureRect= $DoorText
var big_size = Vector2(1.2, 1.2)
var startsize = Vector2(1.0,1.0)
var current_tween: Tween = null
var Game_Manager:GameManager
var timePeeking : float = 0.0
@onready var left_button: Button = $"../LastDoor"
@onready var right_button: Button = $"../NextDoor"
var current_index: int = -1
var connected_ids: Array = []
var peeking: bool = true
@onready var sub_viewport : Viewport= $"../SubViewportContainer/SubViewport"
var encounter_for_this_door: CombatEncounter
@onready var embuscadeUI: TextureRect = $"../EmbuscadeUI"
var peek_scene
var ennemy_are_embushed : bool = false
var heroes_are_embushed : bool = false
@onready var viewport: Viewport = $"../SubViewportContainer2/SubViewport"
@onready var donjon_map: Map = $"../SubViewportContainer2/SubViewport/map"

func _ready():
	Game_Manager = get_tree().root.get_node("GameManager") 
	if Game_Manager:
		print ("Find Game manager")
	peek_scene = load("res://UI/peekScene.tscn").instantiate()
	sub_viewport.add_child(peek_scene)
	
	#print("next room ready")
	#print(GameManager.current_room_Ressource.resource_name)
	encounter_for_this_door= Game_Manager.current_room_Ressource.encounter
	if Game_Manager.last_room_Ressource :
		if Game_Manager.last_room_Ressource.connected_room_ids.size()>1:
			connected_ids = Game_Manager.last_room_Ressource.connected_room_ids.duplicate()
			if connected_ids.is_empty():
				push_warning("⚠️ Aucune room connectée depuis " + str(Game_Manager.last_room_Ressource.room_id))
				left_button.disabled = true
				right_button.disabled = true
				return

			# Trouve l'index de la room actuelle dans cette liste
			current_index = connected_ids.find(Game_Manager.current_room_Ressource.room_id)
			if current_index == -1:
				current_index = 0  # fallback si jamais l'id n'existe pas
				print("⚠️ current_room non trouvée dans connected_room_ids, utilisation de l'index 0")

			# Connecte les boutons
			left_button.pressed.connect(_on_left_pressed)
			right_button.pressed.connect(_on_right_pressed)
		else :
			left_button.disabled=true
			left_button.modulate.a = 0.2
			right_button.disabled=true
			right_button.modulate.a = 0.2
	else :
		left_button.disabled=true
		left_button.modulate.a = 0.2
		right_button.disabled=true
		right_button.modulate.a = 0.2
	
	await get_tree().process_frame  # attendre que la frame d'instanciation soit finie
	donjon_map.curentposition = donjon_map.positions[Game_Manager.current_room_Ressource.position_on_map]
	if donjon_map:
		donjon_map.focus_on_room(donjon_map.curentposition, viewport)
		donjon_map.move_to_position(donjon_map.curentposition)
	
func _on_mouse_exited() -> void:
	Doortext.scale = big_size	
	Doortext.set_pivot_offset(Doortext.size/ 2)
	if current_tween:
		current_tween.kill()

	current_tween = create_tween()
	current_tween.tween_property(Doortext, "scale", startsize, 0.2)



func _on_mouse_entered() -> void:
	Doortext.scale = startsize 	
	Doortext.set_pivot_offset(Doortext.size / 2)


	if current_tween:
		current_tween.kill()


	current_tween = create_tween()
	current_tween.tween_property(Doortext , "scale", big_size, 0.2)
	



func _on_button_down() -> void:
	call_deferred("_advance_in_room")
	
	

func _advance_in_room():
	GameState.current_phase = GameStat.GamePhase.COMBAT
	if not Game_Manager.current_room_Ressource:
		push_error("No current_room defined in GameManager")
		return
	
	var room = Game_Manager.current_room_Ressource
	var scene_to_load: PackedScene = null

	# priorité combat → sinon exploration
	if room.combat_scene and room.encounter:
		scene_to_load = room.combat_scene
		
	elif room.exploration_scene:
		scene_to_load = room.exploration_scene
	else:
		push_error("Room has no valid scene after door")
		return

	# Demander au GameManager d'entrer dans la bonne scène
	Game_Manager._enter_scene_in_current_room(scene_to_load,ennemy_are_embushed,heroes_are_embushed)

func startpeeking():
	peek_scene.door = self
	peek_scene.set_encounter(encounter_for_this_door)
	

func stop_peekink():
	peeking = false

func check_detection() -> void:
	# On lance une boucle tant que peek est vrai
	ennemy_are_embushed = true
	
	await get_tree().create_timer(1.0).timeout
	
	if peeking:
		var rand = randi_range(1, 100)
		print("Jet de détection :", rand)
		if rand > 60:
			print("Tu es repéré ! Combat déclenché.")
			peeking = false 
			heroes_are_embushed = true
			ennemy_are_embushed = false
			_start_combat()
			# on stoppe la boucle si le combat démarre
			return
		check_detection()

func _start_combat():
	embuscadeUI.texture = encounter_for_this_door.imageEmbuscade
	embuscadeUI.visible = true
	await get_tree().create_timer(1.0).timeout
	call_deferred("_advance_in_room")
func _on_left_pressed():
	if connected_ids.is_empty():
		return
	current_index = (current_index - 1 + connected_ids.size()) % connected_ids.size()
	_go_to_connected_room(current_index)


func _on_right_pressed():
	if connected_ids.is_empty():
		return
	current_index = (current_index + 1) % connected_ids.size()
	_go_to_connected_room(current_index)


func _go_to_connected_room(index: int):
	if not Game_Manager:
		return
	if index < 0 or index >= connected_ids.size():
		push_error("Index de room invalide : %d" % index)
		return

	var target_id = connected_ids[index]
	var next_room = Game_Manager.get_room_by_id(target_id)
	if not next_room:
		push_error("Impossible de trouver la room pour ID : %s" % target_id)
		return

	print("🚪 Door → Passage à la room suivante :", next_room.room_id)
	Game_Manager.enter_room(next_room, true)
	
