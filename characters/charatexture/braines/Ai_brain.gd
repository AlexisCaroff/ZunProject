extends Resource
class_name AiBrain

@export var name: String = "Default AI"
@export var description: String = "IA basique qui choisit une compétence aléatoire utilisable et une cible valide."

func decide_action(owner: Character, heroes: Array, enemies: Array) -> Dictionary:
	# Retourne un dictionnaire avec la skill choisie et la cible (ou null)
	var usable_skills := owner.skills.filter(func(s): return s.can_use())
	if usable_skills.is_empty():
		print("%s n'a aucune compétence utilisable." % owner.name)
		return {}
	
	var skill: Skill = usable_skills[randi() % usable_skills.size()]
	var possible_targets: Array[Character] = []
	
	match skill.the_target_type:
		skill.target_type.SELF:
			return {"skill": skill, "target": owner}
		skill.target_type.ALLY:
			possible_targets = enemies
		skill.target_type.ENNEMY:
			possible_targets = heroes
		skill.target_type.ALL_ALLY, skill.target_type.ALL_ENNEMY:
			return {"skill": skill, "target": null}

	# Nettoyer les cibles mortes
	possible_targets = possible_targets.filter(func(c): return not c.is_dead())

	var target: Character = null
	if owner.taunted_by != null and skill.the_target_type == skill.target_type.ENNEMY:
		target = owner.taunted_by
	else:
		if possible_targets.size() > 0:
			target = possible_targets[randi() % possible_targets.size()]
		else:
			target = owner  # fallback si tout le monde est mort
	
	return {"skill": skill, "target": target}
