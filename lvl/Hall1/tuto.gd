extends Sprite2D
@onready var button =$HideTuto
@onready var ButtonShowTuto=$"../ShowTuto"
var gm : GameManager
func _ready() -> void:
	button.connect("button_down",hideTuto)
	ButtonShowTuto.connect("button_down",showTuto)
	gm = get_tree().root.get_node("GameManager") as GameManager
	if gm.current_room_Ressource.ennemikilled==true:
		self.visible= false
func hideTuto():
	self.visible= false
func showTuto():
	self.visible= true
