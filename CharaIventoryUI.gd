extends TextureRect

var chara :Character
@onready var button =$Button
@onready var inventory = $"../.."
@export var normal_color: Color = Color.WHITE
@export var hover_color: Color = Color.BISQUE

@export var hover_scale: Vector2 = Vector2(1.2, 1.2)
@onready var thetexture = $chara
var normal_scale: Vector2 
func _ready():
	button.connect("button_down",select_Chara)
	button.connect("mouse_entered", over)
	button.connect("mouse_exited",exit)
	normal_scale = thetexture.scale
	thetexture.pivot_offset = thetexture.size / 2
func  select_Chara():
	inventory.select_character(chara)
	
func over():
		
	var tween = create_tween()
	tween.tween_property( thetexture, "scale", hover_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property( thetexture, "self_modulate", hover_color, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	
func exit():
	
	
	var tween = create_tween()
	tween.tween_property( thetexture, "scale", normal_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property( thetexture, "self_modulate", normal_color, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
