extends Node2D
class_name ExplorationManager
@onready var portraitCharaselect = $"../charaPortrait"
@export var chara_explo_scene : PackedScene
@onready var Doortext=  $Button/Doortext
@export var door_scene : PackedScene
@onready var slots = $"../HeroPosition".get_children() # conteneur des ExploPositionSlot
var characters: Array[Node] = []
var big_size = Vector2(1.1, 1.1)
var startsize = Vector2(1.0,1.0)
var current_tween: Tween = null
var selected_character: CharaExplo = null
var move_mode: bool = false

func _ready():
	load_characters_from_gamestat()
	selected_character = characters[0]
	portraitCharaselect.texture= characters[0].initiative_icon


func load_characters_from_gamestat():
	characters.clear()
	for i in GameState.saved_heroes_data.size():
		var hero_data = GameState.saved_heroes_data[i]
		var chara = chara_explo_scene.instantiate()
		chara.load_from_dict(hero_data)
		add_child(chara)
		characters.append(chara)

		# Placement dans le slot correspondant
		var slot_index = clamp(hero_data.get("Chara_position", i), 0, slots.size() - 1)
		move_character_to_slot(chara, slots[slot_index])
		slots[slot_index].occupant=chara







func change_to_exploration_scene():
	if get_tree():
		get_tree().change_scene_to_packed(door_scene)
	else:
		print("Erreur : get_tree() est null.")

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
	move_mode=false

	#print("Échange entre ", chara1.Charaname, " et ", chara2.Charaname)

func selectCharacter(chara: CharaExplo):
	if !move_mode:
		selected_character=chara
		
		portraitCharaselect.texture = chara.initiative_icon
	else:
		
		_swap_characters(chara,selected_character)
		

func _on_button_button_down() -> void:
	call_deferred("change_to_exploration_scene")


func _on_button_mouse_entered() -> void:
	Doortext.scale = startsize 	
	Doortext.set_pivot_offset(Doortext.size / 2)


	if current_tween:
		current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(Doortext , "scale", big_size, 0.2)
	



func _on_button_mouse_exited() -> void:
	Doortext.scale = big_size	
	Doortext.set_pivot_offset(Doortext.size/ 2)
	if current_tween:
		current_tween.kill()

	current_tween = create_tween()
	current_tween.tween_property(Doortext, "scale", startsize, 0.2)


func _on_move_button_button_down() -> void:
	move_mode = true
	print("move mode")
