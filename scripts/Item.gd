extends Resource
class_name Item

@export var name: String = ""
@export var icon: Texture2D
@export var description: String = ""
@export var descriptionHide: String = ""
@export var quantity: int = 1
@export var used:bool = false
@export var cursed :bool = false

# Tu peux stocker les effets sous forme de tableau de dictionnaires, ou de Resources personnalisées
@export var effects: Array[Dictionary] = []

func add_quantity(amount: int):
	quantity += amount

func remove_quantity(amount: int):
	quantity = max(0, quantity - amount)

func has_effect(effect_name: String) -> bool:
	for effect in effects:
		if effect_name in effect:
			return true
	return false
