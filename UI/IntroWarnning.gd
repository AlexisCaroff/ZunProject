extends TextureRect
@onready var cine =$"../Cinematic"

func _input(event):
	if event is InputEventMouseButton and event.pressed and self.visible:
		cine.visible=true
		cine._Start()
		self.visible=false 
