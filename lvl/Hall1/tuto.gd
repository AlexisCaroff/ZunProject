extends Sprite2D
@onready var button =$HideTuto
@onready var ButtonShowTuto=$"../ShowTuto"
func _ready() -> void:
	button.connect("button_down",hideTuto)
	ButtonShowTuto.connect("button_down",showTuto)
func hideTuto():
	self.visible= false
func showTuto():
	self.visible= true
