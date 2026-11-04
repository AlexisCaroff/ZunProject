class_name DonjonResource
extends Resource

@export var name: String = "Nouveau donjon"
@export var rooms: Array[RoomResource] = []
@export var start_room_id: String = "" 
@export var outsideroom_id: String =""

@export_group("Coffres piégés")
## Chance qu'un coffre en mode RANDOM contienne un slime.
@export_range(0.0, 1.0) var chest_trap_chance: float = 0.35
## Nombre de coffres piégés dans le donjon, coffres ALWAYS compris. Le tirage
## est corrigé pour rester dans ces bornes (autant que les coffres le permettent).
@export var min_trapped_chests: int = 0
@export var max_trapped_chests: int = 2
@export_group("")
