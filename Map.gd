extends Node2D
class_name Map
var Rooms: Array[Node2D] = [] 
 
var Doors: Array[Node2D] = [] 

@onready var oldposition :Node2D
@onready var TeamPositisonIndicator = $Position
@export var move_time: float = 1.0   
var tween: Tween
@onready var camera= $Camera2D
var gm : GameManager
@export var colorDoorFocus : Color
@export var colorDoorExplored : Color
@export var colorDoorToExplor : Color
@export var colorRoomFocus : Color
@export var colorRoomExplored : Color

func _ready() -> void:
	gm = get_tree().root.get_node("GameManager") as GameManager
	
	if oldposition != null:
		TeamPositisonIndicator.position=oldposition.position
	
	for child in $DonjonRooms.get_children():
		Rooms.append(child)
	for child in $DonjonDoor.get_children():
		Doors.append(child)
	# Exemple : aller à la première position si elle existe
	

func focus_on_room(room: RoomResource, _viewport=null ):
	var focusedRoom
	for salle in Rooms:
		var room_res = gm.get_room_by_id(salle.name)
		if room_res and room_res.explored:
			salle.self_modulate = colorRoomExplored
			for thedoor :MapDoor in Doors:
				for roomname in thedoor.connectedRooms:
					if roomname == room_res.room_id:
				
						thedoor.self_modulate=colorDoorToExplor
			
		else:
			salle.self_modulate = Color.BLACK
		if salle.name==room.room_id:
			focusedRoom=salle
			salle.self_modulate=colorRoomFocus
	var RoomExploreds: Array[RoomResource]
	for roomRes in gm.donjon.rooms:
		
		if roomRes.explored:
			RoomExploreds.append(roomRes)
			

	
		

	var target_pos = focusedRoom.position
	var tween = create_tween()
	tween.tween_property( camera, "position", target_pos, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func peek_next_Room(room : RoomResource, _viewport=null):
	if gm == null:
		gm = get_tree().root.get_node("GameManager") as GameManager
		print ("go find Gm")
	var lastRoom

	if gm.last_room_Ressource != null:
		lastRoom = gm.last_room_Ressource.room_id
	
	var focusedRoom
	for salle in Rooms:
		if salle.name==room.room_id:
			focusedRoom=salle
			focusedRoom.self_modulate=colorRoomFocus
			
	for thedoor :MapDoor in Doors:	
		for roomname in thedoor.connectedRooms:
			if roomname == room.room_id:
				thedoor.self_modulate=colorDoorToExplor
			if roomname == lastRoom:
				thedoor.self_modulate=colorDoorToExplor
			if lastRoom != null:
				if focusedRoom.name in thedoor.connectedRooms and lastRoom in thedoor.connectedRooms:
					thedoor.self_modulate=colorDoorFocus
					
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
					

		
func focus_door(room : RoomResource, _viewport=null):
	
	if gm == null:
		gm = get_tree().root.get_node("GameManager") as GameManager
		print ("go find Gm")
	for salle in Rooms:
		var room_res = gm.get_room_by_id(salle.name)
		if room_res and room_res.explored:
			salle.self_modulate = colorRoomExplored
		else:
			salle.self_modulate = Color.BLACK

	var focusedRoom
	var lastRoom
	if gm.last_room_Ressource != null:
		lastRoom = gm.last_room_Ressource.room_id
	for salle in Rooms:
		if salle.name==room.room_id:
			focusedRoom=salle
			#focusedRoom.self_modulate=colorRoomFocus
		

	var target_pos 
	
	for thedoor :MapDoor in Doors:
		
		for roomname in thedoor.connectedRooms:
			if roomname == lastRoom:
				thedoor.self_modulate=colorDoorToExplor
		
		if lastRoom != null:
			if focusedRoom.name in thedoor.connectedRooms and lastRoom in thedoor.connectedRooms:
				thedoor.self_modulate=colorDoorFocus
				target_pos=thedoor.position
				print ("find door")
		else:
			for roomname in thedoor.connectedRooms:
				if roomname == "Salle0":
					thedoor.self_modulate=colorDoorFocus
					target_pos=thedoor.position
		
	if target_pos ==null:
		target_pos=focusedRoom.position
	var thetween = create_tween()
	thetween.tween_property( camera, "position", target_pos, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
		
		
	
