extends Sprite2D
@onready var button =$"../ExplorationManager/Button"
@export var theskew: float =0.2
@export var duration: float =0.2
func _ready() -> void:
	button.connect("mouse_entered", openning)
	button.connect("mouse_exited", close)
func openning():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "skew",theskew , duration)
	
func close():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "skew",0.0 , duration)
