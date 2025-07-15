
extends CanvasLayer

@onready var rect := $ColorRect

func fade_out(duration := 1.0) -> void:
	var tween = create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, duration)
	await tween.finished
