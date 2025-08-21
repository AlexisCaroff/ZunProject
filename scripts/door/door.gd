extends Node
@onready var Doortext : TextureRect= $DoorText
var big_size = Vector2(1.2, 1.2)
var startsize = Vector2(1.0,1.0)
var current_tween: Tween = null
@export_file("*.tscn") var target_scene : String
@onready var sub_viewport = $"../SubViewportContainer/SubViewport"
@export var encounter_for_this_door: CombatEncounter

func _ready():
	var peek_scene = load("res://UI/peekScene.tscn").instantiate()
	sub_viewport.add_child(peek_scene)
	#await peek_scene.ready
	print("next room ready")
	peek_scene.set_encounter(encounter_for_this_door)
	
	
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
	
	if target_scene != "":
		get_tree().change_scene_to_file(target_scene)
	
	
