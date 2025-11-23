extends Sprite2D
@onready var button= $Button
@export var normal_color: Color = Color.WHITE
@export var hover_color: Color = Color.BISQUE

@export var hover_scale: Vector2 = Vector2(1.2, 1.2)
var normal_scale: Vector2 
var equipement : Equipment = null
@onready var label = $RichTextLabel


func _ready():
	button.connect("mouse_entered", over)
	button.connect("mouse_exited",exit)
	normal_scale= scale
	
	label.pivot_offset = label.size / 2
func assigne_item(item:Equipment):
	
	equipement = item
	texture= equipement.icon
	label.bbcode_enabled = true
	label.bbcode_text= "[b][color=ff5555]%s[/color][/b]\n%s" % [equipement.name, equipement.description]
	
	
func over():
	if equipement:
		label.visible = true
		var tween = create_tween()
		tween.tween_property(label, "scale", hover_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "self_modulate", hover_color, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	
func exit():
	label.visible = false
	
	var tween = create_tween()
	tween.tween_property(label, "scale", normal_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "self_modulate", normal_color, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
