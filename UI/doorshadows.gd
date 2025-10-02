extends Sprite2D
@export var min_x: float = 700
@export var max_x: float = 1400
@export var min_y: float = 400
@export var max_y: float = 500

func _process(_delta: float) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_global_mouse_position()
	
	
	var mirrored_x = viewport_size.x - mouse_pos.x
	var mirrored_y = viewport_size.y - mouse_pos.y
	

	var clamped_x = clamp(mirrored_x, min_x, max_x)
	var clamped_y = clamp(mirrored_y, min_y, max_y)
	
	position = Vector2(clamped_x, clamped_y)
