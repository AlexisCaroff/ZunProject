extends TextureRect
@onready var button= $charaPortraitButton
@export var normal_color: Color = Color.WHITE
@export var hover_color: Color = Color.BISQUE

@export var hover_scale: Vector2 = Vector2(1.2, 1.2)
var normal_scale: Vector2 




func _ready():
	button.connect("mouse_entered", over)
	button.connect("mouse_exited",exit)
	normal_scale= scale
	pivot_offset = size / 2
	


	
func over():


	var tween = create_tween()
	tween.tween_property(self, "scale", hover_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "self_modulate", hover_color, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	
func exit():
	
	
	var tween = create_tween()
	tween.tween_property(self, "scale", normal_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "self_modulate", normal_color, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
