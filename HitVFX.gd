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
		label.add_theme_color_override("font_color", _thecolor)
	label.text = "" + str(damage_amount)
	
	anim.play("hit")
	# Applique la 1re cle tout de suite : sinon le label est dessine une frame
	# a sa position de scene avant que l'animation ne demarre.
	anim.advance(0)



func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
		queue_free()
