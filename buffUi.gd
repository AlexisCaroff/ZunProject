extends Control
class_name buffUI
@onready var  back = $Box2
var buff : Buff= null
@onready var texture: TextureRect = $TextureBuff

@onready var textconteneur = $TextLabel

var offset: Vector2 = Vector2.ZERO


	
func _process(delta):
	
	var hovering = Rect2(Vector2.ZERO, texture.size).has_point(texture.get_local_mouse_position())
	textconteneur.visible = hovering
	back.visible = hovering
func updatebuff(thebuff: Buff):
	buff = thebuff
	if texture==null:
		texture = $TextureBuff
	texture.texture = buff.icon
	
	refresh()

func refresh():
	if buff == null:
		return
	#global_position = get_parent().global_position + offset
	if buff.amount != 0:
		textconteneur.text = " %s  %d \n  %d turns." % [
			buff.Stat.keys()[buff.stat],
			buff.amount,
			buff.duration]
	else:
		textconteneur.text = " %s  \n  %d turns." % [
			buff.Stat.keys()[buff.stat],
			buff.duration]

func btover():
	textconteneur.visible=true
	back.visible =true
	
func btexit():
	textconteneur.visible=false
	back.visible =false
