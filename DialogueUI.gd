extends Control

@onready var portrait := $Portrait
@onready var speaker_label := $Speaker
@onready var text_label := $Text

func set_portrait(tex: Texture2D):
	if tex:
		portrait.texture = tex
		portrait.visible = true
	else:
		portrait.visible = false

func set_text(speaker: String, text: String):
	speaker_label.text = speaker
	text_label.text = text
