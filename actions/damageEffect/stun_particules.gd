extends Node2D
class_name StunParticules
@onready var particles :GPUParticles2D = $heartParticules

func _ready() -> void:
	particles.emitting = true

func setParticulesAlpha(alpha: float):
	print ("set particule " + str(alpha))
	if alpha>=1.0:
		alpha=1.0
	
	particles.modulate.a = alpha
func remove():
	print( "remove Stun Particules")
	queue_free()
