extends Sprite2D
class_name Interactable
@onready var  explomanage = $"../ExplorationManager"
@export  var big_size = Vector2(0.8, 0.8)
@export  var startsize = Vector2(0.6,0.6)
var current_tween: Tween = null
@export var amount:int = 30
@onready var  etiquette = $etiquette
@onready var dialogue_manager := $"../DialogueManager"
@export var dialoguePass :String
@onready var button: Button =$Button

func _ready():
	button =$Button
	button.connect("button_down", _on_button_button_down)
	# Charger un fichier de dialogue
	dialogue_manager.load_dialogue(dialoguePass)
	dialogue_manager.text_choice1 = "Use Kairn "
	dialogue_manager.text_choice2 = "Destroy Kairn "
	
func _on_button_button_down() -> void:
	dialogue_manager.start_dialogue()
	etiquette.visible=false
	
func use_cairn():
	var target :CharaExplo = explomanage.characters[randi() % explomanage.characters.size()]
	target.characterData.current_stamina = min(target.characterData.max_stamina, target.characterData.current_stamina + amount)
	target.update_display()
	
func destroy_cairn():
	for target in explomanage.characters:
		target.characterData.current_stress = max(0, target.characterData.current_stress - amount)
		target.update_display()
		
	self.visible=false 

func _on_button_mouse_entered() -> void:
	etiquette .scale = startsize 	
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

func _on_Choice1_button_down() -> void:
	use_cairn()



func _on_Choice2_button_down() -> void:
	destroy_cairn()
