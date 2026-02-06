extends Resource
class_name Animatic
@export var fade_duration := 1.0
@export var final_hold_time := 2.0 # durée écran de la dernière image

@export var frames: Array[AnimaticFrame]
@export var pan := Vector2(960.0,540.0)
@export var zoom := 1.0
@export var zoomTime := 0.0
@export var text := ""
@export var sound: AudioStream
