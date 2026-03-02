extends Control


@onready var boxUi = $"."
@export var animation_duration: float = 0.4
@export var animation_Start_Delay: float =0.0
@export var despawn: bool = false
signal animation_finished

func _ready() -> void:

	boxUi.pivot_offset = boxUi.size / 2
	boxUi.scale = Vector2(0, 0)
	
	
	# Tween pour le zoom-in avec rebond
	var tween = create_tween()
	tween.tween_property(boxUi, "scale", Vector2(1, 1), animation_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(animation_Start_Delay)
	tween.finished.connect(func():
		emit_signal("animation_finished")
	)
