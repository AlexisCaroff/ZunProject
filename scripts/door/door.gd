extends Node
@onready var Doortext : TextureRect= $DoorText
var big_size = Vector2(1.2, 1.2)
var startsize = Vector2(1.0,1.0)
var current_tween: Tween = null
@export var next_scene: PackedScene 


func _on_mouse_exited() -> void:
	Doortext.scale = big_size	
	Doortext.set_pivot_offset(Doortext.size/ 2)
	if current_tween:
		current_tween.kill()

	current_tween = create_tween()
	current_tween.tween_property(Doortext, "scale", startsize, 0.2)



func _on_mouse_entered() -> void:
	Doortext.scale = startsize 	
	Doortext.set_pivot_offset(Doortext.size / 2)


	if current_tween:
		current_tween.kill()


	current_tween = create_tween()
	current_tween.tween_property(Doortext , "scale", big_size, 0.2)
	



func _on_button_down() -> void:
	GameState.current_phase = GameStat.GamePhase.COMBAT
	call_deferred("change_to_next_scene")



func change_to_next_scene():
	if get_tree():
		get_tree().change_scene_to_packed(next_scene)
	else:
		print("Erreur : get_tree() est null.")
	
