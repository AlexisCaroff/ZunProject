extends Node
@onready var backtext : TextureRect= $BackText
var big_size = Vector2(1.2, 1.2)
var startsize = Vector2(1.0,1.0)
var current_tween: Tween = null
@export var next_scene: PackedScene 


func _on_mouse_exited() -> void:
	backtext.scale = big_size	
	backtext.modulate.a=0.5
	backtext.set_pivot_offset(backtext.size/ 2)
	if current_tween:
		current_tween.kill()

	current_tween = create_tween()
	current_tween.tween_property(backtext, "scale", startsize, 0.2)



func _on_mouse_entered() -> void:
	backtext.scale = startsize 	
	backtext.modulate.a=1.0
	backtext.set_pivot_offset(backtext.size / 2)


	if current_tween:
		current_tween.kill()


	current_tween = create_tween()
	current_tween.tween_property(backtext, "scale", big_size, 0.2)
	



func _on_button_down() -> void:
	call_deferred("change_to_next_scene")



func change_to_next_scene():
	if get_tree():
		get_tree().change_scene_to_packed(next_scene)
	else:
		print("Erreur : get_tree() est null.")
	
