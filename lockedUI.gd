extends Control
@onready var label: RichTextLabel = $TextureRect/RichTextLabel

@export var phrases := [
	"It's locked.",
	"It won't budge.",
	"I need a key."
]

var tween: Tween

func _ready():
	# Choisir une phrase aléatoire
	label.text = phrases.pick_random()
	
	# état initial (petit et invisible)
	scale = Vector2(0.2, 0.2)
	modulate.a = 0
	
	# créer tween
	tween = create_tween()
	tween.set_parallel(true)
	
	# animation d'apparition (grandit)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.25)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	# attendre
	tween.chain().tween_interval(2.5)
	
	# animation de disparition
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.2, 0.2), 1.2)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
		
	tween.tween_property(self, "modulate:a", 0.0, 1.2)
	
	# supprimer le node à la fin
	tween.chain().tween_callback(queue_free)
