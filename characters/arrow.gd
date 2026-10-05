extends Node2D



@export var decalage: float = 1.0
@export var min_duration: float = 0.6
@export var max_duration: float = 1.0
@export var play : bool = true
func _ready():
	randomize()

	var decal = Vector2(0,decalage)
	var duration = randf_range(min_duration, max_duration)
	var delay = randf_range(duration, duration*1.5) # pour décaler les persos entre eux

	var tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	#tween.tween_interval(delay)
	tween.tween_property(self, "position", position-decal, delay)
	tween.tween_property(self, "position", position+decal, duration)
