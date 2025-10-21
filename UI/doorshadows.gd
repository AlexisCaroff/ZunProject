extends Sprite2D
@export var min_x: float = 600
@export var max_x: float = 1450
@export var min_y: float = 400
@export var max_y: float = 500

func _process(_delta: float) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_global_mouse_position()

	# Normaliser la souris en 0..1
	var t_x = clamp(mouse_pos.x / viewport_size.x, 0.0, 1.0)
	var t_y = clamp(mouse_pos.y / viewport_size.y, 0.0, 1.0)

	# Mapper en inversant l'axe : souris gauche -> max_x, souris droite -> min_x
	var mapped_x = lerp(max_x, min_x, t_x)
	var mapped_y = lerp(max_y, min_y, t_y) # si tu veux inverser Y aussi ; sinon utiliser lerp(min_y, max_y, t_y)

	position = Vector2(mapped_x, mapped_y)
