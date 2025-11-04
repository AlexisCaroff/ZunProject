extends Control

@onready var left_portrait: TextureRect = $Portrait
@onready var right_portrait: TextureRect = $Portrait2
@onready var dialogue_text: RichTextLabel = $RichTextLabel
@onready var name_label: Label = $Speaker

func set_text(speaker: String, text: String) -> void:
	name_label.text = speaker
	dialogue_text.text = text

func set_portraits(left: Texture2D, right: Texture2D, active_side: String = "left") -> void:
	left_portrait.texture = left
	right_portrait.texture = right
	
	# Met en avant celui qui parle
	if active_side == "left":
		left_portrait.modulate = Color(1, 1, 1, 1)
		right_portrait.modulate = Color(0.3, 0.3, 0.3, 1.0)
	elif active_side == "right":
		left_portrait.modulate = Color(0.3, 0.3, 0.3, 1.0)
		right_portrait.modulate = Color(1, 1, 1, 1)
