extends Sprite2D
@onready var button =$HideTuto

func _ready() -> void:
	button.connect("button_down",hideTuto)
func hideTuto():
	self.visible= false
