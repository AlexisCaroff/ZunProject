extends Button

var big_size = Vector2(1.2, 1.2)
var startsize = Vector2(1.0,1.0)
@onready var label = get_node("../../LabelAction")
@onready var startposition = label.position
var Actiontext : String = "name"
var current_tween: Tween = null
var current_tween_button: Tween = null


func _on_mouse_entered() -> void:
	label.scale = startsize # 👈 forcer la valeur avant visibilité
	label.visible = true
	label.text = Actiontext
	self.set_pivot_offset(size / 2)
	label.set_pivot_offset(label.size / 2)

	if current_tween:
		current_tween.kill()
	if current_tween_button:
		current_tween_button.kill()

	current_tween_button = create_tween()
	current_tween_button.tween_property(self, "scale", big_size, 0.2)

	current_tween = create_tween()
	current_tween.tween_property(label, "scale", big_size, 0.2)


func _on_mouse_exited() -> void:
	label.visible = false
	label.text = Actiontext

	if current_tween:
		current_tween.kill()
	if current_tween_button:
		current_tween_button.kill()


	current_tween_button = create_tween()

	self.scale = big_size
	current_tween_button.tween_property(self, "scale", startsize, 0.2)
