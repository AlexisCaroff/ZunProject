extends Node
@onready var Doortext : TextureRect= $DoorText
var big_size = Vector2(1.2, 1.2)
var startsize = Vector2(1.0,1.0)
var current_tween: Tween = null
var Game_Manager:GameManager
var timePeeking : float = 0.0
var peeking: bool = true
@onready var sub_viewport : Viewport= $"../SubViewportContainer/SubViewport"
var encounter_for_this_door: CombatEncounter
@onready var embuscadeUI: TextureRect = $"../EmbuscadeUI"
func _ready():
	Game_Manager = get_tree().root.get_node("GameManager") 
	if Game_Manager:
		print ("Find Game manager")
	var peek_scene = load("res://UI/peekScene.tscn").instantiate()
	sub_viewport.add_child(peek_scene)
	
	print("next room ready")
	#print(GameManager.current_room_Ressource.resource_name)
	encounter_for_this_door= Game_Manager.current_room_Ressource.encounter
	peek_scene.set_encounter(encounter_for_this_door)

		
	
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
	GameState.current_phase = GameStat.GamePhase.COMBAT
	
	call_deferred("_advance_in_room")

func _advance_in_room():
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
	Game_Manager._enter_scene_in_current_room(scene_to_load)

func startpeeking():
	check_detection()

func stop_peekink():
	peeking = false

func check_detection() -> void:
	# On lance une boucle tant que peek est vrai
	await get_tree().create_timer(1.0).timeout
	
	if peeking:
		var rand = randi_range(1, 100)
		print("Jet de détection :", rand)
		if rand > 99:
			print("Tu es repéré ! Combat déclenché.")
			_start_combat()
			peeking = false # on stoppe la boucle si le combat démarre
			return
		check_detection()

func _start_combat():
	embuscadeUI.texture = encounter_for_this_door.imageEmbuscade
	embuscadeUI.visible = true
	await get_tree().create_timer(1.0).timeout
	_advance_in_room()
	
