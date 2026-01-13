extends Control
class_name HistorySceneOverlay

@export var history_scene: HistoryScene

@onready var background: Sprite2D = $Background
@onready var dialogue_manager: DialogueManager = $DialogueManager
@onready var close_button: Button = $CloseButton


func _ready():
	close_button.pressed.connect(close)

	if history_scene:
		setup_from_resource(history_scene)


func setup_from_resource(data: HistoryScene):
	# Background
	background.texture = data.background

	# Dialogue
	dialogue_manager.participants = data.participants
	dialogue_manager.is_Choice = data.is_choice
	dialogue_manager.text_choice1 = data.choice_1_text
	dialogue_manager.text_choice2 = data.choice_2_text

	dialogue_manager.load_dialogue(data.dialogue_file)
	dialogue_manager.start_dialogue()

	dialogue_manager.dialogue_finished.connect(_on_dialogue_finished)


func _on_dialogue_finished():

	pass


func close():
	queue_free()
