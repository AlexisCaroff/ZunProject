extends Node2D
@onready var label : Label = $DialogueBox/Label
@onready var button = $Button
func _ready() -> void:
	button.connect("button_down",exit_button_clic)
	var tween := create_tween() as Tween
	label.visible_ratio = 0.0
	scale = Vector2(0.6, 0.6)
	modulate.a = 0.0  # On rend tout le node transparent au début
	

	
	# 1️⃣ Apparition et zoom progressif
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.5)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.5)
	
	# 2️⃣ Ensuite : révélation progressive du texte
	tween.tween_property(label, "visible_ratio", 1.0, 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
func exit_button_clic():
	self.queue_free()
