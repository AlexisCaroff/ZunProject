extends Resource
class_name Skill

@export var name: String = "Attaque"
@export var description: String = "Inflige des dégâts à un ennemi."
@export var icon: Texture2D

@export var cost_action_points: int = 1
@export var Dmg : int = 1
enum target_type {
	ENNEMY, 
	ALLY, 
	SELF,
	ALL_ALLY,
	All_ENNEMY
}

@export_enum("enemy", "ally", "self", "all ally", "all ennemy")
var the_target_type: int = target_type.ENNEMY

@export var two_target_Type: bool = false 

enum second_target_type {
	ENNEMY, 
	ALLY, 
	SELF,
	ALL_ALLY,
	All_ENNEMY
}

@export_enum("enemy", "ally", "self", "all ally", "all ennemy")
var the_second_target_type: int = second_target_type.ENNEMY

@export var usable_when_horny: bool = false
@export var needtarget: bool = true
@export var Actiontype : String = "attack" # attack, heal, boost
@export var cost : int =0
@export var cooldown : int=2
@export var current_cooldown: int = 0
@export var effects: Array[SkillEffect] = []
var owner: Character

func can_use() -> bool:
	if owner == null:
		return false
	return current_cooldown == 0

func use(target: Character = null,):
	if not can_use():
		return
	owner.action_points -= cost_action_points
	owner.current_stamina-= cost
	if cooldown > 0:
		current_cooldown = cooldown
	_apply_effect(target)

func _apply_effect(target: Character):
	for effect in effects:
		effect.apply(owner, target)
	
