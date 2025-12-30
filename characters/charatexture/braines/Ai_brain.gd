extends Resource
class_name AiBrain

@export var name: String = "Default AI"
@export var description: String = "IA basique qui choisit une compétence aléatoire utilisable et une cible valide."

func decide_action(owner: Character, heroes: Array, enemies: Array) -> Dictionary:
	# Retourne un dictionnaire avec la skill choisie et la cible (ou null)
	var combat_manager = owner.combat_manager
	var ennemisPositions =combat_manager.enemy_positions
	var herosPositions = combat_manager.hero_positions
	var usable_skills := owner.skills.filter(func(s): return s.can_use())
	if usable_skills.is_empty():
		print("%s n'a aucune compétence utilisable." % owner.characterData.Charaname)
		return {}
	print ("usable skills for" + owner.characterData.Charaname+ " :")
	for skill in usable_skills:
		if usable_skills.size() >1 and skill.name=="move":
			usable_skills.erase(skill)
	for skill in usable_skills:
		print(skill.name)
	var skill: Skill = usable_skills[randi() % usable_skills.size()]
	var possible_targets: Array[Character] = []
	
	match skill.the_target_type:
		skill.target_type.SELF:
			var selfpositions :Array[PositionSlot]
			selfpositions.append(owner._current_slot)
			return {"skill": skill, "target": selfpositions}
		skill.target_type.ALLY:
			possible_targets = enemies
		skill.target_type.ENNEMY:
			possible_targets = heroes
		skill.target_type.ALL_ALLY:
			return {"skill": skill, "target": ennemisPositions}
		skill.target_type.ALL_ENNEMY:
			return {"skill": skill, "target":herosPositions }
	
	var targetPositions: Array = [] 
	if skill.name=="move":
		var theskill = owner.skills[0]

		match theskill.required_position:
			theskill.position_requirement.ANY:
		
				targetPositions = ennemisPositions
			theskill.position_requirement.FRONT:

				targetPositions = ennemisPositions.filter(func(p): return p.position_data.isFront)
			theskill.position_requirement.back:
				targetPositions = ennemisPositions.filter(func(p): return not p.position_data.isFront)
	print (targetPositions )
	possible_targets = possible_targets.filter(func(c): return not c.is_dead())

	var target: Character = null
	var targetPos: Array[PositionSlot]
	if owner.taunted_by != null and skill.the_target_type == skill.target_type.ENNEMY:
		target = owner.taunted_by
	else:
		if possible_targets.size() > 0:
			target = possible_targets[randi() % possible_targets.size()]
		else:
			target = owner  # fallback si tout le monde est mort
	if !targetPositions.is_empty():
		targetPos.append(targetPositions[randi()%targetPositions.size()]) 
	else:
		targetPos.append(target._current_slot)
	return {"skill": skill, "target": targetPos }
	
