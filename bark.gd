extends Node2D
class_name Bark
@export var display_time := 1.8  # Durée avant disparition
@onready var label := $Label

func set_text(text: String):
	label.text = text
	label.modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(label, "modulate:a", 1.0, 0.15)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(display_time)
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	tween.finished.connect(queue_free)
