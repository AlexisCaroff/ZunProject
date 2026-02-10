# InteractableObject.gd
extends Node2D
class_name InteractableObject

@export var data: InteractableObjectResource

@onready var button: Button = $Button
@onready var dialogue_manager: DialogueManager =$DialogueManager
@onready var  etiquette = $etiquette
@export  var big_size = Vector2(0.8, 0.8)
@export  var startsize = Vector2(0.6,0.6)
var current_tween: Tween = null
func _ready():
	button.connect("button_down",start_interaction)
	button.connect("mouse_entered",_on_button_mouse_entered)
	button.connect("mouse_exited",_on_button_mouse_exited)

func start_interaction():
	
	if dialogue_manager == null:
		push_error("DialogueManager introuvable")
		return

	# Sécurité : éviter double connexion
	if not dialogue_manager.choice_made.is_connected(_on_choice_made):
		dialogue_manager.choice_made.connect(_on_choice_made)
		
	dialogue_manager.is_Choice = true
	dialogue_manager.text_choice1 = data.choice_1.text
	dialogue_manager.text_choice2 = data.choice_2.text
	dialogue_manager.external_choice_receiver = self

	dialogue_manager.load_dialogue(data.dialogue_file)
	dialogue_manager.start_dialogue()
	
	
func _on_choice_made(choice_index: int):
	match choice_index:
		0:
			resolve_choice(data.choice_1)
		1:
			resolve_choice(data.choice_2)

func resolve_choice(choice: InteractableChoice):
	var gm: GameManager = get_tree().root.get_node("GameManager")
	var characters := gm.characters

	match choice.effect_type:
		InteractableChoice.EffectType.NONE:
			pass

		InteractableChoice.EffectType.ITEM:
			gm.add_to_inventory(choice.item)

		InteractableChoice.EffectType.BUFF:
			for chara in characters:
				chara.add_buff(choice.buff)

		InteractableChoice.EffectType.TAG:
			for chara in characters:
				if not chara.tags.has(choice.tag):
					chara.tags.append(choice.tag)

	queue_free() 
	
func _on_button_mouse_entered() -> void:
	etiquette.scale = startsize 	
	etiquette.visible=true
	if current_tween:
		current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(etiquette , "scale", big_size, 0.2)
	

func _on_button_mouse_exited() -> void:
	etiquette.scale = big_size	
	
	if current_tween:
		current_tween.kill()

	current_tween = create_tween()
	current_tween.tween_property(etiquette, "scale", startsize, 0.2)
	await current_tween.finished
	etiquette.visible=false
