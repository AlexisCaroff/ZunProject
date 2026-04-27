extends Control

@onready var portrait_nodes: Array[TextureRect] = [
	$Portrait,   # gauche        (index 0)
	$Portrait3,  # centre-gauche (index 1)
	$Portrait4,  # centre-droite (index 2)
	$Portrait2,  # droite        (index 3)
]
@onready var dialogue_text: RichTextLabel = $RichTextLabel
@onready var name_label: Label = $Speaker

const COLOR_ACTIVE:   Color = Color(1, 1, 1, 1)
const COLOR_INACTIVE: Color = Color(0.3, 0.3, 0.3, 1.0)
const COLOR_HIDDEN:   Color = Color(1, 1, 1, 0)

var _participant_count: int = 0


func setup_layout(count: int) -> void:
	_participant_count = clamp(count, 1, 4)
	global_position = Vector2(0,0)
	for node in portrait_nodes:
		node.visible = false

	match _participant_count:
		1:
			portrait_nodes[0].visible = true
		2:
			portrait_nodes[0].visible = true
			portrait_nodes[3].visible = true
		3:
			portrait_nodes[0].visible = true
			portrait_nodes[1].visible = true
			portrait_nodes[2].visible = true
		4:
			for node in portrait_nodes:
				node.visible = true


# active_index = -1 → aucun portrait actif (cas Narrator)
func set_portraits_multi(textures: Array[Texture2D], active_index: int) -> void:
	var visible_nodes: Array[TextureRect] = []
	for node in portrait_nodes:
		if node.visible:
			visible_nodes.append(node)

	for i in range(visible_nodes.size()):
		var node = visible_nodes[i]
		if i < textures.size() and textures[i] != null:
			node.texture = textures[i]
			# active_index == -1 : tous inactifs (Narrator parle)
			node.modulate = COLOR_ACTIVE if i == active_index else COLOR_INACTIVE
		else:
			node.modulate = COLOR_HIDDEN


func set_text(speaker: String, text: String) -> void:
	name_label.text = speaker
	dialogue_text.bbcode_enabled=true
	dialogue_text.clear()
	dialogue_text.append_text(text)


func set_portraits(left: Texture2D, right: Texture2D, active_side: String = "left") -> void:
	set_portraits_multi(
		[left, right] as Array[Texture2D],
		0 if active_side == "left" else 1
	)
