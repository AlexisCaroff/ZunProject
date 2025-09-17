class_name RoomResource
extends Resource
@export var position_on_map: int
@export var door_scene: PackedScene
@export var combat_scene: PackedScene
@export var exploration_scene: PackedScene
@export var encounter: Resource  # Encounter.tres
@export var CanCamp : bool = false
@export var connected_rooms: Array[Resource] = []
