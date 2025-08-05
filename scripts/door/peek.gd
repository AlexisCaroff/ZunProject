extends Node
@onready var peektext : TextureRect=$peek_texture
var big_size = Vector2(1.2, 1.2)
var startsize = Vector2(1.0,1.0)
var current_tween: Tween = null

func _on_mouse_entered() -> void:
	peektext.scale = startsize 	
	peektext.set_pivot_offset(peektext.size/ 2)


	if current_tween:
		current_tween.kill()


	current_tween = create_tween()
	current_tween.tween_property(peektext, "scale", big_size, 0.2)


func _on_mouse_exited() -> void:
	peektext.scale = big_size	
	peektext.set_pivot_offset(peektext.size / 2)
	if current_tween:
		current_tween.kill()

	current_tween = create_tween()
	current_tween.tween_property(peektext, "scale", startsize, 0.2)


func _on_button_down() -> void:
	pass # Replace with function body.
