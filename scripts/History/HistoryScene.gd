extends Resource
class_name HistoryScene

@export var illustration: Texture2D
## Illustration étirée sur toute la largeur de l'écran, collée en haut, à
## ses proportions ; le noir du fond comble ce qu'elle ne couvre pas. Pour
## les décors de salle (BG_dungeon_*), plus petits que les illustrations.
@export var fill_width: bool = false
## Pas d'illustration ni de fond noir : la scène en cours (le combat) reste
## visible derrière le dialogue.
@export var show_scene_behind: bool = false
@export_file("*.txt") var dialogue_file : String
@export var title: String = ""
@export var participants: Array[String] = [] # ["Hero", "Guide"]

@export var is_choice: bool = false
@export var choice_1_text: String
@export var choice_2_text: String
