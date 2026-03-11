extends Node2D

@onready var text = $RichTextLabel
@onready var voice = $AudioStreamPlayer2D
@onready var transi: SceneTransition =$".."
@export var scroll_speed = 20
var started:bool=false
func _Start():
	text.position.y = get_viewport_rect().size.y/1.8
	voice.play()

func _process(delta):
	
	if voice.playing:
		text.position.y -= scroll_speed * delta
		started=true
	else:
		if started:
			transi.fade_in()
			queue_free()
		
func _input(event):
	if event is InputEventMouseButton and event.pressed and self.visible and started:
		transi.fade_in()
		queue_free()
