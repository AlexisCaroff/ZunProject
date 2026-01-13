extends Resource
class_name HistoryScene

@export var illustration: Texture2D
@export_file("*.txt") var dialogue_file : String
@export var title: String = ""
@export var participants: Array[String] = [] # ["Hero", "Guide"]

@export var is_choice: bool = false
@export var choice_1_text: String
@export var choice_2_text: String
