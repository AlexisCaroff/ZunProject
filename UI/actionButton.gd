extends Button


@onready var startsize = Vector2(1.0,1.0)
@onready var label = get_node("../../LabelAction")
@onready var startposition = label.position
var Actiontext : String = "name"


func _on_mouse_entered() -> void:
	label.visible=true
	label.text = Actiontext
	var tween := create_tween() as Tween
	var tweenbutton := create_tween() as Tween
	var end_pose = Vector2(startposition.x,startposition.y +5)
	self.set_pivot_offset(size / 2)
	
	label.set_pivot_offset(label.size / 2)
	var big_size = Vector2(1.2, 1.2)
	tweenbutton.tween_property(self, "scale", startsize, 0.0)
	tweenbutton.tween_property(self, "scale", big_size, 0.2)
	tween.tween_property(label, "scale", startsize,0.00)
	tween.tween_property(label, "scale", big_size, 0.2)


func _on_mouse_exited() -> void:
	label.visible=false
	var tween := create_tween() as Tween
	label.text = Actiontext
	var tweenbutton := create_tween() as Tween
	tweenbutton.tween_property(self, "scale", startsize, 0.1)
