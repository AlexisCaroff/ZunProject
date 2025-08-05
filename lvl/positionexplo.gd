extends Node2D
var occupant: CharaExplo = null
@onready var explo_manager =$"../../ExplorationManager"


func _on_button_button_down() -> void:
	explo_manager.selectCharacter(occupant)
	
