extends Control

@onready var portrait_nodes: Array[TextureRect] = [
	$Portrait,   # gauche        (slot 0 / "position 1")
	$Portrait3,  # centre-gauche (slot 1 / "position 2")
	$Portrait4,  # centre-droite (slot 2 / "position 3")
	$Portrait2,  # droite        (slot 3 / "position 4")
]
@onready var dialogue_text: RichTextLabel = $RichTextLabel
@onready var name_label: Label = $Speaker

const COLOR_ACTIVE:   Color = Color(1, 1, 1, 1)
const COLOR_INACTIVE: Color = Color(0.3, 0.3, 0.3, 1.0)
const COLOR_HIDDEN:   Color = Color(1, 1, 1, 0)

var _participant_count: int = 0
## Slots actuellement utilisés (dans l'ordre où les participants seront
## affichés). Permet à set_portraits_multi() de savoir quel index visible
## correspond à quel slot du layout.
var _active_slots: Array[int] = []


func setup_layout(count: int) -> void:
	_participant_count = clamp(count, 1, 4)
	global_position = Vector2(0, 0)
	for node in portrait_nodes:
		node.visible = false

	match _participant_count:
		1:
			_active_slots = [0]
		2:
			_active_slots = [0, 3]
		3:
			_active_slots = [0, 1, 2]
		4:
			_active_slots = [0, 1, 2, 3]

	for slot in _active_slots:
		portrait_nodes[slot].visible = true


## Variante explicite : on choisit quels slots sont visibles. Utile pour
## les scènes spéciales où le layout par défaut (3 → 0,1,2) ne convient
## pas. Exemple : give_in branch → [0, 1, 3] pour laisser le slot 2 vide.
##
## L'ordre du tableau définit l'ordre d'affectation des textures dans
## set_portraits_multi() : textures[0] va dans slot_indices[0], etc.
func setup_layout_explicit(slot_indices: Array[int]) -> void:
	global_position = Vector2(0, 0)
	for node in portrait_nodes:
		node.visible = false

	_active_slots.clear()
	for slot in slot_indices:
		if slot >= 0 and slot < portrait_nodes.size():
			portrait_nodes[slot].visible = true
			_active_slots.append(slot)
	_participant_count = _active_slots.size()


# active_index = -1 → aucun portrait actif (cas Narrator)
func set_portraits_multi(textures: Array[Texture2D], active_index: int) -> void:
	# On itère sur _active_slots (ordre logique = ordre des textures)
	# plutôt que sur portrait_nodes (ordre visuel).
	for i in range(_active_slots.size()):
		var node: TextureRect = portrait_nodes[_active_slots[i]]
		if i < textures.size() and textures[i] != null:
			node.texture = textures[i]
			node.modulate = COLOR_ACTIVE if i == active_index else COLOR_INACTIVE
		else:
			node.modulate = COLOR_HIDDEN


func set_text(speaker: String, text: String) -> void:
	name_label.text = speaker
	dialogue_text.bbcode_enabled = true
	dialogue_text.clear()
	dialogue_text.append_text(text)


func set_portraits(left: Texture2D, right: Texture2D, active_side: String = "left") -> void:
	set_portraits_multi(
		[left, right] as Array[Texture2D],
		0 if active_side == "left" else 1
	)
