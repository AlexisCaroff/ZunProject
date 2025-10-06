extends Node2D

@onready var label = $Label
@onready var anim = $AnimationPlayer
@onready var visuel : Array[Node2D] = []
var color = null

func setup(texte: String ):
	label.text = texte
	
	anim.play("hit")



func _on_animation_player_animation_finished(anim_name: StringName) -> void:
		queue_free()
