extends ColorRect
@onready var buttonChara =  $"../ContourMap/ButtonCharainfo"
@onready var buttonMap = $"../ContourMap/ButtonMap"
func _ready() -> void:
	buttonChara.connect("button_down",showChara)
	buttonMap.connect("button_down",showMap)

func showChara():
	self.visible = true
	buttonChara.z_index=1
	buttonMap.z_index = -1
func showMap():
	self.visible=false
	buttonChara.z_index=-1
	buttonMap.z_index = 1
	
