extends Node2D
class_name ExplorationManager


@export var chara_explo_scene : PackedScene
@onready var Doortext = $Button/Doortext
@onready var slots : Array[ExplorationPosition] = []
var characters: Array[Node] = []
var big_size = Vector2(1.1, 1.1)
var startsize = Vector2(1.0, 1.0)
var current_tween: Tween = null
var selected_character: CharaExplo = null
var over_chara: CharaExplo
var move_mode: bool = false
@onready var viewport: Viewport = $"../SubViewportContainer/SubViewport"
@onready var donjon_map: Map = $"../SubViewportContainer/SubViewport/map"
@onready var portraits = $"../Portraits".get_children()
@onready var portrait_selector =$"../Portraits/ExploCharaselector"
var DoorNumber:int =0
var gm : GameManager
var campButton: Button
@onready var menuPerso = $"../MenuPerso"
@onready var bouton_menuPerso=$"../charaPortrait2/charaPortraitButton"

const SELECTOR_TEX = preload("res://UI/selectorCombatChara.png")
var selectorChara : Sprite2D

func _ready():
	for child in $"../HeroPosition".get_children():
		if child is ExplorationPosition:
			slots.append(child)
			
	gm = get_tree().root.get_node("GameManager") as GameManager
	if gm.current_room_Ressource.CanCamp:
		campButton=$Campement
		if gm.current_room_Ressource.CampDone:
			campButton.disabled=true
	menuPerso.characters=gm.characters
	load_characters_from_gamestat()
	selected_character = characters[0]
	
	portrait_selector.position = portraits[0].position
	bouton_menuPerso.connect("button_down", showMenuPerso)
	
	if donjon_map== null:
		donjon_map=$"../SubViewportContainer/SubViewport/map"
	donjon_map.focus_on_room(gm.current_room_Ressource,viewport)
		#donjon_map.move_to_position(donjon_map.curentposition)
	create_selector_sprite()
	selectorChara.position= selected_character.CharaPosition.charaUI.global_position if selected_character.CharaPosition else Vector2.ZERO

func load_characters_from_gamestat():
	characters.clear()
	
	for i in gm.characters.size():
		var hero_data = gm.characters[i]
		var chara = chara_explo_scene.instantiate()
		chara.characterData = hero_data
		add_child(chara)
		chara.load_chara()
		characters.append(chara)
		
		# Placement dans le slot correspondant
		var slot_index = hero_data.Chara_position
		move_character_to_slot(chara, slots[slot_index])
		
		portraits[slot_index].set_occupant(chara)
		

## --- Nouvelle logique pour passer à la prochaine room ---
func go_to_next_room():
	
	if not gm:
		push_error("ExplorationManager: GameManager introuvable dans la scène !")
		return

	if not gm.current_room_Ressource:
		push_error("ExplorationManager: aucune room courante !")
		return

	# Récupère la liste d'IDs des rooms connectées
	var connected_ids: Array = gm.current_room_Ressource.connected_room_ids
	if connected_ids == null or connected_ids.is_empty():
		push_warning("ExplorationManager: aucune salle connectée depuis " + str(gm.current_room_Ressource.room_id))
		return

	# Vérifie DoorNumber
	if DoorNumber < 0 or DoorNumber >= connected_ids.size():
		push_error("ExplorationManager: DoorNumber invalide (%d)" % DoorNumber)
		return

	# Récupère l'ID de la room cible et résoud la ressource via le GameManager
	var next_room_id: String = connected_ids[DoorNumber]
	var next_room: RoomResource = gm.get_room_by_id(next_room_id)
	if next_room == null:
		push_error("ExplorationManager: impossible de trouver la room pour ID '%s'" % next_room_id)
		return

	print("ExplorationManager → Passage à la room suivante :", next_room.room_id)
	gm.enter_room(next_room)

func move_character_to_slot(chara: CharaExplo, slot: ExplorationPosition):
	
	slot.set_occupant(chara) 
	

func _swap_characters(chara1: CharaExplo, chara2: CharaExplo) -> void:
	var slot1 = chara1.characterData.Chara_position
	var slot2 = chara2.characterData.Chara_position
	var portrait1= chara1.exploPortrait
	var portrait2= chara2.exploPortrait

	move_character_to_slot(chara1, slots[slot2])
	chara1.characterData.Chara_position = slot2
	chara1.move()
	portrait2.set_occupant(chara1)
	
	move_character_to_slot(chara2, slots[slot1])
	chara2.characterData.Chara_position = slot1
	chara2.move()
	portrait1.set_occupant(chara2)
	move_mode = false
	selectorChara.position= selected_character.CharaPosition.charaUI.global_position if selected_character.CharaPosition else Vector2.ZERO

func selectCharacter(chara: CharaExplo):
	chara.animate_selected()
	if !move_mode:
		selected_character = chara
		var i = characters.find(chara)
		portrait_selector.position = portraits[i].position
		selectorChara.position= selected_character.CharaPosition.charaUI.global_position if selected_character.CharaPosition else Vector2.ZERO

		
		

## --- Le bouton appelle maintenant go_to_next_room ---
func _on_button_button_down() -> void:
	DoorNumber = 0
	call_deferred("go_to_next_room")

func _on_button_mouse_entered() -> void:
	Doortext.scale = startsize 	
	Doortext.set_pivot_offset(Doortext.size / 2)

	if current_tween:
		current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(Doortext , "scale", big_size, 0.2)

func _on_button_mouse_exited() -> void:
	Doortext.scale = big_size	
	Doortext.set_pivot_offset(Doortext.size / 2)
	if current_tween:
		current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(Doortext, "scale", startsize, 0.2)

func _on_move_button_button_down() -> void:
	move_mode = true
	selected_character.want_to_move()
	_swap_characters(over_chara, selected_character)
	print("move mode")


func _on_button_2_button_down() -> void:
	DoorNumber = 1
	call_deferred("go_to_next_room")


func _on_campement_button_down() -> void:
	gm.current_room_Ressource.CampDone=true
	gm.go_to_campement()
	
func sortie_du_camp():
	for chara in characters:
		chara.current_stamina = min(chara.max_stamina, chara.current_stamina + 10)
		chara.animate_heal(10, chara)
		chara.update_display()
		
func showMenuPerso():
	menuPerso.visible = true

func create_selector_sprite():
	var sprite := Sprite2D.new()
	sprite.texture = SELECTOR_TEX
	add_child(sprite)
	selectorChara=sprite
	selectorChara.scale= Vector2(0.9,1.1)
	selectorChara.offset.y =-4.0
	selectorChara.z_index = 3
