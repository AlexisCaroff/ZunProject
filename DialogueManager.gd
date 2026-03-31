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

# Speakers sans portrait — n'occupent pas de slot visuel (ex: "Narrator")
@export var no_portrait_speakers: Array[String] = ["Narrator"]

# Alias de portrait : même slot, texture différente selon le contexte
# ex: {"Hooded figure": "Inquisitor", "Inquisitor.": "Inquisitor"}
@export var portrait_aliases: Dictionary = {}

# Slots qui n'apparaissent PAS dans le layout initial — ils entrent dynamiquement
# quand leur speaker parle pour la première fois.
# ex: ["Inquisitor"] → le slot Inquisitor est absent au début, apparaît à la 1re réplique
@export var late_entry_slots: Array[String] = []

# Détectés automatiquement à la lecture du fichier — ne pas remplir manuellement
var participants: Array[String] = []

# Portrait actuellement verrouillé par slot : { "Inquisitor": "Inquisitor" }
# Une fois le portrait canonique affiché, il ne repasse plus sur un alias.
var _slot_current_portrait: Dictionary = {}


func _ready():
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
	_slot_current_portrait.clear()

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Impossible de lire " + file_path)
		return

	var seen_slots: Array[String] = []   # noms de slots (après résolution des alias)

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line == "":
			continue
		var parts = line.split(":", false, 2)
		if parts.size() == 2:
			var speaker = parts[0].strip_edges()
			var text    = parts[1].strip_edges()
			dialogue_lines.append({"speaker": speaker, "text": text})

			# Ignore les speakers sans portrait
			if speaker in no_portrait_speakers:
				continue

			# Résout l'alias → nom de slot
			var slot_name := _resolve_slot(speaker)

			if slot_name not in seen_slots:
				seen_slots.append(slot_name)
				# Initialise le portrait du slot avec le premier speaker qui l'utilise.
				_slot_current_portrait[slot_name] = speaker
	file.close()

	# On garde au maximum 4 slots, en excluant les late_entry_slots du layout initial
	for i in range(min(seen_slots.size(), 4)):
		var slot := seen_slots[i]
		if slot not in late_entry_slots:
			participants.append(slot)

	ui.setup_layout(participants.size())
	print("Participants (slots):", participants)


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

	# ── Cas Narrator (pas de portrait) ──────────────────────────────
	if speaker in no_portrait_speakers:
		# Tous les portraits en inactif, nom du speaker quand même affiché
		_dim_all_portraits()
		ui.set_text(speaker, text)
		return

	# ── Résolution slot + portrait ────────────────────────────────────
	var slot_name     := _resolve_slot(speaker)

	# ── Entrée dynamique (late_entry_slots) ───────────────────────────
	# Si le slot n'est pas encore dans participants, on l'ajoute et on reconfigure le layout
	if slot_name not in participants:
		if participants.size() < 4:
			participants.append(slot_name)
			ui.setup_layout(participants.size())

	var speaker_index := participants.find(slot_name)

	# ── Mise à jour du portrait du slot ──────────────────────────────
	# Verrouillage : une fois que le speaker canonique (slot_name == speaker) a parlé,
	# le portrait ne change plus.
	var already_locked: bool = _slot_current_portrait.get(slot_name, "") == slot_name
	if not already_locked:
		_slot_current_portrait[slot_name] = speaker

	# Construit le tableau de textures en utilisant le portrait verrouillé de chaque slot
	var textures: Array[Texture2D] = []
	for p in participants:
		var portrait_name: String = _slot_current_portrait.get(p, p)
		var tex: Texture2D = null
		if portraits_resource:
			if portraits_resource.portraits.has(portrait_name):
				tex = portraits_resource.portraits[portrait_name]
			elif portraits_resource.portraits.has(p):
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


# ─────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────

## Retourne le nom de slot d'un speaker (résout les alias)
func _resolve_slot(speaker: String) -> String:
	if portrait_aliases.has(speaker):
		return portrait_aliases[speaker]
	return speaker


## Met tous les portraits en inactif (pour le Narrator)
func _dim_all_portraits() -> void:
	var dummy_textures: Array[Texture2D] = []
	for p in participants:
		var portrait_name: String = _slot_current_portrait.get(p, p)
		var tex: Texture2D = null
		if portraits_resource:
			if portraits_resource.portraits.has(portrait_name):
				tex = portraits_resource.portraits[portrait_name]
			elif portraits_resource.portraits.has(p):
				tex = portraits_resource.portraits[p]
		dummy_textures.append(tex)
	# speaker_index = -1 → aucun portrait actif dans set_portraits_multi
	ui.set_portraits_multi(dummy_textures, -1)
