extends TextureRect
@onready var pose1 =$"../pose1"
@onready var doorbutton=$"../Door"
func _on_button_button_down() -> void:
	self.visible=false
	doorbutton.position=pose1.position
