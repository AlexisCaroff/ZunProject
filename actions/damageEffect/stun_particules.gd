extends Node2D

@onready var particles :GPUParticles2D = $heartParticules

func _ready() -> void:
	particles.emitting = true

func setParticulesAlpha(alpha: float):
	print ("set particule " + str(alpha))
	if alpha>=1.0:
		alpha=1.0
	
	particles.modulate.a = alpha
func remove():
	queue_free()
