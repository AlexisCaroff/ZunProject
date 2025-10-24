extends Sprite2D
@onready var  explomanage = $"../ExplorationManager"
var big_size = Vector2(1.5, 1.5)
var startsize = Vector2(1.0,1.0)
var current_tween: Tween = null
@export var amount:int = 30
@onready var  etiquette = $etiquette
@onready var dialogue_manager := $"../DialogueManager"
@export var dialoguePass :String

func _ready():
	
	# Charger un fichier de dialogue
	dialogue_manager.load_dialogue(dialoguePass)
	dialogue_manager.text_choice1 = "Use Kairn "
	dialogue_manager.text_choice2 = "Destroy Kairn "
	
func _on_button_button_down() -> void:
	dialogue_manager.start_dialogue()
	etiquette.visible=false
	
func use_cairn():
	var target :CharaExplo = explomanage.characters[randi() % explomanage.characters.size()]
	target.current_stamina = min(target.max_stamina, target.current_stamina + amount)
	target.update_display()
	GameState.update_hero_stat(target.Charaname, "stamina", target.current_stamina)

func destroy_cairn():
	for target in explomanage.characters:
		target.current_stress = max(0, target.current_stress - amount)
		target.update_display()
		GameState.update_hero_stat(target.Charaname, "stress", target.current_stress)
	self.visible=false

func _on_button_mouse_entered() -> void:
	etiquette .scale = startsize 	

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


func _on_Choice1_button_down() -> void:
	use_cairn()



func _on_Choice2_button_down() -> void:
	destroy_cairn()
