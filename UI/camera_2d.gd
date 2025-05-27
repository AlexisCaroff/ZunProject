extends Camera2D

var shake_strength := 0.0
var shake_decay := 0.1
var original_offset := Vector2.ZERO

func _ready():
	original_offset = offset

func shake(strength: float = 5.0, decay: float = 0.8):
	shake_strength = strength
	shake_decay = decay

func _process(delta: float) -> void:
	if shake_strength > 0:
		offset = original_offset + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_strength
		shake_strength = lerp(shake_strength, 0.0, shake_decay)
	else:
		offset = original_offset
		
