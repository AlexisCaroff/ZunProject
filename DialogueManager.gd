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

# ─────────────────────────────────────────────
#  Layout custom (optionnel)
# ─────────────────────────────────────────────
## Liste des slots du DialogueUI à afficher, dans l'ordre logique
## d'affectation. Vide → utilise le layout par défaut basé sur le nombre
## de participants (1→[0], 2→[0,3], 3→[0,1,2], 4→[0,1,2,3]).
##
## Exemple give_in : [0, 1, 3] = Portrait | Portrait3 | (vide) | Portrait2
@export var slot_layout: Array[int] = []

## Mapping speaker (slot name) → index logique dans participants/slot_layout.
## Vide → ordre d'apparition dans le fichier de dialogue.
## Quand renseigné, désactive late_entry_slots (le layout est fixé d'avance).
##
## Exemple give_in :
##   {"Inquisitor": 0, "Priestess": 1, "Broodmother": 2}
##   combiné à slot_layout = [0, 1, 3] →
##   Inquisitor en gauche, Priestess en centre-gauche, Broodmother en droite.
@export var slot_overrides: Dictionary = {}

# Détectés automatiquement à la lecture du fichier — ne pas remplir manuellement
var participants: Array[String] = []

# Mapping nœuds portrait selon le nombre de participants (gauche → droite)
const _LAYOUT_PORTRAIT_NAMES := {
	1: ["Portrait"],
	2: ["Portrait", "Portrait2"],
	3: ["Portrait", "Portrait3", "Portrait2"],
	4: ["Portrait", "Portrait3", "Portrait4", "Portrait2"]
}

# Slot index (0-3) → nom du nœud TextureRect dans DialogueUI.
# Utilisé pour _reposition_speaker quand slot_layout est défini.
const _SLOT_INDEX_TO_NODE_NAME := ["Portrait", "Portrait3", "Portrait4", "Portrait2"]

# Portrait actuellement verrouillé par slot : { "Inquisitor": "Inquisitor" }
# Une fois le portrait canonique affiché, il ne repasse plus sur un alias.
var _slot_current_portrait: Dictionary = {}

# Référence au GameManager pour récupérer les noms personnalisés des héros
var _gm: GameManager = null


func _ready():
	_gm = get_tree().root.get_node_or_null("GameManager") as GameManager
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
	if not event.is_pressed():
		return

	# Clic gauche ou Espace → ligne suivante
	if dialogue_started:
		if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) \
				or (event is InputEventKey and event.keycode == KEY_SPACE):
			next_line()

	# X → sauter tout le dialogue immédiatement
	if dialogue_started and event is InputEventKey and event.keycode == KEY_X:
		current_index = dialogue_lines.size()
		show_line()


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
		var raw := file.get_line()
		# Ligne vide → séparateur de réplique, on ne concatène pas
		if raw.strip_edges() == "":
			continue

		var parts = raw.split(":", false, 2)
		if parts.size() >= 2:
			# Ligne avec speaker → nouvelle réplique
			var speaker := parts[0].strip_edges()
			var text    := parts[1].strip_edges()
			dialogue_lines.append({"speaker": speaker, "text": text})

			# Ignore les speakers sans portrait
			if speaker in no_portrait_speakers:
				continue

			# Résout l'alias → nom de slot
			var slot_name := _resolve_slot(speaker)
			if slot_name not in seen_slots:
				seen_slots.append(slot_name)
				_slot_current_portrait[slot_name] = speaker

		else:
			# Ligne sans ":" → continuation de la réplique précédente
			if not dialogue_lines.is_empty():
				dialogue_lines[-1]["text"] += "\n" + raw.strip_edges()

	file.close()

	# ── Construction de participants ──
	if not slot_overrides.is_empty():
		# MODE OVERRIDE : ordre fixé par slot_overrides (speaker → index logique).
		# Late_entry_slots est ignoré ici (le layout est figé d'avance).
		var max_idx := -1
		for s in slot_overrides.keys():
			max_idx = max(max_idx, int(slot_overrides[s]))

		var ordered: Array[String] = []
		ordered.resize(max_idx + 1)
		for s: String in slot_overrides.keys():
			var idx := int(slot_overrides[s])
			if idx >= 0 and idx <= max_idx:
				ordered[idx] = s

		# Ne garde dans participants que les speakers qui apparaissent réellement
		# dans le fichier (sinon on aurait des slots vides au mauvais endroit).
		for s in ordered:
			if s != "" and s in seen_slots:
				participants.append(s)
				if not _slot_current_portrait.has(s):
					_slot_current_portrait[s] = s
	else:
		# MODE CLASSIQUE : ordre d'apparition, hors late_entry_slots.
		for i in range(min(seen_slots.size(), 4)):
			var slot := seen_slots[i]
			if slot not in late_entry_slots:
				participants.append(slot)

	# ── Layout ──
	if not slot_layout.is_empty():
		ui.setup_layout_explicit(slot_layout)
	else:
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
		ui.set_text(_resolve_display_name(speaker), text)
		return

	# ── Résolution slot + portrait ────────────────────────────────────
	var slot_name     := _resolve_slot(speaker)

	# ── Entrée dynamique (late_entry_slots) ───────────────────────────
	# Désactivée en mode override : le layout est fixé d'avance.
	if slot_name not in participants:
		if slot_overrides.is_empty() and participants.size() < 4:
			participants.append(slot_name)
			ui.setup_layout(participants.size())
		else:
			# Mode override : speaker absent de slot_overrides → fallback narrator
			push_warning("DialogueManager : speaker '%s' absent de slot_overrides → affiché en mode narrator." % speaker)
			_dim_all_portraits()
			ui.set_text(_resolve_display_name(speaker), text)
			return

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
	ui.set_text(_resolve_display_name(speaker), text)
	_reposition_speaker(speaker_index)


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

## Déplace le label Speaker pour le centrer sous le portrait actif.
## En mode slot_layout, on utilise directement l'index de slot ; sinon
## on utilise le mapping par count des _LAYOUT_PORTRAIT_NAMES.
func _reposition_speaker(speaker_index: int) -> void:
	var speaker_label := ui.get_node_or_null("Speaker") as Label
	if speaker_label == null:
		return

	var node_name: String = ""

	if not slot_layout.is_empty():
		if speaker_index < 0 or speaker_index >= slot_layout.size():
			return
		var slot_idx: int = slot_layout[speaker_index]
		if slot_idx < 0 or slot_idx >= _SLOT_INDEX_TO_NODE_NAME.size():
			return
		node_name = _SLOT_INDEX_TO_NODE_NAME[slot_idx]
	else:
		var count := participants.size()
		if not _LAYOUT_PORTRAIT_NAMES.has(count):
			return
		var names: Array = _LAYOUT_PORTRAIT_NAMES[count]
		if speaker_index < 0 or speaker_index >= names.size():
			return
		node_name = names[speaker_index]

	var portrait := ui.get_node_or_null(node_name) as TextureRect
	if portrait == null:
		return

	var center_x := portrait.position.x + portrait.size.x * portrait.scale.x * 0.5
	var half_w := speaker_label.size.x * 0.5
	speaker_label.position.x = center_x - half_w


## Retourne le nom de slot d'un speaker (résout les alias)
func _resolve_slot(speaker: String) -> String:
	if portrait_aliases.has(speaker):
		return portrait_aliases[speaker]
	return speaker


## Retourne le nom affiché du speaker.
## Cherche dans gm.characters un CharacterData dont Charaname == slot_name
## et retourne son Name personnalisé. Fallback sur le speaker brut si introuvable.
func _resolve_display_name(speaker: String) -> String:
	var slot_name := _resolve_slot(speaker)
	if _gm != null:
		for chara: CharacterData in _gm.characters:
			if chara.Charaname == slot_name:
				return chara.Name if chara.Name != "" else slot_name
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
