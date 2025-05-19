extends Node2D

@onready var label = $Label

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		label.text = "Cible sélectionnée"


func _on_area_2d_mouse_entered() -> void:
	label.text = "Over"
