extends Control

@onready var portrait_nodes: Array[TextureRect] = [
	$Portrait,   # gauche       (index 0)
	$Portrait3,  # centre-gauche (index 1)
	$Portrait2,  # centre-droite (index 2)
	$Portrait4,  # droite        (index 3)
]
@onready var dialogue_text: RichTextLabel = $RichTextLabel
@onready var name_label: Label = $Speaker

const COLOR_ACTIVE:   Color = Color(1, 1, 1, 1)
const COLOR_INACTIVE: Color = Color(0.3, 0.3, 0.3, 1.0)
const COLOR_HIDDEN:   Color = Color(1, 1, 1, 0)   # transparent quand inutilisé

var _participant_count: int = 0


# Appelé par DialogueManager.load_dialogue() avant le premier show_line()
func setup_layout(count: int) -> void:
	_participant_count = clamp(count, 1, 4)

	# Masque tous les portraits, puis affiche seulement ceux nécessaires
	for node in portrait_nodes:
		node.visible = false

	match _participant_count:
		1:
			# Un seul portrait, affiché à gauche (ou centré selon ta scène)
			portrait_nodes[0].visible = true

		2:
			portrait_nodes[0].visible = true   # gauche
			portrait_nodes[2].visible = true   # droite
			# Repositionnement optionnel si tes nœuds ne sont pas déjà bien placés
			# portrait_nodes[0].position = Vector2(...)
			# portrait_nodes[2].position = Vector2(...)

		3:
			portrait_nodes[0].visible = true   # gauche
			portrait_nodes[1].visible = true   # centre
			portrait_nodes[2].visible = true   # droite

		4:
			for node in portrait_nodes:
				node.visible = true


# Reçoit un tableau de textures (dans l'ordre des participants) + l'index du locuteur
func set_portraits_multi(textures: Array[Texture2D], active_index: int) -> void:
	var visible_nodes: Array[TextureRect] = []

	# Récupère seulement les nodes visibles (dans l'ordre)
	for node in portrait_nodes:
		if node.visible:
			visible_nodes.append(node)

	# Applique les textures correctement
	for i in range(visible_nodes.size()):
		var node = visible_nodes[i]

		if i < textures.size():
			node.texture = textures[i]
			node.modulate = COLOR_ACTIVE if i == active_index else COLOR_INACTIVE
		else:
			node.modulate = COLOR_HIDDEN


func set_text(speaker: String, text: String) -> void:
	name_label.text = speaker
	dialogue_text.text = text


# Conservé pour compatibilité si d'autres scripts l'appellent encore
func set_portraits(left: Texture2D, right: Texture2D, active_side: String = "left") -> void:
	set_portraits_multi(
		[left, right] as Array[Texture2D],
		0 if active_side == "left" else 1
	)
