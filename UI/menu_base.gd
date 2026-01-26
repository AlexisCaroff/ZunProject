extends Control
class_name StartMenu
@onready var button_start: Button = $CanvasLayer/background2/VBoxContainer/ButtonStart
@onready var button_option: Button = $CanvasLayer/background2/VBoxContainer/Buttonoption
@onready var button_gallerie: Button = $CanvasLayer/background2/VBoxContainer/ButtonGallerie
@onready var button_glossaire: Button = $CanvasLayer/background2/VBoxContainer/ButtonGlossaire
@onready var button_didacticiel: Button =$CanvasLayer/background2/VBoxContainer/ButtonDitactitiel
@onready var button_quit: Button = $CanvasLayer/background2/VBoxContainer/Button2Quit
@onready var game_manager: GameManager = get_parent() as GameManager

func _ready():
	button_start.pressed.connect(_on_start_pressed)
	button_option.pressed.connect(_on_option_pressed)
	button_gallerie.pressed.connect(_on_gallerie_pressed)
	button_glossaire.pressed.connect(_on_glossaire_pressed)
	button_didacticiel.pressed.connect(_on_didacticiel_pressed)
	button_quit.pressed.connect(_on_quit_pressed)
	
func _on_start_pressed():
	
	if game_manager:
		game_manager.start_game()
	# get_tree().change_scene_to_file("res://Scenes/Game.tscn")


func _on_option_pressed():
	print("Options")
	# open_options_menu()


func _on_gallerie_pressed():
	print("Gallerie")


func _on_glossaire_pressed():
	print("Glossaire")


func _on_didacticiel_pressed():
	print("Didacticiel")


func _on_quit_pressed():
	get_tree().quit()
