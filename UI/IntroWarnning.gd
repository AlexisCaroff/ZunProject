extends TextureRect
@onready var button =$HideTuto

var gm
func _ready() -> void:
	button.connect("button_down",hideTuto)
	gm = get_tree().root.get_node("GameManager") as GameManager

func hideTuto():
	self.visible= false
