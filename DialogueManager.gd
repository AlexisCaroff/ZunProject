extends Node
class_name DialogueManager

signal dialogue_finished

var dialogue_lines: Array = []
var current_index: int = 0
@export var portraits_resource:  PortraitsResource # { "Hero": Texture2D, "Guide": Texture2D }
var choix: Control
@export var is_Choice : bool = false
@export var text_choice1 : String
@export var text_choice2 : String
@export var external_choice_receiver: Node = null
var dialogue_started : bool = false
var ui: Node =null
var scene: PackedScene = preload("res://UI/dialogue_ui.tscn")
func _ready():
	
	if ui==null:
		
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
			
			choix.Choice1.pressed.connect(_on_Choice1_button_down)
			choix.Choice2.pressed.connect(_on_Choice2_button_down)
		else:
			choix = $Choix
			choix.Choice1.text=text_choice1
			choix.Choice2.text=text_choice2
		choix.visible = false
		if external_choice_receiver:
			if external_choice_receiver.has_method("_on_Choice1_button_down"):
				choix.Choice1.pressed.connect(external_choice_receiver._on_Choice1_button_down)
			if external_choice_receiver.has_method("_on_Choice2_button_down"):
				choix.Choice2.pressed.connect(external_choice_receiver._on_Choice2_button_down)



func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and dialogue_started:
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
	dialogue_started=true
	#$"../Kairn/Button".disabled=true
	if dialogue_lines.is_empty():
		emit_signal("dialogue_finished")
		if is_Choice and choix:
			choix.Choice1.text=text_choice1
			choix.Choice2.text=text_choice2
			choix.visible = true
			dialogue_started=false
		return

	ui.visible = true
	show_line()


func show_line():
	if current_index >= dialogue_lines.size():
		ui.visible = false
		emit_signal("dialogue_finished")
		if is_Choice and choix:
			choix.Choice1.text=text_choice1
			choix.Choice2.text=text_choice2
			choix.visible = true
			dialogue_started=false
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


func _on_Choice1_button_down() -> void:
	hideChoix()

func _on_Choice2_button_down() -> void:
	hideChoix()
