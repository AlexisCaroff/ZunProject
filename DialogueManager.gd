extends Node
class_name DialogueManager

signal dialogue_finished
signal dialogue_choice_requested
signal choice_made(choice_index: int)

var dialogue_lines: Array = []
var current_index: int = 0
@export var portraits_resource: PortraitsResource
var choix: Control
@export var is_Choice: bool = false
@export var text_choice1: String
@export var text_choice2: String
@export var external_choice_receiver: Node = null
var dialogue_started: bool = false
var ui: Node = null
var scene: PackedScene = preload("res://UI/dialogue_ui.tscn")

# Détectés automatiquement à la lecture du fichier — ne pas remplir manuellement
var participants: Array[String] = []


func _ready():
	self.global_position = Vector2(0, 0)
	if ui == null:
		ui = scene.instantiate()
		add_child(ui)
	else:
		ui = $DialogueUI
	ui.visible = false

	if is_Choice:
		if choix == null:
			var choix_scene: PackedScene = preload("res://UI/Choix.tscn")
			choix = choix_scene.instantiate()
			add_child(choix)
			choix.Choice1.pressed.connect(_on_Choice1_button_down)
			choix.Choice2.pressed.connect(_on_Choice2_button_down)
		else:
			choix = $Choix
			choix.Choice1.text = text_choice1
			choix.Choice2.text = text_choice2
		choix.visible = false
		if external_choice_receiver:
			if external_choice_receiver.has_method("_on_Choice1_button_down"):
				choix.Choice1.pressed.connect(external_choice_receiver._on_Choice1_button_down)
			if external_choice_receiver.has_method("_on_Choice2_button_down"):
				choix.Choice2.pressed.connect(external_choice_receiver._on_Choice2_button_down)


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed and dialogue_started:
		next_line()


func load_dialogue(file_path: String):
	dialogue_lines.clear()
	current_index = 0
	participants.clear()

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Impossible de lire " + file_path)
		return

	# Première passe : collecte des lignes et détection des personnages (ordre d'apparition)
	var seen_speakers: Array[String] = []
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line == "":
			continue
		var parts = line.split(":", false, 2)
		if parts.size() == 2:
			var speaker = parts[0].strip_edges()
			var text    = parts[1].strip_edges()
			dialogue_lines.append({"speaker": speaker, "text": text})
			if speaker not in seen_speakers:
				seen_speakers.append(speaker)
	file.close()

	# On garde au maximum 4 personnages (ordre d'apparition)
	for i in range(min(seen_speakers.size(), 4)):
		participants.append(seen_speakers[i])

	# Informe l'UI du nombre de participants pour qu'elle ajuste la mise en page
	ui.setup_layout(participants.size())
	print("Participants:", participants)
	

func start_dialogue():
	dialogue_started = true
	if dialogue_lines.is_empty():
		emit_signal("dialogue_finished")
		if is_Choice and choix:
			choix.Choice1.text = text_choice1
			choix.Choice2.text = text_choice2
			choix.visible = true
			dialogue_started = false
		return
	ui.visible = true
	show_line()


func show_line():
	if current_index >= dialogue_lines.size():
		ui.visible = false
		if is_Choice and choix:
			choix.Choice1.text = text_choice1
			choix.Choice2.text = text_choice2
			choix.visible = true
			dialogue_started = false
			emit_signal("dialogue_choice_requested")
		else:
			emit_signal("dialogue_finished")
		return

	var line    = dialogue_lines[current_index]
	var speaker = line["speaker"]
	var text    = line["text"]

	# Calcule l'index du locuteur dans la liste des participants (0–3)
	var speaker_index: int = participants.find(speaker)

	# Récupère les textures dans l'ordre des participants
	var textures: Array[Texture2D] = []
	for p in participants:
		var tex: Texture2D = null
		if portraits_resource and portraits_resource.portraits.has(p):
			tex = portraits_resource.portraits[p]
		textures.append(tex)

	ui.set_portraits_multi(textures, speaker_index)
	ui.set_text(speaker, text)


func next_line():
	current_index += 1
	show_line()


func hideChoix():
	if choix:
		choix.visible = false


func _on_Choice1_button_down() -> void:
	hideChoix()
	emit_signal("choice_made", 0)

func _on_Choice2_button_down() -> void:
	hideChoix()
	emit_signal("choice_made", 1)
