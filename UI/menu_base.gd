extends Control
class_name StartMenu
@onready var button_start: Button = $CanvasLayer/background2/VBoxContainer/ButtonStart
@onready var button_option: Button = $CanvasLayer/background2/VBoxContainer/Buttonoption
@onready var button_gallerie: Button = $CanvasLayer/background2/VBoxContainer/ButtonGallerie
@onready var button_glossaire: Button = $CanvasLayer/background2/VBoxContainer/ButtonGlossaire
@onready var button_didacticiel: Button =$CanvasLayer/background2/VBoxContainer/ButtonDitactitiel
@onready var button_quit: Button = $CanvasLayer/background2/VBoxContainer/Button2Quit
@onready var game_manager: GameManager = get_parent() as GameManager
@onready var options_panel: OptionsPanel = $CanvasLayer/OptionsPanel 


func _ready():
	options_panel.hide()
	
	button_start.pressed.connect(_on_start_pressed)
	button_start.animscale()
	button_option.pressed.connect(_on_option_pressed)
	button_gallerie.pressed.connect(_on_gallerie_pressed)
	button_glossaire.pressed.connect(_on_glossaire_pressed)
	button_didacticiel.pressed.connect(_on_didacticiel_pressed)
	button_quit.pressed.connect(_on_quit_pressed)
	
	AudioManager.register_tracks(
		[preload("res://Audio/Music/track_01.ogg"),
		 preload("res://Audio/Music/track_02.ogg"), 
		preload("res://Audio/Music/boss01.ogg"), 
		preload("res://Audio/Music/camp01.ogg"), 
		preload("res://Audio/Music/dungeon01.ogg")],
		
		["Thème 01", "Camp 02","Boss 01","Camp01","Dungeon 01"]
	)
	AudioManager.play()
	
func _on_start_pressed():
	
	if game_manager:
		game_manager.start_game()
	# get_tree().change_scene_to_file("res://Scenes/Game.tscn")


func _on_option_pressed():
	
	options_panel.refresh()
	options_panel.show()
	# open_options_menu()


func _on_gallerie_pressed():
	print("Gallerie")


func _on_glossaire_pressed():
	print("Glossaire")


func _on_didacticiel_pressed():
	print("Didacticiel")


func _on_quit_pressed():
	get_tree().quit()
