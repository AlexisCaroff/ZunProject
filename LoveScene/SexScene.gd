extends Node2D
@onready var label : Label = $DialogueBox/Label
@onready var button = $Button
@onready var sprite =$HunterxWarrior
@onready var base_scale: Vector2
func _ready() -> void:
	button.connect("button_down",exit_button_clic)
	var tween := create_tween() as Tween
	label.visible_ratio = 0.0
	base_scale = sprite.scale
	sprite.scale = sprite.scale*0.8
	modulate.a = 0.0  # On rend tout le node transparent au début
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_stylebox_override("focus_visible", empty)
	

	
	# 1️⃣ Apparition et zoom progressif
	tween.parallel().tween_property(sprite, "scale", base_scale, 0.5)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.5)
	
	# 2️⃣ Ensuite : révélation progressive du texte
	tween.tween_property(label, "visible_ratio", 1.0, 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
func exit_button_clic():
	var gm: GameManager = get_tree().root.get_node("GameManager") as GameManager
	await gm.sceneTransition.fade_out(0.5)
	self.visible=false
	await gm.sceneTransition.fade_in(0.5)
	self.queue_free()
