extends Node2D

@onready var label = $Label
@onready var anim = $AnimationPlayer

func setup(damage_amount: int ):
	label.text = "-" + str(damage_amount)
	anim.play("hit")



func _on_animation_player_animation_finished(anim_name: StringName) -> void:
		queue_free()
