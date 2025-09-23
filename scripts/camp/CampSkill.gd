extends Resource
class_name CampSkill

@export var name: String = "Repos"
@export var description: String = "Permet au héros de se reposer et de récupérer un peu de PV."
@export var icon: Texture2D
@export var cost: int = 1   # coût en points de camp / ressources

enum TargetType {
	SELF,
	ALLY,
	ALL_ALLIES
}
@export_enum("Self", "Ally", "All Allies")
var target_type: int = TargetType.SELF

@export var effects: Array[CampEffect] = []   # une liste d’effets appliqués

func use(user: CharaCamp, targets: Array[CharaCamp]):
	for effect in effects:
		for target in targets:
			effect.apply(user, target)
