extends Node2D
@onready var particules :GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	particules.emitting =true
	await get_tree().create_timer(2.1)
	remove()
func remove():
	await get_tree().create_timer(2.1)
	print ("remove ParticulesS")
	#queue_free()
