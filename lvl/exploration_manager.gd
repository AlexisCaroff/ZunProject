extends Node2D
class_name ExplorationManager

@onready var portraitCharaselect = $"../charaPortrait"
@export var chara_explo_scene : PackedScene
@onready var Doortext = $Button/Doortext
@onready var slots = $"../HeroPosition".get_children() # conteneur des ExploPositionSlot
var characters: Array[Node] = []
var big_size = Vector2(1.1, 1.1)
var startsize = Vector2(1.0, 1.0)
var current_tween: Tween = null
var selected_character: CharaExplo = null
var move_mode: bool = false
@onready var viewport: Viewport = $"../SubViewportContainer/SubViewport"
@onready var donjon_map: Map = $"../SubViewportContainer/SubViewport/map"
var DoorNumber:int =0
var gm : GameManager
func _ready():
	
	gm = get_tree().root.get_node("GameManager") as GameManager
	load_characters_from_gamestat()
	selected_character = characters[0]
	portraitCharaselect.texture = characters[0].initiative_icon
	donjon_map.curentposition = donjon_map.positions[gm.current_room_Ressource.position_on_map]
	if donjon_map:
		focus_on_room(donjon_map.curentposition)
		donjon_map.move_to_position(donjon_map.curentposition)

func focus_on_room(room: Node2D):
	var target_pos = room.position
	var tween = create_tween()
	tween.tween_property(donjon_map.camera, "position", target_pos, 0.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func load_characters_from_gamestat():
	characters.clear()
	print("try to load characters, saved character are "+ str(GameState.saved_heroes_data.size()))
	for i in GameState.saved_heroes_data.size():
		var hero_data = GameState.saved_heroes_data[i]
		var chara = chara_explo_scene.instantiate()
		chara.load_from_dict(hero_data)
		add_child(chara)
		characters.append(chara)

		# Placement dans le slot correspondant
		var slot_index = clamp(hero_data.get("Chara_position", i), 0, slots.size() - 1)
		move_character_to_slot(chara, slots[slot_index])
		slots[slot_index].occupant = chara

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

func move_character_to_slot(chara: Node, slot: Node):
	if chara.get_parent():
		chara.get_parent().remove_child(chara)
	slot.add_child(chara)
	chara.global_position = slot.global_position
	GameState.update_hero_stat(chara.Charaname, "position", chara.current_position)

func _swap_characters(chara1: Node, chara2: Node) -> void:
	var slot1 = chara1.current_position
	var slot2 = chara2.current_position

	move_character_to_slot(chara1, slots[slot2])
	chara1.current_position = slot2
	move_character_to_slot(chara2, slots[slot1])
	chara2.current_position = slot1
	move_mode = false

func selectCharacter(chara: CharaExplo):
	if !move_mode:
		selected_character = chara
		portraitCharaselect.texture = chara.initiative_icon
	else:
		_swap_characters(chara, selected_character)

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
	print("move mode")


func _on_button_2_button_down() -> void:
	DoorNumber = 1
	call_deferred("go_to_next_room")


func _on_campement_button_down() -> void:
	gm.go_to_campement()
