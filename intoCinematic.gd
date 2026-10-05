extends Node2D
## Introduction du donjon : texte qui défile pendant la voix du narrateur.
## Lancée par GameManager._play_intro_cinematic() après « Start » ; émet
## `finished` à la fin de la voix ou au clic, puis se libère.

signal finished

@onready var text = $RichTextLabel
@onready var voice = $AudioStreamPlayer2D
@export var scroll_speed = 20
var started:bool=false
var _done: bool = false

func _Start():
	text.position.y = get_viewport_rect().size.y/1.8
	voice.play()

func _process(delta):
	if voice.playing:
		text.position.y -= scroll_speed * delta
		started=true
	elif started:
		_finish()

func _input(event):
	if event is InputEventMouseButton and event.pressed and self.visible and started:
		_finish()

func _finish() -> void:
	if _done:
		return
	_done = true
	voice.stop()
	finished.emit()
	queue_free()
