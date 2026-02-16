extends Node2D

@onready var particles :GPUParticles2D = $heartParticules
@onready var particlesStun: GPUParticles2D =$GPUParticles2D
func _ready() -> void:
	particles.emitting = true

func setParticulesAlpha(alpha: float):
	print ("set particule " + str(alpha))
	if alpha>=1.0:
		alpha=1.0
		particlesStun. visible = true
	else :
		particlesStun. visible = false
	particles.modulate.a = alpha
