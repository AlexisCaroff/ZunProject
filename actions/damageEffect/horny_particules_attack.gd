extends Node2D
@onready var particules :GPUParticles2D = $GPUParticles2D
@onready var particules2 :GPUParticles2D = $heartParticules
func _ready() -> void:
	particules.emitting =true
	particules2.emitting  = true
	await get_tree().create_timer(2.1)
	await remove()
func remove():
	await get_tree().create_timer(2.1)
	print ("remove ParticulesS")
	queue_free()
