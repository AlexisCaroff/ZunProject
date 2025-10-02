extends  Node2D

@onready var dialogue_manager := $DialogueManager
@export var dialogPass :String 


func _ready():

	# Charger un fichier de dialogue
	dialogue_manager.load_dialogue(dialogPass)

	# Lancer le dialogue
	dialogue_manager.start_dialogue()
