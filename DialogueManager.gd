extends Node

class_name DialogueManager

signal dialogue_finished

var dialogue_lines: Array = []
var current_index: int = 0
@export var portraits: Dictionary = {} # assigne dans l’inspecteur : { "Hero": Texture2D, "Guide": Texture2D }
var choix 
@export var is_Choice :bool = false
@onready var ui := $DialogueUI

func _ready():
	ui.visible = false
	if is_Choice:
		choix=$Choix
		choix.visible=false
		print (choix)

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		next_line()
		
func load_dialogue(file_path: String):
	dialogue_lines.clear()
	current_index = 0

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Impossible de lire " + file_path)
		return

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line == "":
			continue
		var parts = line.split(":", false, 2)
		if parts.size() == 2:
			dialogue_lines.append({
				"speaker": parts[0].strip_edges(),
				"text": parts[1].strip_edges()
			})
	file.close()

func start_dialogue():
	if dialogue_lines.is_empty():
		emit_signal("dialogue_finished")
		if is_Choice:
			choix.visible=true 
			print ("dialog end, show choices")
		return
	ui.visible = true
	show_line()

func show_line():
	if current_index >= dialogue_lines.size():
		ui.visible = false
		emit_signal("dialogue_finished")
		if is_Choice:
			choix.visible=true 
			print ("dialog end, show choices")
		return

	var line = dialogue_lines[current_index]
	var speaker = line["speaker"]
	var text = line["text"]

	# Mettre à jour l'UI
	if portraits.has(speaker):
		ui.set_portrait(portraits[speaker])
	else:
		ui.set_portrait(null)

	ui.set_text(speaker, text)

func next_line():
	current_index += 1
	show_line()
	
func hideChoix():
	choix.visible=false


func _on_use_button_down() -> void:
	hideChoix()


func _on_destroy_button_down() -> void:
	hideChoix()
