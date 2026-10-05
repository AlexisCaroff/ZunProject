extends Resource
class_name CombatEncounter

@export var enemy_scenes: Array[PackedScene] = []
## Slot de chaque ennemi (index dans les positions ennemies : 0-1 avant,
## 2-3 arrière). Vide = dans l'ordre (0, 1, 2…). Permet de laisser un trou,
## par ex. un ennemi devant et un en arrière.
@export var enemy_slots: Array[int] = []
@export var loots: Array[Equipment] = []  
@export var description: String = ""
@export var imageEmbuscade: Texture2D
