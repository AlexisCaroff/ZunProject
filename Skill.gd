extends Resource
class_name Skill

@export var name: String = "Attaque"
@export var description: String = "Inflige des dégâts à un ennemi."
@export var icon: Texture2D

@export var cost_action_points: int = 1
@export var Dmg : int = 1
@export var target_type: String = "enemy" # "enemy", "ally", "self", etc.
@export var usable_when_horny: bool = false
@export var needtarget: bool = true
@export var Actiontype : String = "attack" # attack, heal, boost
@export var cost : int =0
@export var cooldown : int=2
@export var currentcooldown: int = 0
var owner: Character

func can_use() -> bool:
	if owner == null:
		return false
	return owner.action_points >= cost_action_points and (usable_when_horny or owner.current_horniness < 100) and currentcooldown == 0

func use(target: Character = null,):
	if not can_use():
		return
	owner.action_points -= cost_action_points
	owner.current_stamina-= cost
	_apply_effect(target)

func _apply_effect(target: Character):
	# Par défaut, inflige des dégâts simples
	if target&& Actiontype == "attack":
		var damage = max(0, Dmg+ owner.attack - target.defense)
		#if target.current_stamina
		#	target.dead= true
		target.current_stamina = max(0,target.current_stamina - damage)
		target.update_ui()
		print("%s inflige %d de dégâts à %s" % [owner.name, damage, target.name])
		
	if target&& Actiontype == "heal":
		var heal = Dmg
		target.current_stamina -= heal
		target.update_ui()
		print("%s soigne %d de dégâts à %s" % [owner.name, heal, target.name])
