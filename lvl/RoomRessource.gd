class_name RoomResource
extends Resource

@export var room_id: String = ""   # identifiant unique de la salle
@export var position_on_map: int
@export var door_scene: PackedScene
@export var Blocked_door_scene: PackedScene
@export var door_scene_History: HistoryScene
@export var before_combat_Animatic_scene: Animatic
@export var before_combat_scene_History: HistoryScene
@export var combat_scene: PackedScene
@export var Post_combat_scene_History: HistoryScene
@export var exploration_scene: PackedScene
@export var exploration_scene_history: HistoryScene
@export var encounter: Resource  # Encounter.tres
@export var CanCamp: bool = false
@export var connected_room_ids: Array[String] = []
@export var blocked_room_ids: Array[String] = []
@export var explored: bool = false
@export var ennemikilled: bool =false
@export var CampDone: bool =false
@export var interactable: InteractableObjectResource
@export var keyName:String =""
@export var locked: bool = false
var connected_rooms: Array[String]
