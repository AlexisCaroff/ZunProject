extends Button
@onready var pose1 =$"../pose1"
@onready var doorbutton=$"../Door"
@onready var peekScene=$"../SubViewportContainer"

	


func _on_button_down() -> void:
	self.visible=false
	doorbutton.position=pose1.position
	peekScene.visible=false
