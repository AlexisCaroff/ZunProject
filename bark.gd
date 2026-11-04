extends Node2D
class_name Bark
@export var display_time := 1.8  # Durée avant disparition
## Largeur max du texte avant retour à la ligne.
@export var max_text_width := 260.0
@onready var label := $Label

const FONT_SIZE := 20


func set_text(text: String):
	label.text = text
	# Le Label est masqué dans bark.tscn (pour l'éditeur) : on l'affiche ici,
	# sinon aucune bulle n'apparaît en jeu.
	label.visible = true
	# Au-dessus des sprites des autres personnages et des slots.
	z_as_relative = false
	z_index = 100
	_apply_bubble_style(text)

	label.modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.8, 0.8)

	var tween = create_tween()

	tween.tween_property(label, "modulate:a", 1.0, 0.15)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(display_time)
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	tween.finished.connect(queue_free)


## Même fond que les bulles de survol (skills, bonus) : rectangle noir aux
## coins arrondis, taillé sur le texte. L'ancien cadre image est masqué.
func _apply_bubble_style(text: String) -> void:
	var box := label.get_node_or_null("DialogueBox") as CanvasItem
	if box:
		box.visible = false

	var font: Font = label.get_theme_font("font")
	var one_line := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var w: float = min(one_line + 4.0, max_text_width)
	var h := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, w, FONT_SIZE).y

	var style := StatHover.bubble_style()
	style.content_margin_left = StatHover.PAD.x
	style.content_margin_right = StatHover.PAD.x
	style.content_margin_top = StatHover.PAD.y
	style.content_margin_bottom = StatHover.PAD.y
	label.add_theme_stylebox_override("normal", style)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", FONT_SIZE)

	# Bulle centrée sur l'ancien emplacement, posée par son bas.
	var old_center_x: float = label.position.x + label.size.x * 0.5
	var old_bottom: float = label.position.y + label.size.y
	var full := Vector2(w + StatHover.PAD.x * 2.0, h + StatHover.PAD.y * 2.0)
	# Hauteur réelle mesurée par le Label lui-même une fois sa largeur fixée
	# (l'estimation de la police compte parfois une ligne de trop).
	label.size = Vector2(full.x, 0)
	full.y = label.get_minimum_size().y
	label.size = full
	label.position = Vector2(old_center_x - full.x * 0.5, old_bottom - full.y)
