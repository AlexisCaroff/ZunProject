extends Control
class_name buffUI

var buff : Buff= null
@onready var texture: TextureRect = $TextureBuff
@onready var button=$Button
@onready var textconteneur = $TextLabel

func _ready() -> void:
	button.connect("mouse_entered",btover)
	button.connect("mouse_exited",btexit)
	
func updatebuff(thebuff:Buff):
		texture = $TextureBuff
		textconteneur = $TextLabel
		buff = thebuff
		texture.texture = buff.icon
		if buff.amount!=0:
			textconteneur.text= " %s  %d \n  %d turns." % [
			buff.Stat.keys()[buff.stat],
			buff.amount,
			buff.duration]
		else :
			textconteneur.text= " %s  \n  %d turns." % [
			buff.Stat.keys()[buff.stat],
			buff.duration]
	
func btover():
	textconteneur.visible=true

	
func btexit():
	textconteneur.visible=false
