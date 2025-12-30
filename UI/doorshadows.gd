extends Node2D
class_name Crosshair

@export var max_x := 1600
@export var min_x := 200
@export var max_y := 300
@export var min_y := 200
func _process(_delta):
	var viewport_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_global_mouse_position()

	var t_x = clamp(mouse_pos.x / viewport_size.x, 0.0, 1.0)
	var t_y = clamp(mouse_pos.y / viewport_size.y, 0.0, 1.0)

	var mapped_x = lerp(max_x, min_x, t_x)
	var mapped_y = lerp(max_y, min_y, t_y)

	position = Vector2(mapped_x, 200)
