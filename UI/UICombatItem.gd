extends Sprite2D
@onready var button= $Button
@export var normal_color: Color = Color.WHITE
@export var hover_color: Color = Color.BISQUE

@export var hover_scale: Vector2 = Vector2(1.2, 1.2)
var normal_scale: Vector2 
var equipement : Equipment = null
@onready var label = $RichTextLabel

## Clic sur un objet équipé. Seules les scènes qui le connectent
## (exploration, porte) permettent de déséquiper : en combat, rien.
signal unequip_requested(item: Equipment)

## Infobulle posée à DROITE de la case, pour ne pas recouvrir l'objet.
## Repère local du slot (le cadre fait ~112 px, centré sur 0).
@export var tooltip_offset: Vector2 = Vector2(66, -34)
@export var tooltip_width: float = 260.0


const ITEM_BOX := preload("res://UI/UI boxes/UI_combat_itembox.png")


func _ready():
	_ensure_box()
	button.connect("mouse_entered", over)
	button.connect("mouse_exited",exit)
	normal_scale= scale
	
	
	button.pressed.connect(_on_pressed)

	label.position = tooltip_offset
	label.size = Vector2(tooltip_width, label.size.y)
	label.fit_content = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Le grossissement au survol part du bord gauche, collé à la case.
	label.pivot_offset = Vector2(0, label.size.y / 2)


func _on_pressed() -> void:
	if equipement != null:
		emit_signal("unequip_requested", equipement)


## Le cadre doit rester visible, vide ou non. En combat il était la texture
## du Sprite lui-même : l'icône de l'objet l'écrasait, et remove_item()
## l'effaçait. On le déplace dans un enfant dessiné derrière, la texture du
## Sprite ne porte plus que l'icône. L'exploration a déjà son cadre en
## enfant (TextureRect) : rien à faire.
func _ensure_box() -> void:
	for child in get_children():
		if child is TextureRect and child.texture == ITEM_BOX:
			return
	var box := Sprite2D.new()
	box.name = "Box"
	box.texture = ITEM_BOX
	box.show_behind_parent = true
	add_child(box)
	move_child(box, 0)
	if texture == ITEM_BOX:
		texture = null


func assigne_item(item:Equipment):
	
	equipement = item
	texture= equipement.icon
	label.bbcode_enabled = true
	label.bbcode_text= "[b][color=AA55FF]%s[/color][/b]\n%s" % [equipement.name, equipement.description]
func remove_item():
	equipement = null
	texture=null
	if !label:
		label = $RichTextLabel
	label.bbcode_enabled = true
	label.bbcode_text= "[b][color=AA55FF][/color][/b]\n%s"
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
