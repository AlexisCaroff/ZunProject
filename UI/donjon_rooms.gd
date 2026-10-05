extends Node2D

@onready var game_manager: Node = get_tree().get_root().get_node("GameManager")
@onready var map = $".."
var hovered_sprite: Sprite2D = null
var hover_scale := Vector2(1.05, 1.05)
var normal_scale := Vector2.ONE


func _ready() -> void:
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if not (GameState.current_phase == GameStat.GamePhase.EXPLORATION \
			or GameState.current_phase == GameStat.GamePhase.DOOR):
		return

	# Toujours utiliser la position MONDE via la caméra du SubViewport.
	# get_viewport().get_mouse_position() donne du screen-local qui ne tient
	# pas compte du scale/position du SubViewport ni de la caméra → décalage.
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var mouse_pos: Vector2 = camera.get_global_mouse_position()

	if event is InputEventMouseMotion:
		_check_hover(mouse_pos)

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_check_room_click(mouse_pos)


func _check_room_click(click_pos: Vector2) -> void:
	for room_sprite in get_children():
		if room_sprite is Sprite2D:
			if _is_click_on_visible_pixel(room_sprite, click_pos):
				_on_room_clicked(room_sprite)
				break


func _is_click_on_visible_pixel(sprite: Sprite2D, click_position: Vector2) -> bool:
	var local_pos := sprite.to_local(click_position)

	var texture := sprite.texture
	if texture == null:
		return false

	var image := texture.get_image()
	if image == null:
		return false

	var tex_size: Vector2 = texture.get_size()
	var sprite_size: Vector2 = tex_size * sprite.scale

	var uv := (local_pos + sprite_size * 0.5) / sprite_size

	if uv.x < 0 or uv.x > 1 or uv.y < 0 or uv.y > 1:
		return false

	var pixel_pos := Vector2i(
		int(uv.x * tex_size.x),
		int(uv.y * tex_size.y)
	)

	var color := image.get_pixelv(pixel_pos)
	return color.a > 0.1


func _on_room_clicked(room_sprite: Sprite2D) -> void:
	if room_sprite == null:
		return

	var room_name = room_sprite.name
	var room = game_manager.get_room_by_id(room_name)

	if room == null:
		return

	if not room.explored:
		return

	map.focus_on_room(room)
	game_manager.current_room_Ressource = room
	game_manager._enter_scene_in_current_room(game_manager.current_room_Ressource.exploration_scene)


func _check_hover(mouse_pos: Vector2) -> void:
	var new_hovered: Sprite2D = null

	for room_sprite in get_children():
		if not room_sprite is Sprite2D:
			continue

		var room = game_manager.get_room_by_id(room_sprite.name)
		if room == null or not room.explored:
			continue

		if _is_click_on_visible_pixel(room_sprite, mouse_pos):
			new_hovered = room_sprite
			break

	if new_hovered != hovered_sprite:
		if hovered_sprite:
			var tween = create_tween()
			tween.tween_property(hovered_sprite, "scale", normal_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		hovered_sprite = new_hovered

		if hovered_sprite:
			var tween = create_tween()
			tween.tween_property(hovered_sprite, "scale", hover_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
