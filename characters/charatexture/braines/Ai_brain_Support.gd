extends AiBrain
class_name AiBrain_Support

func decide_action(owner: Character, heroes: Array, enemies: Array) -> Dictionary:
	var usable_skills := owner.skills.filter(func(s): return s.can_use())
	if usable_skills.is_empty():
		return {}

	# --- 1️⃣ Cherche les alliés ennemis blessés (dans enemies)
	var weak_allies: Array = enemies.filter(func(c): return not c.is_dead() and c.current_stamina < c.max_stamina * 0.6)
	var heal_skills: Array = usable_skills.filter(func(s): return s.Actiontype == "heal")

	if not heal_skills.is_empty() and not weak_allies.is_empty():
		var heal_skill: Skill = heal_skills.pick_random()
		var target: Character = weak_allies.pick_random()
		print("%s (AI Support) soigne %s avec %s" % [owner.name, target.name, heal_skill.descriptionName])
		return {
			"skill": heal_skill,
			"target": target
		}

	# --- 2️⃣ Sinon, cherche une attaque contre les héros
	var attack_skills: Array = usable_skills.filter(func(s): return s.Actiontype == "attack")
	if not attack_skills.is_empty():
		var attack_skill: Skill = attack_skills.pick_random()
		var possible_targets: Array[Character] = heroes.filter(func(h): return not h.is_dead())
		var target: Character = possible_targets.pick_random() if possible_targets.size() > 0 else null
		print("%s (AI Support) attaque %s avec %s" % [owner.name, target.name if target else "personne", attack_skill.descriptionName])
		return {
			"skill": attack_skill,
			"target": target
		}

	# --- 3️⃣ Si rien d’autre n’est possible, fallback sur le comportement par défaut
	print("%s (AI Support) n’a trouvé aucune action utile, fallback sur IA basique." % owner.name)
	return super.decide_action(owner, heroes, enemies)
