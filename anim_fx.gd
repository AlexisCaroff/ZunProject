extends Node2D
class_name SkillFX
 
@onready var anim: AnimationPlayer = $AnimationPlayer
 
func _ready() -> void:
	anim.play("FX_anim")
	await anim.animation_finished
	queue_free()
 
