extends Control
class_name ItemUi
@onready var imageContainer = $boxUI/imageObj
@onready var label=$boxUI/Labelname
@export var image = null
@onready var boxUi = $boxUI
@export var animation_duration: float = 0.4
@export var despawn: bool = false
signal animation_finished

func _ready() -> void:
	if image != null:
		imageContainer.texture = image
	boxUi.pivot_offset = boxUi.size / 2
	boxUi.scale = Vector2(0, 0)
	
	
	# Tween pour le zoom-in avec rebond
	var tween = create_tween()
	tween.tween_property(boxUi, "scale", Vector2(1, 1), animation_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		emit_signal("animation_finished")
	)
func _input(event):
	if event is InputEventMouseButton && despawn:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			on_left_click()
			
func on_left_click():
	var tween = create_tween()
	tween.parallel().tween_property(boxUi, "scale", Vector2(0, 0), animation_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position", position+Vector2(700,300), animation_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.finished.connect(func():emit_signal("animation_finished"))
	await tween.finished
	queue_free()

func setObject(theimage: Texture, text: String):
	imageContainer = $boxUI/imageObj
	label=$boxUI/Labelname
	image = theimage
	imageContainer.texture = image
	label.text = text
