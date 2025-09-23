extends CampSkill
class_name CampSkillHeal

func _init():
	name = "Repos"
	description = "Le héros se repose et récupère 20 points de stamina."
	cost = 2
	target_type = TargetType.SELF

	# on ajoute un effet de soin
	var heal_effect := CampEffect.new()
	heal_effect.name = "Soin"
	heal_effect.type = "stamina"
	heal_effect.amount = 20
	effects = [heal_effect]
