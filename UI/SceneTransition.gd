extends CanvasLayer
class_name SceneTransition

@onready var fade_rect: ColorRect = $ColorRect
var tween: Tween

func _ready():
	fade_rect.modulate.a = 0

func fade_out(duration := 0.2) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished

func fade_in(duration := 0.2) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	await tween.finished
