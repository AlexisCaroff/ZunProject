extends Node
class_name DialogueManager

signal dialogue_finished

var dialogue_lines: Array = []
var current_index: int = 0
@export var portraits_resource:  PortraitsResource # { "Hero": Texture2D, "Guide": Texture2D }
var choix: Control
@export var is_Choice : bool = false

var ui: Node =null

func _ready():
	# Crée automatiquement l'UI si elle n'existe pas déjà
	if ui==null:
		var scene: PackedScene = preload("res://UI/dialogue_ui.tscn") # à adapter à ton projet
		ui = scene.instantiate()
		add_child(ui)
	else:
		ui = $DialogueUI

	ui.visible = false

	# Gestion des choix
	if is_Choice:
		if choix==null:
			var choix_scene: PackedScene = preload("res://UI/Choix.tscn") # idem à adapter
			choix = choix_scene.instantiate()
			add_child(choix)
		else:
			choix = $Choix
		choix.visible = false



func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
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
		if is_Choice and choix:
			choix.visible = true
		return

	ui.visible = true
	show_line()


func show_line():
	if current_index >= dialogue_lines.size():
		ui.visible = false
		emit_signal("dialogue_finished")
		if is_Choice and choix:
			choix.visible = true
		return

	var line = dialogue_lines[current_index]
	var speaker = line["speaker"]
	var text = line["text"]

	if portraits_resource and portraits_resource.portraits.has(speaker):
		ui.set_portrait(portraits_resource.portraits[speaker])
	else:
		ui.set_portrait(null)

	ui.set_text(speaker, text)



func next_line():
	current_index += 1
	show_line()


func hideChoix():
	if choix:
		choix.visible = false


func _on_use_button_down() -> void:
	hideChoix()

func _on_destroy_button_down() -> void:
	hideChoix()
