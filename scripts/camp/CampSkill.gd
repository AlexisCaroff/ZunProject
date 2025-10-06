extends Resource
class_name CampSkill

@export var name: String = "Dialogue"
@export var description: String = "engage une discution"
@export var icon: Texture2D
@export var cost: int = 1   # coût en points de camp / ressources
@export var standarEnd: bool = true
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
	if standarEnd:
		user.camp.After_camp_skill(user.camp.skillused)
