extends Node2D

@onready var label = $Label
@onready var particles = $heartParticules
@onready var anim = $AnimationPlayer

func setup(damage_amount: int ):
	label.text = "-" + str(damage_amount)
	particles.emitting = true
	anim.play("charmed")



func _on_animation_player_animation_finished() -> void:
		queue_free()
