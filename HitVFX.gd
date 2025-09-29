extends Node2D

@onready var label = $Label
@onready var anim = $AnimationPlayer
@onready var visuel : Array[Node2D] = []
var color = null

func setup(damage_amount: int, _thecolor = null):
	if _thecolor != null:
		for child in get_children():
			if child is Node2D:
				child.modulate = _thecolor
	label.text = "-" + str(damage_amount)
	anim.play("hit")



func _on_animation_player_animation_finished(anim_name: StringName) -> void:
		queue_free()
