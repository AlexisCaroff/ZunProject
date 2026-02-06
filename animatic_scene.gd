extends Control
class_name AnimaticSceneContainer
@export var animatic: Animatic
@onready var img_a: TextureRect =$CanvasLayer/Images/ImageA
@onready var img_b: TextureRect = $CanvasLayer/Images/ImageB
@onready var AudioPLayer = $CanvasLayer/AudioStreamPlayer2D
@onready var cam :Camera
var index := 0
var front: TextureRect
var back: TextureRect
signal Animatic_finished
var current_index := 0

func _ready():
	front = img_a
	back = img_b
	
	front.texture = animatic.frames[0].texture
	front.modulate.a = 1.0
	back.modulate.a = 0.0
	play_animatic(cam)

	
func play_animatic(camera:Camera) -> void:
	cam=camera
	cam.zoom_to_position(animatic.pan, animatic.zoom,animatic.zoomTime)
	if animatic.sound :
		AudioPLayer.stream = animatic.sound
		AudioPLayer.play()
	while index < animatic.frames.size() - 1:
		var current_at = animatic.frames[index].at
		var next_at = animatic.frames[index + 1].at

		var visible_time = max(0.0, next_at - current_at)
		if visible_time==0.0:
			visible_time=animatic.fade_duration
		# On attend jusqu'au moment du fade
		await get_tree().create_timer(
			max(0.0, visible_time - animatic.fade_duration)
		).timeout

		# prépare la suivante
		back.texture = animatic.frames[index + 1].texture
		back.modulate.a = 0.0

		await cross_fade()
		swap_images()

		index += 1

	# Dernière image
	await get_tree().create_timer(animatic.final_hold_time).timeout
	close()
func cross_fade() -> void:
	var tween := create_tween()
	tween.parallel().tween_property(
		front, "modulate:a", 0.0, animatic.fade_duration*2.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.parallel().tween_property(back, "modulate:a", 1.0, animatic.fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished
	
func swap_images():
	var tmp = front
	front = back
	back = tmp
func close():
	cam.zoom=Vector2(1.0,1.0)
	cam.position= Vector2(960,540)
	emit_signal("Animatic_finished")
	queue_free()
