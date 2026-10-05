extends CanvasLayer
class_name FadeManager

@onready var rect := $FadeRect
var tween: Tween

func fade_to_black(duration := 0.15) -> void:
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, duration)
	print ("star fade")
func fade_from_black(duration := 0.15) -> void:
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, duration)
	print ("end fade")
