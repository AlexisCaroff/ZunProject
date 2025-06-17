extends Label
@onready var button = get_parent()
@onready var startposition = position
@onready var startsize = Vector2(1.0,1.0)
func _on_action_1_mouse_entered() -> void:
	visible=true
	var tween := create_tween() as Tween
	var tweenpos := create_tween() as Tween
	var end_pose = Vector2(startposition.x,startposition.y +5)
	button.set_pivot_offset(button.size / 2)
	button.scale = Vector2(1.2, 1.2)
	self.set_pivot_offset(size / 2)
	var big_size = Vector2(1.2, 1.2)
	tweenpos.tween_property(self, "position", startposition, 0.05)
	tween.tween_property(self, "scale", startsize,0.00)
	tween.tween_property(self, "scale", big_size, 0.2)
	#tweenpos.tween_property(self, "position", end_pose, 0.2)


func _on_action_1_mouse_exited() -> void:
	button.set_pivot_offset(button.size / 2)
	button.scale = Vector2(1.0, 1.0)
	
	visible=false
