extends Node2D

@export var min_scale: float = 0.95
@export var max_scale: float = 1.0
@export var scalemini: float = 1.0
@export var min_duration: float = 0.6
@export var max_duration: float = 1.0
@export var play : bool = true
func _ready():
	randomize()

	var target_scale = randf_range(min_scale, max_scale)
	var duration = randf_range(min_duration, max_duration)
	var delay = randf_range(0.0, duration) # pour décaler les persos entre eux

	var tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	#tween.tween_interval(delay)
	tween.tween_property(self, "scale:y", target_scale, duration)
	tween.tween_property(self, "scale:y", scalemini, duration)
