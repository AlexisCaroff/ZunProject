extends Button
class_name action_Button
var big_size = Vector2(1.2, 1.2)
var startsize = Vector2(1.0,1.0)
@onready var label : RichTextLabel 
@onready var startposition : Vector2
var Actiontext : String = "Move"
var current_tween: Tween = null
var current_tween_button: Tween = null


func _on_mouse_entered() -> void:
	z_index =1
	if label:
		startposition = label.position
		label.scale = startsize 
		label.visible = true
		label.text = Actiontext
		self.set_pivot_offset(size / 2)
		label.set_pivot_offset(label.size / 2)
		if label.has_meta("tip_anchor"):
			_fit_tip()

	if current_tween:
		current_tween.kill()
	if current_tween_button:
		current_tween_button.kill()

	current_tween_button = create_tween()
	current_tween_button.tween_property(self, "scale", big_size, 0.2)

	current_tween = create_tween()
	current_tween.tween_property(label, "scale", big_size, 0.2)


## Infobulle à la hauteur de son texte, posée au-dessus de son point
## d'ancrage (bas-centre, coordonnées globales ; cf. ui_combat).
func _fit_tip() -> void:
	var anchor: Vector2 = label.get_meta("tip_anchor")
	var margins := label.get_theme_stylebox("normal").get_minimum_size()
	label.size = Vector2(label.size.x, label.get_content_height() + margins.y)
	label.global_position = anchor - Vector2(label.size.x * 0.5, label.size.y)
	# Le grossissement au survol part du bas : l'infobulle grandit vers le haut.
	label.set_pivot_offset(Vector2(label.size.x * 0.5, label.size.y))


func _on_mouse_exited() -> void:
	z_index =0
	label.visible = false
	label.text = Actiontext

	if current_tween:
		current_tween.kill()
	if current_tween_button:
		current_tween_button.kill()


	current_tween_button = create_tween()

	self.scale = big_size
	current_tween_button.tween_property(self, "scale", startsize, 0.2)
