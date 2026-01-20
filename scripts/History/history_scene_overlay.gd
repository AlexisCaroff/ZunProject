extends Control
class_name HistorySceneOverlay

@export var history_scene: HistoryScene

@onready var background: Sprite2D = $CanvasLayer/Background
@onready var dialogue_manager: DialogueManager =$CanvasLayer/DialogueManager
@onready var close_button: Button = $CanvasLayer/CloseButton
signal history_finished


func _ready():
	close_button.pressed.connect(close)

	if history_scene:
		setup_from_resource(history_scene)


func setup_from_resource(data: HistoryScene):
	# Background
	
	background.texture = data.illustration
	if dialogue_manager==null:
		dialogue_manager = $DialogueManager
	# Dialogue
	#dialogue_manager.participants = data.participants
	dialogue_manager.is_Choice = data.is_choice
	if data.choice_1_text:
		dialogue_manager.text_choice1 = data.choice_1_text
	if data.choice_2_text:
		dialogue_manager.text_choice2 = data.choice_2_text

	dialogue_manager.load_dialogue(data.dialogue_file)

	
	dialogue_manager.start_dialogue()

	dialogue_manager.dialogue_finished.connect(_on_dialogue_finished)
	
	dialogue_manager.dialogue_finished.connect(_on_no_choice)
	dialogue_manager.dialogue_choice_requested.connect(_on_choice_requested)
	dialogue_manager.choice_made.connect(_on_choice_made)

	dialogue_manager.start_dialogue()

func _on_dialogue_finished():
	if not dialogue_manager.is_Choice:
		close()
func _on_choice_requested():
	# L’overlay reste ouvert
	pass
	
func _on_choice_made(choice_index: int):
# ajouter fonction ici
	print("Choix sélectionné :", choice_index)

	close()
func _on_no_choice():
	close()
func close():
	emit_signal("history_finished")
	queue_free()
