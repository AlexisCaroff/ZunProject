extends Resource
class_name CampEffect

@export var name: String = "Soin"
@export var amount: int = 10   # points de vie ou stamina récupérés
@export var type: String = "heal"  # heal, stamina, morale, etc.

func apply(user: CharaCamp, target: CharaCamp):
	return
