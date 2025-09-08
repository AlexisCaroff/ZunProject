extends Node

class_name DialogueManager

signal dialogue_finished

var dialogue_lines: Array = []
var current_index: int = 0
@export var portraits: Dictionary = {} # assigne dans l’inspecteur : { "Hero": Texture2D, "Guide": Texture2D }


@onready var ui := $DialogueUI

func _ready():
	ui.visible = false

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
		return
	ui.visible = true
	show_line()

func show_line():
	if current_index >= dialogue_lines.size():
		ui.visible = false
		emit_signal("dialogue_finished")
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
	
