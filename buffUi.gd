extends Control
class_name buffUI

@onready var back                       = $Box2
@onready var texture    : TextureRect   = $TextureBuff
@onready var textconteneur              = $TextLabel

var buff   : Buff   = null
var offset : Vector2 = Vector2.ZERO


func _process(_delta):
	var hovering = Rect2(Vector2.ZERO, texture.size).has_point(texture.get_local_mouse_position())
	textconteneur.visible = hovering
	back.visible          = hovering


func updatebuff(thebuff: Buff):
	buff = thebuff
	if texture == null:
		texture = $TextureBuff
	texture.texture = buff.icon
	refresh()


func refresh():
	if buff == null:
		return
	# textconteneur peut être null si le nœud n'est pas encore dans l'arbre
	if not is_instance_valid(textconteneur):
		return
	if buff.amount != 0:
		textconteneur.text = " %s  %d \n  %d turns." % [
			buff.Stat.keys()[buff.stat],
			buff.amount,
			buff.duration
		]
	else:
		textconteneur.text = " %s  \n  %d turns." % [
			buff.Stat.keys()[buff.stat],
			buff.duration
		]


func btover():
	textconteneur.visible = true
	back.visible          = true


func btexit():
	textconteneur.visible = false
	back.visible          = false
