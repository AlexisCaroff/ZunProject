extends Node2D


@onready var anim = $AnimationPlayer

func setup():

	anim.play("missAnimation")



func _on_animation_player_animation_finished(anim_name: StringName) -> void:
		queue_free()
