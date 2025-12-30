extends Button


@export var normal_color: Color = Color.WHITE
@export var hover_color: Color = Color.BISQUE

# échelle configurables
@export var normal_scale: Vector2 = Vector2.ONE
@export var hover_scale: Vector2 = Vector2(1.2, 1.2)
@export var centered : bool =true

func _ready():
	if centered:
		pivot_offset = size / 2
	# couleur de départ
	self_modulate = normal_color
	scale = normal_scale
	if disabled:
		modulate.a = 0.0
	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override("focus", empty)
	add_theme_stylebox_override("focus_visible", empty)
	# connecter les signaux de souris
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))

func _on_mouse_entered():
	if not disabled:
		var tween = create_tween()
		tween.tween_property(self, "scale", hover_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if icon :
			tween.tween_property(self, "self_modulate", hover_color, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if get_child(0) != null:
			var obj = get_child(0)
			tween.tween_property(obj, "self_modulate", hover_color, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
func _on_mouse_exited():
	if not disabled:
		var tween = create_tween()
		tween.tween_property(self, "scale", normal_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if icon :
			tween.tween_property(self, "self_modulate", normal_color, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if get_child(0) != null:
			var obj = get_child(0)
			tween.tween_property(obj, "self_modulate", normal_color, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
