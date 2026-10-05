extends Node2D
class_name Map

var Rooms: Array[Node2D] = []
var Doors: Array[Node2D] = []

@onready var TeamPositisonIndicator: Sprite2D = $Position
## Durée du glissement du pointeur d'équipe vers sa nouvelle salle/porte.
@export var move_time: float = 0.6
var _pointer_tween: Tween
var tween: Tween
@onready var camera: Camera2D = $Camera2D
var is_dragging := false
var last_mouse_pos := Vector2.ZERO

var zoom_step := 0.1
var min_zoom := 0.4
var max_zoom := 2.5

var gm: GameManager
@export var colorDoorFocus: Color
@export var colorDoorExplored: Color
@export var colorDoorToExplor: Color
@export var colorRoomFocus: Color
@export var colorRoomExplored: Color


func _ready() -> void:
	gm = get_tree().root.get_node("GameManager") as GameManager

	for child in $DonjonRooms.get_children():
		Rooms.append(child)
	for child in $DonjonDoor.get_children():
		Doors.append(child)


func _input(event: InputEvent) -> void:
	if camera == null:
		return

	var mouse_pos := camera.get_global_mouse_position()

	if is_dragging:
		var delta = last_mouse_pos - mouse_pos
		camera.position += delta
		last_mouse_pos = mouse_pos

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				last_mouse_pos = mouse_pos
			else:
				is_dragging = false

		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoom_at(mouse_pos, 1.0 - zoom_step)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_at(mouse_pos, 1.0 + zoom_step)


func _zoom_at(mouse_pos: Vector2, factor: float) -> void:
	var old_zoom = camera.zoom
	var new_zoom = (old_zoom * factor).clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

	if new_zoom == old_zoom:
		return

	var before = mouse_pos
	camera.zoom = new_zoom
	var after = camera.get_global_mouse_position()
	camera.position += before - after


# ════════════════════════════════════════════════════════════════════
#  Helpers de coloration
# ════════════════════════════════════════════════════════════════════

## Repeint TOUTES les salles : visible si explorée, noire sinon.
## Renvoie la salle dont le nom matche room.room_id (la "focus").
func _paint_rooms(room: RoomResource) -> Node2D:
	var focused: Node2D = null
	for salle in Rooms:
		var room_res = gm.get_room_by_id(salle.name)
		if room_res and room_res.explored:
			salle.self_modulate = colorRoomExplored
		else:
			salle.self_modulate = Color.BLACK
		if salle.name == room.room_id:
			focused = salle
	return focused


## Repeint TOUTES les portes : visible (gris) si elle relie au moins
## une salle explorée, noire sinon. C'est la base avant de surligner
## la porte focus.
func _paint_doors_default() -> void:
	for thedoor: MapDoor in Doors:
		var visible_door := false
		for roomname in thedoor.connectedRooms:
			var room_res = gm.get_room_by_id(roomname)
			if room_res and room_res.explored:
				visible_door = true
				break
		thedoor.self_modulate = colorDoorToExplor if visible_door else Color.BLACK


# ════════════════════════════════════════════════════════════════════
#  Focus modes
# ════════════════════════════════════════════════════════════════════

## Phase EXPLORATION : on est dans une salle, on la met en focus.
func focus_on_room(room: RoomResource, _viewport = null):
	var focusedRoom := _paint_rooms(room)
	_paint_doors_default()
	if focusedRoom:
		focusedRoom.self_modulate = colorRoomFocus

	if focusedRoom == null:
		return
	var target_pos = focusedRoom.position
	_place_team_indicator(target_pos)
	var thetween = create_tween()
	thetween.tween_property(camera, "position", target_pos, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Hover sur une salle dans le menu de sélection : on prévisualise la porte.
func peek_next_Room(room: RoomResource, _viewport = null):
	if gm == null:
		gm = get_tree().root.get_node("GameManager") as GameManager

	var lastRoom: String = ""
	if gm.last_room_Ressource != null:
		lastRoom = gm.TheRoom_we_are_in.room_id

	var focusedRoom: Node2D = null
	for salle in Rooms:
		if salle.name == room.room_id:
			focusedRoom = salle
			focusedRoom.self_modulate = colorRoomFocus

	for thedoor: MapDoor in Doors:
		for roomname in thedoor.connectedRooms:
			if roomname == room.room_id:
				thedoor.self_modulate = colorDoorToExplor
			if roomname == lastRoom:
				thedoor.self_modulate = colorDoorToExplor
		if lastRoom != "" and focusedRoom != null:
			if focusedRoom.name in thedoor.connectedRooms and lastRoom in thedoor.connectedRooms:
				thedoor.self_modulate = colorDoorFocus


## Phase DOOR : on regarde une porte qu'on est sur le point de franchir.
## Reset complet salles + portes, puis surligne la porte qu'on traverse.
func focus_door(room: RoomResource, _viewport = null):
	if gm == null:
		gm = get_tree().root.get_node("GameManager") as GameManager

	# 1. Repaint salles + portes par défaut (état explored)
	var focusedRoom := _paint_rooms(room)
	_paint_doors_default()

	# 2. Détermine la salle de provenance
	var lastRoom: String = ""
	if gm.LastRoom_we_were_in != null:
		lastRoom = gm.TheRoom_we_are_in.room_id

	# 3. Cherche la porte qui relie focusedRoom et lastRoom → focus
	var target_pos = null
	for thedoor: MapDoor in Doors:
		var connects_focus := focusedRoom != null and (focusedRoom.name in thedoor.connectedRooms)
		var connects_last  := lastRoom != "" and (lastRoom in thedoor.connectedRooms)
		var connects_start := lastRoom == "" and ("Salle0" in thedoor.connectedRooms)

		if (connects_focus and connects_last) or connects_start:
			thedoor.self_modulate = colorDoorFocus
			target_pos = thedoor.position
			break

	# 4. Tween caméra vers la porte focus, ou la salle si on n'a rien trouvé
	if target_pos == null and focusedRoom != null:
		target_pos = focusedRoom.position

	if target_pos != null:
		_place_team_indicator(target_pos)
		var thetween = create_tween()
		thetween.tween_property(camera, "position", target_pos, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ════════════════════════════════════════════════════════════════════
#  POINTEUR D'ÉQUIPE
# ════════════════════════════════════════════════════════════════════

## Amène le pointeur sur la salle — ou la porte — où se trouve le groupe.
## La mini-carte étant ré-instanciée à chaque changement de scène, la position
## de départ vient du GameManager : c'est elle qui fait que le pointeur glisse
## depuis la salle précédente au lieu de réapparaître ailleurs.
## La rotation lente est gérée à part par rotateSprite.gd sur le nœud Position.
func _place_team_indicator(target_pos: Vector2) -> void:
	if TeamPositisonIndicator == null:
		return
	TeamPositisonIndicator.visible = true

	var previous: Vector2 = gm.map_pointer_position if gm != null else Vector2.INF
	# Première salle de la partie : le pointeur se pose sans traverser la carte.
	TeamPositisonIndicator.position = previous if previous.is_finite() else target_pos
	if gm != null:
		gm.map_pointer_position = target_pos

	if TeamPositisonIndicator.position.is_equal_approx(target_pos):
		return
	if _pointer_tween != null and _pointer_tween.is_valid():
		_pointer_tween.kill()
	_pointer_tween = create_tween()
	_pointer_tween.tween_property(TeamPositisonIndicator, "position", target_pos, move_time) 			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
