extends Node2D

@onready var game_manager: Node = get_tree().get_root().get_node("GameManager") # 🧩 adapte le chemin si besoin
@onready var map=$".."
func _ready() -> void:
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_check_room_click(event.position)


func _check_room_click(click_pos: Vector2) -> void:
	# Parcourt tous les Sprite2D enfants
	for room_sprite in get_children():
		if not (room_sprite is Sprite2D):
			continue

		if _is_click_on_visible_pixel(room_sprite, click_pos):
			_on_room_clicked(room_sprite)
			break


func _is_click_on_visible_pixel(sprite: Sprite2D, click_position: Vector2) -> bool:
	if not sprite.texture:
		return false

	# Convertit la position du clic dans le repère local du sprite
	var local_pos = sprite.to_local(click_position)
	var tex = sprite.texture
	var tex_size = tex.get_size() * sprite.scale
	var origin = -tex_size / 2.0
	var tex_pos = ((local_pos - origin) / sprite.scale).floor()

	# Vérifie les limites
	if tex_pos.x < 0 or tex_pos.y < 0 or tex_pos.x >= tex.get_width() or tex_pos.y >= tex.get_height():
		return false

	# Récupère l'image et la couleur du pixel
	var img: Image = tex.get_image()
	if img.is_empty():
		return false

	var pixel_color = img.get_pixelv(tex_pos)
	return pixel_color.a > 0.1


func _on_room_clicked(room_sprite: Sprite2D) -> void:
	if room_sprite != null:
		var room_name = room_sprite.name
		var room= game_manager.get_room_by_id(room_name)
		if room != null:
			map.focus_on_room(room)
		#	game_manager.current_room_Ressource = room
		#	game_manager._enter_scene_in_current_room(game_manager.current_room_Ressource.exploration_scene)
	
