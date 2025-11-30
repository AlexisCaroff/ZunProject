extends Node2D
var occupant: CharaExplo = null
@onready var explo_manager =$"../../ExplorationManager"
@onready var button =$Button
@onready var movebutton =$"../../moveButton"
func _on_button_button_down() -> void:
	explo_manager.selectCharacter(occupant)
	
func _ready() -> void:
	button.connect("mouse_entered", showMove)

func showMove():
	movebutton.position= Vector2(self.global_position.x, (self.global_position.y-320) )
