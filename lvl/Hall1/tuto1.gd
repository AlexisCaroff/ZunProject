extends Sprite2D
@onready var button =$HideTuto
var gm
func _ready() -> void:
	button.connect("button_down",hideTuto)
	gm = get_tree().root.get_node("GameManager") as GameManager
	if gm.current_room_Ressource.ennemikilled==true:
		self.visible= false
func hideTuto():
	self.visible= false
